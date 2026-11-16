import 'dart:convert';

import 'package:kit_agent/kit_agent.dart';
import 'package:test/test.dart';

/// 假 SSE 流：真网关发的是 `event: x\ndata: {...}\n\n`，这里照抄那个格式。
Stream<String> _fakeSse(List<Map<String, Object?>> events) {
  final buffer = StringBuffer();
  for (final e in events) {
    buffer.writeln('event: ${e['type']}');
    buffer.writeln('data: ${jsonEncode(e)}');
    buffer.writeln();
  }
  return Stream<String>.fromIterable(buffer.toString().split('\n'));
}

void main() {
  group('网关协议', () {
    test('一轮完整对话：start / text / tool_use / tool_done / result', () async {
      final events = <AgentEvent>[];
      String? sessionId;

      await for (final r in parseGatewaySse(_fakeSse([
        {'type': 'start', 'sessionId': 's-1'},
        {'type': 'text', 'text': '好的'},
        {'type': 'tool_use', 'name': 'add_todo', 'args': {'title': '买牛奶'}},
        {'type': 'tool_done', 'name': 'add_todo', 'result': '已添加：买牛奶'},
        {'type': 'result', 'text': '好的，已添加', 'output': {'ok': true}},
      ]))) {
        if (r.sessionId != null) sessionId = r.sessionId;
        if (r.event != null) events.add(r.event!);
      }

      expect(sessionId, 's-1');
      expect(events, hasLength(4));
      expect(events[0], isA<AgentEventText>());
      expect((events[0] as AgentEventText).text, '好的');
      expect(events[1], isA<AgentEventToolUse>());
      expect((events[1] as AgentEventToolUse).name, 'add_todo');
      expect((events[1] as AgentEventToolUse).args, {'title': '买牛奶'});
      expect(events[2], isA<AgentEventToolDone>());
      expect((events[2] as AgentEventToolDone).result, '已添加：买牛奶');
      expect(events[3], isA<AgentEventResult>());
      expect((events[3] as AgentEventResult).text, '好的，已添加');
    });

    test('工具失败和错误事件', () async {
      final events = <AgentEvent>[];
      await for (final r in parseGatewaySse(_fakeSse([
        {'type': 'tool_use', 'name': 'add_todo', 'args': <String, Object?>{}},
        {'type': 'tool_failed', 'name': 'add_todo', 'message': '标题不能为空'},
        {'type': 'error', 'message': '网关炸了'},
      ]))) {
        if (r.event != null) events.add(r.event!);
      }

      expect(events, hasLength(3));
      expect((events[1] as AgentEventToolFailed).message, '标题不能为空');
      expect((events[2] as AgentEventError).message, '网关炸了');
    });

    test('不认识的事件被丢掉，不影响后面的', () async {
      final events = <AgentEvent>[];
      await for (final r in parseGatewaySse(_fakeSse([
        {'type': 'heartbeat', 'at': 1},
        {'type': 'text', 'text': '还在'},
      ]))) {
        if (r.event != null) events.add(r.event!);
      }

      expect(events, hasLength(1));
      expect((events.first as AgentEventText).text, '还在');
    });

    test('字段缺失不炸（网关版本旧一点也认）', () async {
      final r = mapGatewayEvent({'type': 'text'});
      expect(r.event, isA<AgentEventText>());
      expect((r.event! as AgentEventText).text, '');
    });
  });
}
