import 'package:kit_agent/kit_agent.dart';
import 'package:test/test.dart';

/// 一个最小 skill 用于测试契约层（不依赖 dart_agent_core）。
class _EchoTool extends SkillTool {
  _EchoTool() : super('echo', '回声工具');
  @override
  Future<ToolOutput> execute(Map<String, Object?> args) async {
    return ToolOutput.text('echo:${args['text']}');
  }
}

class _BadTool extends SkillTool {
  _BadTool() : super('DeleteData', '名字不是 snake_case，且危险');
  @override
  bool get requiresApproval => true;
  @override
  Future<ToolOutput> execute(Map<String, Object?> args) async {
    return ToolOutput.text('deleted');
  }
}

SkillDefinition makeSkill({List<SkillTool>? tools, int maxTurns = 20}) {
  return SkillDefinition(
    id: 'todo',
    name: '待办助手',
    description: '管理本地待办',
    systemPrompt: '你是待办助手。',
    tools: tools ?? [_EchoTool()],
    maxTurns: maxTurns,
  );
}

void main() {
  group('SkillContract.violations', () {
    test('正常 skill 无违规', () {
      expect(violations(makeSkill()), isEmpty);
    });

    test('空字段被抓', () {
      final s = SkillDefinition(
        id: '',
        name: '',
        description: '',
        systemPrompt: '',
        tools: const [],
      );
      final v = violations(s);
      expect(v, contains('skill.id 为空'));
      expect(v, contains('skill.name 为空'));
      expect(v, contains('skill.description 为空'));
    });

    test('工具名非 snake_case 被抓', () {
      final v = violations(makeSkill(tools: [_BadTool()]));
      expect(v, contains(contains('不是 snake_case')));
    });

    test('maxTurns 非正被抓', () {
      final v = violations(makeSkill(maxTurns: 0));
      expect(v, contains(contains('非正')));
    });

    test('工具重名被抓', () {
      final v = violations(makeSkill(tools: [_EchoTool(), _EchoTool()]));
      expect(v, contains(contains('重名')));
    });
  });

  group('SkillSamples.runSamples', () {
    test('期望片段命中则无失败', () async {
      final failures = await runSamples(makeSkill(), [
        SkillSample('echo', {'text': 'hi'}, 'echo:hi'),
      ]);
      expect(failures, isEmpty);
    });

    test('期望片段缺失则记失败', () async {
      final failures = await runSamples(makeSkill(), [
        SkillSample('echo', {'text': 'hi'}, 'NOPE'),
      ]);
      expect(failures, hasLength(1));
      expect(failures.first.toolName, 'echo');
    });

    test('找不到工具则记失败', () async {
      final failures = await runSamples(makeSkill(), [
        SkillSample('nope', {}, 'x'),
      ]);
      expect(failures, hasLength(1));
      expect(failures.first.reason, contains('找不到工具'));
    });
  });

  group('ChatLog', () {
    test('文本增量累计到同一气泡', () {
      final log = ChatLog();
      log.user('你好');
      log.onEvent(const AgentEventText('你'));
      log.onEvent(const AgentEventText('好'));
      final a = log.messages.whereType<AssistantChatMessage>().single;
      expect(a.text, '你好');
    });

    test('工具调用→完成映射到步骤状态', () {
      final log = ChatLog();
      log.onEvent(const AgentEventToolUse('echo', {'text': 'x'}));
      log.onEvent(const AgentEventToolDone('echo', 'echo:x'));
      final a = log.messages.whereType<AssistantChatMessage>().single;
      expect(a.steps.single.status, ChatStepStatus.done);
      expect(a.steps.single.result, 'echo:x');
    });

    test('工具失败映射到 failed', () {
      final log = ChatLog();
      log.onEvent(const AgentEventToolUse('echo', {}));
      log.onEvent(const AgentEventToolFailed('echo', 'boom'));
      final a = log.messages.whereType<AssistantChatMessage>().single;
      expect(a.steps.single.status, ChatStepStatus.failed);
      expect(a.steps.single.error, 'boom');
    });
  });
}
