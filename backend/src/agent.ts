/**
 * agent 执行：skill + input → SDK agent loop → 网关事件流。
 *
 * 事件（SSE data 的 JSON）—— 词汇跟 kit 的 `AgentEvent` 一一对应：
 *   { type: "start",       sessionId }
 *   { type: "text",        text }          // assistant 文本块
 *   { type: "tool_use",    name, args }    // 模型调了某个工具
 *   { type: "tool_done",   name, result }  // 工具跑完
 *   { type: "tool_failed", name, message } // 工具没跑成
 *   { type: "result",      text, output }  // 整轮结束：text=完整回复，output=已按 schema 校验的 JSON
 *   { type: "error",       message }
 *
 * 改这里必须同步改 kit-agent 的 `mapGatewayEvent`
 * （`scripts/verify_gateway.py` 盯着两边对不对得上）。
 */
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { query } from "@anthropic-ai/claude-agent-sdk";
import type { Skill } from "./skills.js";
import { parseOutput } from "./skills.js";

export type GatewayEvent =
  | { type: "start"; sessionId: string }
  | { type: "text"; text: string }
  | { type: "tool_use"; name: string; args: Record<string, unknown> }
  | { type: "tool_done"; name: string; result: string }
  | { type: "tool_failed"; name: string; message: string }
  | { type: "result"; text: string; output: unknown }
  | { type: "error"; message: string };

export interface InvokeResult {
  sessionId: string;
}

/** tool_result 的 content 可能是字符串，也可能是内容块数组（取其中的 text）。 */
function flattenToolContent(content: unknown): string {
  if (typeof content === "string") return content;
  if (!Array.isArray(content)) return "";
  return content
    .map((b) => {
      const t = (b as { text?: unknown }).text;
      return typeof t === "string" ? t : "";
    })
    .filter((s) => s !== "")
    .join("\n");
}

export async function invokeSkill(
  skill: Skill,
  input: unknown,
  sessionId: string | undefined,
  onEvent: (e: GatewayEvent) => void,
  signal?: AbortSignal
): Promise<InvokeResult> {
  // 每个 skill 有自己的输出契约，拼进 system prompt；输出 JSON 由服务端 parseOutput 兜底校验
  const systemPrompt =
    `${skill.prompt}\n\n` +
    `## 输出要求（必须遵守）\n` +
    `你的最终回复必须是且仅是一个 JSON 对象（可以放在 \`\`\`json 围栏里），` +
    `不要输出 JSON 以外的内容。它必须符合这个 JSON Schema：\n` +
    JSON.stringify(skill.outputSchema);

  const abortController = new AbortController();
  signal?.addEventListener("abort", () => abortController.abort(), { once: true });

  // 隔离的工作目录：agent 不碰仓库和用户文件
  const workdir = fs.mkdtempSync(path.join(os.tmpdir(), "agent-gw-"));
  let resultSessionId = sessionId ?? "";
  // tool_use_id → 工具名：SDK 的 tool_result 块只给 id，名字得自己记
  const toolNames = new Map<string, string>();

  try {
    const stream = query({
      prompt: `输入参数：\n${JSON.stringify(input, null, 2)}`,
      options: {
        systemPrompt,
        // skill.tools 是白名单，语义上要"只有这些工具能用"：
        //   tools       —— 限定模型能看到的工具集（[] = 一个都不给）
        //   allowedTools —— 同一批工具免审批直接跑
        // 只给 allowedTools 是不够的：它只管"免审批"，不限制工具集，
        // 那样 tools: [] 的纯对话 skill 照样能调 Read/Write/Bash。
        tools: skill.tools,
        allowedTools: skill.tools,
        maxTurns: skill.maxTurns ?? 8,
        model: skill.model ?? process.env.AGENT_MODEL ?? "claude-opus-5-5",
        settingSources: [], // ponytail: 不读宿主机 CLAUDE.md/settings，网关行为要确定
        cwd: workdir,
        resume: sessionId,
        abortController,
      },
    });

    for await (const message of stream) {
      if (message.type === "system" && message.subtype === "init") {
        resultSessionId = message.session_id;
        onEvent({ type: "start", sessionId: message.session_id });
      } else if (message.type === "assistant") {
        for (const block of message.message.content) {
          if (block.type === "text") {
            onEvent({ type: "text", text: block.text });
          } else if (block.type === "tool_use") {
            toolNames.set(block.id, block.name);
            const args =
              typeof block.input === "object" && block.input !== null && !Array.isArray(block.input)
                ? (block.input as Record<string, unknown>)
                : {};
            onEvent({ type: "tool_use", name: block.name, args });
          }
        }
      } else if (message.type === "user") {
        // 工具结果在 user 消息里（content 可能是字符串，也可能是一组块）
        const content = message.message.content;
        if (!Array.isArray(content)) continue;
        for (const block of content) {
          if (block.type !== "tool_result") continue;
          const name = toolNames.get(block.tool_use_id) ?? "tool";
          const text = flattenToolContent(block.content);
          if (block.is_error) {
            onEvent({ type: "tool_failed", name, message: text });
          } else {
            onEvent({ type: "tool_done", name, result: text });
          }
        }
      } else if (message.type === "result") {
        if (message.subtype === "success") {
          const raw = message.result ?? "";
          const parsed = parseOutput(skill, raw);
          if (parsed.ok) {
            onEvent({ type: "result", text: raw, output: parsed.output });
          } else {
            onEvent({ type: "error", message: parsed.error });
          }
        } else {
          onEvent({ type: "error", message: `agent 执行失败 (${message.subtype})` });
        }
      }
      // stream_event 等消息：v1 不下发
    }
  } finally {
    fs.rmSync(workdir, { recursive: true, force: true });
  }

  return { sessionId: resultSessionId };
}
