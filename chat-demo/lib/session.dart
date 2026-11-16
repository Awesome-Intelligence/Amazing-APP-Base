import 'dart:io' show Platform;

import 'package:kit_agent/kit_agent.dart';

import 'now_tool.dart';

/// 从环境变量建会话；`fake = true` 时用本地假运行时（不联网、不需要 key）。
///
/// 返回 null = 没找到 API key，UI 会提示怎么配。
AgentSession? createSession(bool fake) {
  if (fake) {
    return FakeAgentRuntime(
      replies: const [
        FakeReply.text('（假运行时）我在。这一轮没有联网，也没有花 token。', chunkSize: 6),
        FakeReply.toolCall('now', then: '（假运行时）工具调用事件已经发给你了，但工具本身不会执行。'),
      ],
    ).session(demoSkill(), approver: const AllowAllApprover());
  }

  final key = _env('ANTHROPIC_API_KEY') ?? _env('ANTHROPIC_AUTH_TOKEN');
  if (key == null) return null;
  final baseUrl = _env('ANTHROPIC_BASE_URL') ?? 'https://api.anthropic.com';
  final model = _env('ANTHROPIC_MODEL') ??
      _env('ANTHROPIC_DEFAULT_SONNET_MODEL') ??
      'claude-opus-5-5';
  return DartAgentRuntime(apiKey: key, baseUrl: baseUrl)
      .session(demoSkill(model: model), approver: const AllowAllApprover());
}

/// demo 的 skill：验证 agent 对话链路。
SkillDefinition demoSkill({String model = 'claude-opus-5-5'}) => SkillDefinition(
      id: 'chat_demo',
      name: '对话演示',
      description: '验证 agent 对话链路',
      systemPrompt:
          '你是一个用于验证 agent 框架的对话助手。回答简短。需要当前时间时调用 now 工具。',
      tools: [NowTool()],
      model: model,
    );

String? _env(String name) {
  final v = Platform.environment[name];
  return (v == null || v.trim().isEmpty) ? null : v;
}
