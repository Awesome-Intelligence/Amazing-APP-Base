/**
 * 推送发送：把一条消息送到客户端能收到的地方。
 *
 * 两条通道，都是**可选**的（没配就一封不发，网关照常跑，不报错）：
 *
 * - ntfy（https://ntfy.sh，可自托管）：纯 HTTP、零凭据。客户端轮询拉消息。
 *   缺点：应用被杀时收不到（没有系统级唤醒）。
 * - FCM（Firebase HTTP v1）：系统级后台推送，应用被杀也能到。
 *   前提：服务端有 service account，客户端有 FCM token。
 *
 * 两条都不引第三方 SDK：ntfy 是普通 HTTP，FCM 的 OAuth2 用 node:crypto 手签 RS256。
 */
import { createSign } from "node:crypto";
import { log } from "./log.js";

export interface NotifyPayload {
  title: string;
  body: string;
}

export type FetchLike = (
  input: string,
  init?: { method?: string; headers?: Record<string, string>; body?: string },
) => Promise<{ ok: boolean; status: number; text(): Promise<string> }>;

/* ── ntfy ─────────────────────────────────────────────────── */

export interface NtfyTarget {
  server: string;
  topic: string;
  token?: string;
}

/** NTFY_TOPIC 没配 = 不走 ntfy。 */
export function ntfyTargetFromEnv(env: NodeJS.ProcessEnv = process.env): NtfyTarget | null {
  const topic = env.NTFY_TOPIC?.trim();
  if (!topic) return null;
  const server = env.NTFY_SERVER?.trim() || "https://ntfy.sh";
  const token = env.NTFY_TOKEN?.trim();
  return { server: server.replace(/\/+$/, ""), topic, ...(token ? { token } : {}) };
}

export async function publishNtfy(
  payload: NotifyPayload,
  target: NtfyTarget,
  fetchImpl: FetchLike = fetch as unknown as FetchLike,
): Promise<void> {
  const res = await fetchImpl(`${target.server}/${target.topic}`, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      ...(target.token ? { authorization: `Bearer ${target.token}` } : {}),
    },
    body: JSON.stringify({
      topic: target.topic,
      title: payload.title,
      message: payload.body,
    }),
  });
  if (!res.ok) {
    throw new Error(`ntfy 发布失败: ${res.status} ${await res.text()}`);
  }
}

/* ── FCM（Firebase HTTP v1）───────────────────────────────── */

export interface ServiceAccount {
  client_email: string;
  private_key: string;
}

export interface FcmTarget {
  projectId: string;
  serviceAccount: ServiceAccount;
}

/**
 * FCM_PROJECT_ID + FCM_SERVICE_ACCOUNT_JSON（service account 的 JSON 内容）都配了才有 FCM。
 *
 * 为什么不读文件路径：容器里 secret 一般走环境变量；两种都支持的话又是一份分支。
 */
export function fcmTargetFromEnv(env: NodeJS.ProcessEnv = process.env): FcmTarget | null {
  const projectId = env.FCM_PROJECT_ID?.trim();
  const raw = env.FCM_SERVICE_ACCOUNT_JSON?.trim();
  if (!projectId || !raw) return null;
  try {
    const parsed = JSON.parse(raw) as ServiceAccount;
    if (!parsed.client_email || !parsed.private_key) return null;
    return { projectId, serviceAccount: parsed };
  } catch {
    log.warn("fcm.config.invalid", { projectId });
    return null;
  }
}

function base64url(input: Buffer | string): string {
  return Buffer.from(input).toString("base64url");
}

/**
 * service account 换 OAuth2 access token：自签一个 RS256 JWT 当 assertion，
 * 拿去换 token。不用 google-auth 库，也不用引 npm 依赖。
 */
export async function fcmAccessToken(
  account: ServiceAccount,
  fetchImpl: FetchLike = fetch as unknown as FetchLike,
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const claims = {
    iss: account.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };
  const signingInput = `${base64url(JSON.stringify(header))}.${base64url(JSON.stringify(claims))}`;
  const signature = createSign("RSA-SHA256").update(signingInput).sign(account.private_key);
  const assertion = `${signingInput}.${base64url(signature)}`;

  const res = await fetchImpl("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }).toString(),
  });
  if (!res.ok) {
    throw new Error(`FCM 换 token 失败: ${res.status} ${await res.text()}`);
  }
  const json = JSON.parse(await res.text()) as { access_token?: string };
  if (!json.access_token) throw new Error("FCM 换 token 失败：响应里没有 access_token");
  return json.access_token;
}

/** 给一批 token 发消息，返回成功条数。单个失败不影响其他 token。 */
export async function publishFcm(
  payload: NotifyPayload,
  target: FcmTarget,
  tokens: string[],
  fetchImpl: FetchLike = fetch as unknown as FetchLike,
): Promise<number> {
  if (tokens.length === 0) return 0;
  const accessToken = await fcmAccessToken(target.serviceAccount, fetchImpl);
  let ok = 0;
  for (const token of tokens) {
    const res = await fetchImpl(
      `https://fcm.googleapis.com/v1/projects/${target.projectId}/messages:send`,
      {
        method: "POST",
        headers: { authorization: `Bearer ${accessToken}`, "content-type": "application/json" },
        body: JSON.stringify({
          message: {
            token,
            notification: { title: payload.title, body: payload.body },
            data: { title: payload.title, body: payload.body },
          },
        }),
      },
    );
    if (res.ok) {
      ok++;
    } else {
      log.warn("fcm.send.failed", { status: res.status, text: await res.text() });
    }
  }
  return ok;
}
