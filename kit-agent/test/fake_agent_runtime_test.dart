import 'package:kit_agent/kit_agent.dart';
import 'package:test/test.dart';

void main() {
  group('FakeAgentRuntime', () {
    test('文本按块吐，最后给整段 Result', () async {
      final runtime = FakeAgentRuntime(
        replies: const [FakeReply.text('你好世界你好世界', chunkSize: 2)],
      );
      final events = await runtime.session(_skill()).send('hi').toList();

      final chunks = events.whereType<AgentEventText>().map((e) => e.text).toList();
      expect(chunks, ['你好', '世界', '你好', '世界']);
      expect(events.whereType<AgentEventResult>().single.text, '你好世界你好世界');
    });

    test('工具调用：先 ToolUse 再 ToolDone，然后继续回答', () async {
      final runtime = FakeAgentRuntime(
        replies: const [FakeReply.toolCall('now', then: '好了')],
      );
      final events = await runtime.session(_skill()).send('几点').toList();

      expect(events.whereType<AgentEventToolUse>().single.name, 'now');
      expect(events.whereType<AgentEventToolDone>().single.name, 'now');
      expect(events.whereType<AgentEventResult>().single.text, '好了');
    });

    test('失败只发 Error，不发 Result', () async {
      final runtime = FakeAgentRuntime(
        replies: const [FakeReply.failure('没网')],
      );
      final events = await runtime.session(_skill()).send('hi').toList();

      expect(events.whereType<AgentEventError>().single.message, '没网');
      expect(events.whereType<AgentEventResult>(), isEmpty);
    });

    test('多轮按顺序消费，用完重复最后一条', () async {
      final runtime = FakeAgentRuntime(
        replies: const [FakeReply.text('一'), FakeReply.text('二')],
      );
      final session = runtime.session(_skill());
      final texts = <String>[];
      for (final input in ['a', 'b', 'c']) {
        final events = await session.send(input).toList();
        texts.add(events.whereType<AgentEventResult>().single.text);
      }
      expect(texts, ['一', '二', '二']);
      expect(runtime.inputs, ['a', 'b', 'c']);
    });
  });
}

SkillDefinition _skill() => const SkillDefinition(
      id: 't',
      name: 't',
      description: 't',
      systemPrompt: 't',
      tools: [],
    );
