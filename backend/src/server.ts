/**
 * agent 网关 HTTP 层。五条路由，完了：
 *   GET  /health
 *   GET  /v1/skills                     → skill 列表（id/name/description）
 *   POST /v1/skills/:id/invoke          → SSE 事件流（start/text/tool/result/error）
 *   POST /v1/devices                    → 登记 FCM token（推系统通知用）
 *   POST /v1/notify                     → 直接推一条消息（定时任务 / webhook 触发）
 *
 * 鉴权：配置了 GATEWAY_TOKEN 时，所有 /v1 请求必须带 Authorization: Bearer <token>。
 * 多用户：GATEWAY_TOKENS="alice:tok1,bob:tok2" —— token 直接认用户（userId）。
 *
 * 三条安全线（改这块之前先读 SECURITY.md）：
 *   1. session 按 userId 隔离 —— resume 会接着别人的会话跑，不能让客户端随便传 sessionId
 *   2. 日志只记事件类型，不记对话正文
 *   3. 危险工具走白名单，闸门在工具执行前拦
 */
import "./env.js";
import express, { type Request, type Response } from "express";
import { fileURLToPath } from "node:url";
import { loadSkills, inputError } from "./skills.js";
import { invokeSkill, type GatewayEvent } from "./agent.js";
import { abortOnDisconnect } from "./sse.js";
import { mayResume, RateLimiter, userOf } from "./guard.js";
import { DeviceRegistry } from "./devices.js";
import {
  fcmTargetFromEnv,
  ntfyTargetFromEnv,
  publishFcm,
  publishNtfy,
  type NotifyPayload,
} from "./notify.js";
import { log } from "./log.js";

const PORT = Number(process.env.PORT ?? 8787);
const SKILLS_DIR = process.env.SKILLS_DIR || fileURLToPath(new URL("../skills/", import.meta.url));
// 每个用户每分钟最多几次 invoke —— agent 一次调用就是一次真金白银的模型请求
const RATE_LIMIT_PER_MIN = Number(process.env.RATE_LIMIT_PER_MIN ?? 60);

const skills = loadSkills(SKILLS_DIR);
log.info("skills.loaded", { dir: SKILLS_DIR, count: skills.size, ids: [...skills.keys()] });

const app = express();
app.use(express.json({ limit: "1mb" }));

const limiter = new RateLimiter(RATE_LIMIT_PER_MIN);

/**
 * sessionId → 拥有它的 userId。
 *
 * ponytail: 内存表，服务重启就丢（重启后客户端带来的 sessionId 一律当新会话）。
 *         要跨重启 resume 就落盘（sessionId → userId 一行一条）。
 */
const sessionOwner = new Map<string, string>();

/** userId → FCM token（推系统通知用）。 */
const devices = new DeviceRegistry();

/**
 * 把一条消息发到所有配好的通道，返回真正发出去的通道名。
 *
 * 没配通道 = 什么都不发（不是错误）。单个通道失败也不影响其他通道。
 */
async function publish(userId: string, payload: NotifyPayload): Promise<string[]> {
  const sent: string[] = [];

  const ntfy = ntfyTargetFromEnv();
  if (ntfy) {
    try {
      await publishNtfy(payload, ntfy);
      sent.push("ntfy");
    } catch (e) {
      log.warn("notify.ntfy.failed", { error: e instanceof Error ? e.message : String(e) });
    }
  }

  const fcm = fcmTargetFromEnv();
  if (fcm) {
    try {
      const ok = await publishFcm(payload, fcm, devices.tokensOf(userId));
      if (ok > 0) sent.push("fcm");
    } catch (e) {
      log.warn("notify.fcm.failed", { error: e instanceof Error ? e.message : String(e) });
    }
  }

  return sent;
}

// ── 路由 ─────────────────────────────────────────────────────

/** 认出用户 + 限流；认不出就自己回 401/429 并返回 null。 */
function requireUser(req: Request, res: Response): string | null {
  const userId = userOf(
    req.headers.authorization,
    process.env.GATEWAY_TOKENS,
    process.env.GATEWAY_TOKEN
  );
  if (!userId) {
    log.warn("auth.fail", { path: req.path });
    res.status(401).json({ error: "缺少或错误的 Bearer token" });
    return null;
  }
  if (limiter.hit(userId)) {
    log.warn("rate.limit", { userId, path: req.path });
    res.setHeader("Retry-After", "60");
    res.status(429).json({ error: `每分钟最多 ${RATE_LIMIT_PER_MIN} 次` });
    return null;
  }
  return userId;
}

app.get("/health", (_req, res) => res.json({ ok: true }));

app.get("/v1/skills", (req, res) => {
  if (!requireUser(req, res)) return;
  res.json([...skills.values()].map((s) => ({ id: s.id, name: s.name, description: s.description })));
});

/** 登记本机的 FCM token —— 之后服务端推消息才知道往哪儿推。 */
app.post("/v1/devices", (req, res) => {
  const userId = requireUser(req, res);
  if (!userId) return;
  const token = (req.body as { token?: unknown } | undefined)?.token;
  if (typeof token !== "string" || !token) {
    res.status(400).json({ error: "缺 token" });
    return;
  }
  devices.register(userId, token);
  res.json({ ok: true });
});

/**
 * 直接推一条消息（定时任务 / webhook 触发）。
 *
 * 这是「服务端主动通知」的那条路：不需要客户端在线挂着，
 * 消息进 ntfy 主题 / FCM token，客户端自己收。
 */
app.post("/v1/notify", async (req, res) => {
  const userId = requireUser(req, res);
  if (!userId) return;
  const body = (req.body ?? {}) as { title?: unknown; body?: unknown };
  const title = typeof body.title === "string" ? body.title : "";
  const text = typeof body.body === "string" ? body.body : "";
  if (!title && !text) {
    res.status(400).json({ error: "title / body 至少给一个" });
    return;
  }
  const sent = await publish(userId, { title, body: text });
  res.json({ ok: true, channels: sent });
});

app.post("/v1/skills/:id/invoke", (req, res) => {
  const userId = requireUser(req, res);
  if (!userId) return;

  const skill = skills.get(req.params.id);
  if (!skill) {
    res.status(404).json({ error: `skill 不存在: ${req.params.id}` });
    return;
  }

  const { input, sessionId } = req.body ?? {};
  // notify=true → 这一轮跑完把结果推给客户端（应用在后台也能收到）。
  const wantNotify = (req.body as { notify?: unknown } | undefined)?.notify === true;
  const bad = inputError(skill, input);
  if (bad) {
    res.status(400).json({ error: bad });
    return;
  }

  // 客户端要接着上次的会话跑 —— 先验归属
  const requested = typeof sessionId === "string" && sessionId ? sessionId : undefined;
  let resumeId: string | undefined;
  if (requested) {
    const decision = mayResume(sessionOwner, requested, userId);
    if (decision === "forbidden") {
      log.warn("session.forbidden", { userId, skillId: skill.id });
      res.status(403).json({ error: "session 不属于当前用户" });
      return;
    }
    if (decision === "resume") {
      resumeId = requested;
    } else {
      // 本进程没见过这个 session（服务重启过 / 别的实例产的）—— 当新会话，绝不拿它去 resume
      log.warn("session.unknown", { userId, skillId: skill.id });
    }
  }

  // SSE 头
  res.writeHead(200, {
    "Content-Type": "text/event-stream",
    "Cache-Control": "no-cache",
    Connection: "keep-alive",
  });

  const startedAt = Date.now();
  let outcome = "ok";
  let activeSessionId = resumeId ?? "";
  let finalText = "";
  let failMessage = "";
  const send = (e: GatewayEvent) => {
    if (e.type === "start") {
      activeSessionId = e.sessionId;
      sessionOwner.set(e.sessionId, userId);
    }
    if (e.type === "error") {
      outcome = "error";
      failMessage = e.message;
    }
    if (e.type === "result") finalText = e.text;
    res.write(`event: ${e.type}\ndata: ${JSON.stringify(e)}\n\n`);
  };

  // 审计日志：记事件类型和标识符，不记正文
  log.info("invoke.start", { userId, skillId: skill.id, resumed: resumeId !== undefined });

  // 客户端断开 → 中止 agent loop（挂 res，不挂 req，原因见 sse.ts）
  const abort = abortOnDisconnect(res);

  invokeSkill(skill, input, resumeId, send, abort.signal)
    .catch((e: unknown) => {
      outcome = "error";
      if (!abort.signal.aborted) send({ type: "error", message: (e as Error).message });
    })
    .finally(() => {
      log.info("invoke.end", {
        userId,
        skillId: skill.id,
        sessionId: activeSessionId,
        ms: Date.now() - startedAt,
        outcome,
      });
      res.end();
      // 推送放在最后：正文已经在 finalText / failMessage 里了。
      // 推送失败不影响这一轮的结果 —— 客户端已经拿到 SSE 了。
      if (wantNotify) {
        const payload: NotifyPayload =
          outcome === "error"
            ? { title: "助手出错了", body: failMessage }
            : { title: "助手回复完成", body: finalText };
        void publish(userId, payload).then((sent) => {
          log.info("notify.sent", { userId, channels: sent });
        });
      }
    });
});

// 兜底错误处理：别把栈信息回给客户端（里面可能有路径、配置），只记日志
app.use((err: unknown, _req: Request, res: Response, _next: express.NextFunction) => {
  log.error("http.error", {
    error: err instanceof Error ? err.message : String(err),
    stack: err instanceof Error ? err.stack : undefined,
  });
  if (!res.headersSent) res.status(500).json({ error: "内部错误" });
});

// 进程级兜底：崩了要留下痕迹（崩溃报告的最小实现 —— 不引第三方 SDK，
// 免得把用户的对话内容发给外网）
process.on("unhandledRejection", (reason) => {
  log.error("unhandledRejection", { error: String(reason) });
});
process.on("uncaughtException", (err) => {
  log.error("uncaughtException", { error: err.message, stack: err.stack });
  process.exit(1);
});

app.listen(PORT, () => {
  log.info("gateway.listening", {
    port: PORT,
    auth: process.env.GATEWAY_TOKENS ? "multi" : process.env.GATEWAY_TOKEN ? "on" : "off",
    rateLimitPerMin: RATE_LIMIT_PER_MIN,
  });
});
