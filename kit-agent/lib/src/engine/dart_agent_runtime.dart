import 'dart:async';
import 'dart:convert';

import 'package:dart_agent_core/dart_agent_core.dart' as dac;
import '../agent_event.dart';
import '../agent_runtime.dart';
import '../skill_definition.dart';
import '../skill_tool.dart';
import '../tool_approval.dart';

/// 把工具调用参数（JSON 字符串）解码成 Map；失败/空返回空 Map。
Map<String, Object?> _decodeArgs(String arguments) {
  if (arguments.trim().isEmpty) return {};
  try {
    final decoded = jsonDecode(arguments);
    return decoded is Map ? Map<String, Object?>.from(decoded) : {};
  } catch (_) {
    return {};
  }
}

/// 本机 agent 运行时：用 dart_agent_core 在端上跑 loop。
///
/// 框架耦合集中在此文件。已对照 dart_agent_core 2.1.9 源码对齐：
/// - [dac.StatefulAgent] 构造（name/systemPrompts/client/modelConfig/state/tools/hooks/maxTurns）
/// - 工具执行前审批用 [dac.AgentHook.beforeToolCall] 返回 [dac.ToolCallHookResult]
/// - [dac.StatefulAgent.runStream] 返回 [dac.StreamingEvent]，按 [dac.StreamingEventType] 区分
/// - [dac.Tool] 用 object 模式，executable 收 Map 并返回 String（框架包成文本结果）
class DartAgentRuntime implements AgentRuntime {
  final String apiKey;
  final String? baseUrl;

  /// 测试注入点：非空时直接用它当 LLM client，跳过真实 `ClaudeClient`。
  /// 生产路径传 null，由 SDK 用 [apiKey] 建真实客户端。
  final dac.LLMClient? client;

  DartAgentRuntime({required this.apiKey, this.baseUrl, this.client});

  @override
  AgentSession session(SkillDefinition skill, {ToolApprover? approver}) {
    final c = client ?? _realClient();
    return _DartAgentSession(skill: skill, client: c, approver: approver);
  }

  dac.LLMClient _realClient() {
    final url = baseUrl;
    return url == null
        ? dac.ClaudeClient(apiKey: apiKey)
        : dac.ClaudeClient(apiKey: apiKey, baseUrl: url);
  }
}

class _DartAgentSession implements AgentSession {
  final SkillDefinition skill;
  final dac.LLMClient client;
  final ToolApprover? approver;

  _DartAgentSession({
    required this.skill,
    required this.client,
    this.approver,
  });

  @override
  Stream<AgentEvent> send(String input) async* {
    final tools = skill.tools.map(_toDacTool).toList();
    final hook = _ApprovalHook(approver, skill.tools);

    final agent = dac.StatefulAgent(
      name: skill.id,
      systemPrompts: [skill.systemPrompt],
      client: client,
      modelConfig: dac.ModelConfig(model: skill.model),
      state: dac.AgentState.empty(),
      tools: tools,
      hooks: [hook],
      maxTurns: skill.maxTurns,
      withGeneralPrinciples: false,
    );

    await for (final ev in agent.runStream([dac.UserMessage.text(input)])) {
      for (final mapped in _mapEvent(ev)) {
        yield mapped;
      }
    }
  }

  dac.Tool _toDacTool(SkillTool t) {
    return dac.Tool(
      name: t.name,
      description: t.description,
      // Tool.parameters 类型 Map<String, dynamic>；SkillTool.jsonSchema 是
      // Map<String, Object?>，这里 cast 一下。
      parameters: t.jsonSchema.cast<String, dynamic>(),
      parameterMode: dac.ToolParameterMode.object,
      executable: (Map<String, dynamic> args) async {
        final out = await t.execute(args);
        // 框架对 String 返回值用 TextPart(toString()) 包成工具结果文本。
        return out.text;
      },
    );
  }

  List<AgentEvent> _mapEvent(dac.StreamingEvent ev) {
    switch (ev.eventType) {
      case dac.StreamingEventType.modelChunkMessage:
        final m = ev.data as dac.ModelMessage;
        return [AgentEventText(m.textOutput ?? '')];
      case dac.StreamingEventType.functionCallRequest:
        // 注意：StatefulAgent 在此事件的 data 里塞的是 List<FunctionCall>，
        // 不是单个 FunctionCall（和 fullModelMessage 不同）。
        final calls = (ev.data as List<dac.FunctionCall>);
        return calls
            .map((c) => AgentEventToolUse(c.name, _decodeArgs(c.arguments)))
            .toList();
      case dac.StreamingEventType.functionCallResult:
        // 注意：data 是 FunctionExecutionResultMessage（含 results 列表），
        // 不是单个 FunctionExecutionResult。
        final msg = ev.data as dac.FunctionExecutionResultMessage;
        return msg.results.map((r) {
          final text = r.content
              .whereType<dac.TextPart>()
              .map((c) => c.text)
              .join('\n');
          return r.isError
              ? AgentEventToolFailed(r.name, text)
              : AgentEventToolDone(r.name, text);
        }).toList();
      case dac.StreamingEventType.fullModelMessage:
        final m = ev.data as dac.ModelMessage;
        return [AgentEventResult(m.textOutput ?? '')];
      case dac.StreamingEventType.beforeCallModel:
      case dac.StreamingEventType.modelRetrying:
        return const [];
    }
  }

  @override
  void dispose() {
    // StatefulAgent 无需显式释放。
  }
}

/// 把 [ToolApprover] 接到 dart_agent_core 的工具执行前拦截点。
///
/// [dac.AgentHook.beforeToolCall] 在工具真正执行前被调用：返回 `proceed()` 放行，
/// 返回 `deny(reason:)` 则不执行，且理由会作为**错误工具结果**回给模型（让它改道）——这正
/// 是"执行前拦截"闸门的语义，而不是 UI 上弹个提示就放行。
class _ApprovalHook extends dac.AgentHook {
  final ToolApprover? approver;
  final List<SkillTool> tools;
  final Set<String> _allowAlways = {};

  _ApprovalHook(this.approver, this.tools);

  SkillTool? _tool(String name) =>
      tools.where((t) => t.name == name).firstOrNull;

  @override
  FutureOr<dac.ToolCallHookResult> beforeToolCall(
    dac.ToolCallHookContext context,
  ) {
    final toolName = context.call.name;
    final tool = _tool(toolName);
    if (approver == null || tool == null || !tool.requiresApproval) {
      return const dac.ToolCallHookResult.proceed();
    }
    if (_allowAlways.contains(toolName)) {
      return const dac.ToolCallHookResult.proceed();
    }

    final args = _decodeArgs(context.call.arguments);
    // approve 是 async；返回 Future 即可（beforeToolCall 允许 FutureOr）。
    return (() async {
      final decision = await approver!.approve(toolName, args);
      return switch (decision) {
        Allow() => const dac.ToolCallHookResult.proceed(),
        AllowAlways() => () {
          _allowAlways.add(toolName);
          return const dac.ToolCallHookResult.proceed();
        }(),
        Deny(:final reason) => dac.ToolCallHookResult.deny(reason: reason),
      };
    })();
  }
}
