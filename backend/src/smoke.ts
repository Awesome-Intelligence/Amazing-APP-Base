/** 冒烟检查（不花 token，不连网）：skill 能加载、契约是合法 JSON Schema、parseOutput 行为正确。 */
import assert from "node:assert";
import { generateKeyPairSync } from "node:crypto";
import type { AddressInfo } from "node:net";
import { fileURLToPath } from "node:url";
import express from "express";
import { loadSkills, inputError, parseOutput } from "./skills.js";
import { abortOnDisconnect } from "./sse.js";
import { mayResume, RateLimiter, userOf } from "./guard.js";
import { fcmTargetFromEnv, ntfyTargetFromEnv, publishFcm, publishNtfy } from "./notify.js";

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

const skills = loadSkills(fileURLToPath(new URL("../skills/", import.meta.url)));
assert.ok(skills.size > 0, "skills 目录是空的，至少要有一个 skill");

const summarize = skills.get("summarize");
assert.ok(summarize, "缺 demo skill: summarize");

// input 契约
assert.equal(inputError(summarize!, { text: "你好" }), null);
assert.ok(inputError(summarize!, {}), "空 input 应该被契约拦下");

// output 契约 + 围栏容错
const good = parseOutput(summarize!, '好的，结果如下：\n```json\n{"summary":"短摘要","keywords":["a"]}\n```');
assert.ok(good.ok, `合法输出被误判: ${!good.ok ? good.error : ""}`);
const bad = parseOutput(summarize!, '{"summary":123}');
assert.ok(!bad.ok, "类型不对的 output 应该被拦下");

console.log(`smoke 通过: ${skills.size} 个 skill（${[...skills.keys()].join(", ")}）`);

/**
 * SSE 断连检测：body 读完**不能** abort，客户端真的断开才 abort。
 * （req 的 'close' 在 body 读完就触发，用它会把 agent 立刻掐掉。）
 */
async function checkAbortOnDisconnect() {
  const app = express();
  app.use(express.json());
  let controller: AbortController | undefined;
  app.post("/probe", (_req, res) => {
    controller = abortOnDisconnect(res);
    res.writeHead(200, { "Content-Type": "text/event-stream" });
    res.write("data: open\n\n");
  });
  const server = app.listen(0);
  const port = (server.address() as AddressInfo).port;

  const clientAbort = new AbortController();
  const resp = await fetch(`http://127.0.0.1:${port}/probe`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: "{}",
    signal: clientAbort.signal,
  });
  // 读到服务端开流为止 —— 此时 body 已解析完
  await resp.body?.getReader().read();

  assert.ok(controller, "probe 没拿到 AbortController");
  assert.equal(controller.signal.aborted, false, "body 一读完就 abort 了 —— 又踩了 req 'close' 的坑");

  clientAbort.abort(); // 客户端断开
  for (let i = 0; i < 50 && !controller.signal.aborted; i++) await sleep(20);
  assert.ok(controller.signal.aborted, "客户端断了但没 abort");

  server.closeAllConnections();
  server.close();
}

await checkAbortOnDisconnect();
console.log("smoke 通过: SSE 断连检测");

/**
 * 安全边界自检：鉴权 → userId、session 归属、限流。
 * 这三条出错的后果是「接着别人的会话跑」或者「刷爆模型账单」，必须挡住。
 */
function checkGuards() {
  // 鉴权
  const multi = "alice:tok-a,bob:tok-b";
  assert.equal(userOf("Bearer tok-a", multi), "alice", "alice 的 token 应该认出 alice");
  assert.equal(userOf("Bearer tok-b", multi), "bob");
  assert.equal(userOf("Bearer tok-c", multi), null, "别人的 token 不能被认出来");
  assert.equal(userOf("", multi), null, "没带 token 不能通过");
  assert.equal(userOf("Bearer x", undefined, "single"), null, "单用户模式也要验 token");
  assert.equal(userOf("Bearer single", undefined, "single"), "default");
  assert.equal(userOf("", undefined, undefined), "default", "没配 token = 本机开发，放行");

  // session 归属
  const registry = new Map<string, string>([["s1", "alice"]]);
  assert.equal(mayResume(registry, "s1", "alice"), "resume", "自己的 session 要能接着跑");
  assert.equal(mayResume(registry, "s1", "bob"), "forbidden", "别人的 session 必须拒绝");
  assert.equal(mayResume(registry, "s-unknown", "bob"), "new", "没见过的 session 当新的，别 resume");

  // 限流
  const limiter = new RateLimiter(3, () => 1000);
  assert.equal(limiter.hit("u"), false);
  assert.equal(limiter.hit("u"), false);
  assert.equal(limiter.hit("u"), false);
  assert.equal(limiter.hit("u"), true, "第 4 次要超限");
  assert.equal(limiter.hit("other"), false, "限流要按 key 分开");
}

checkGuards();
console.log("smoke 通过: 鉴权 / session 归属 / 限流");

/**
 * 推送通道自检：ntfy 的请求长什么样、FCM 的 token 怎么换、发了几个成功。
 * 全部用假 fetch —— 不连网、不花钱。
 */
async function checkNotify() {
  const calls: { url: string; method?: string; headers?: Record<string, string>; body?: string }[] = [];
  const fakeFetch = async (
    url: string,
    init?: { method?: string; headers?: Record<string, string>; body?: string },
  ) => {
    calls.push({ url, ...init });
    return { ok: true, status: 200, text: async () => JSON.stringify({ access_token: "at-1" }) };
  };

  // ntfy
  const target = ntfyTargetFromEnv({ NTFY_TOPIC: "demo-topic", NTFY_TOKEN: "tk_x" } as never);
  assert.ok(target, "配了 NTFY_TOPIC 就该有目标");
  assert.equal(target!.server, "https://ntfy.sh");
  await publishNtfy({ title: "标题", body: "正文" }, target!, fakeFetch as never);
  assert.equal(calls.at(-1)!.url, "https://ntfy.sh/demo-topic");
  assert.equal(calls.at(-1)!.headers!["authorization"], "Bearer tk_x");
  assert.deepEqual(JSON.parse(calls.at(-1)!.body!), {
    topic: "demo-topic",
    title: "标题",
    message: "正文",
  });

  // 没配主题 = 不走 ntfy
  assert.equal(ntfyTargetFromEnv({} as never), null);

  // FCM：现生成一把 RSA 私钥，走完整的换 token + 发消息
  const { privateKey } = generateKeyPairSync("rsa", { modulusLength: 2048 });
  const fcm = fcmTargetFromEnv({
    FCM_PROJECT_ID: "proj-1",
    FCM_SERVICE_ACCOUNT_JSON: JSON.stringify({
      client_email: "sa@x.iam",
      private_key: privateKey.export({ type: "pkcs8", format: "pem" }).toString(),
    }),
  } as never);
  assert.ok(fcm, "配全了 FCM 就该有目标");
  const sent = await publishFcm(
    { title: "标题", body: "正文" },
    fcm!,
    ["token-a", "token-b"],
    fakeFetch as never,
  );
  assert.equal(sent, 2, "两个 token 都该发成功");
  const tokenCall = calls.find((c) => c.url.includes("oauth2.googleapis.com"))!;
  assert.ok(tokenCall, "应该先换 access token");
  const assertion = new URLSearchParams(tokenCall.body!).get("assertion")!;
  assert.equal(assertion.split(".").length, 3, "JWT 应该是三段");
  const msgCall = calls.find((c) => c.url.includes("messages:send"))!;
  assert.equal(msgCall.url, "https://fcm.googleapis.com/v1/projects/proj-1/messages:send");
  assert.equal(JSON.parse(msgCall.body!).message.token, "token-a");
}

await checkNotify();
console.log("smoke 通过: 推送通道（ntfy / FCM）");
