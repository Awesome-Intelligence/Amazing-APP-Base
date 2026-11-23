import 'dart:async';
import 'dart:convert';

import 'package:kit_agent/kit_agent.dart' as ac;
import 'package:dart_agent_core/dart_agent_core.dart' as dac;
import 'package:dio/dio.dart';
import 'package:test/test.dart';

/// 脚本化假 LLM：按 stream 调用顺序吐出预设的 [dac.ModelMessage]。
///
/// 设计：第 0 次 stream 调用吐"带 functionCall 的消息"（驱动工具执行），
/// 之后的调用吐"最终文本"。这样能在**完全不连网、不用 API key** 的情况下，
/// 把 dart_agent_core 的真实 agent loop、工具执行、审批闸门、事件映射全部跑一遍。
class _ScriptedClient extends dac.LLMClient {
  final List<dac.ModelMessage> turns;
  int _i = 0;

  _ScriptedClient(this.turns);

  @override
  Future<dac.ModelMessage> generate(
    List<dac.LLMMessage> messages, {
    List<dac.Tool>? tools,
    dac.ToolChoice? toolChoice,
    required dac.ModelConfig modelConfig,
    bool? jsonOutput,
    CancelToken? cancelToken,
  }) async =>
      turns.isNotEmpty ? turns.last : dac.ModelMessage(model: modelConfig.model);

  @override
  Future<Stream<dac.StreamingMessage>> stream(
    List<dac.LLMMessage> messages, {
    List<dac.Tool>? tools,
    dac.ToolChoice? toolChoice,
    required dac.ModelConfig modelConfig,
    bool? jsonOutput,
    CancelToken? cancelToken,
  }) async {
    final idx = _i < turns.length ? _i : turns.length - 1;
    _i++;
    return Stream.value(dac.StreamingMessage(modelMessage: turns[idx]));
  }
}

/// 普通工具：执行时把 title 写进 [log]（副作用），用来证明"真的跑过"。
class _AddTool extends ac.SkillTool {
  final List<String> log;
  _AddTool(this.log) : super('add_item', 'Add an item to the list');

  @override
  Map<String, Object?> get jsonSchema => const {
        'type': 'object',
        'properties': {'title': {'type': 'string'}},
        'required': ['title'],
      };

  @override
  Future<ac.ToolOutput> execute(Map<String, Object?> args) async {
    final title = args['title'] as String;
    log.add(title);
    return ac.ToolOutput.text('added $title');
  }
}

/// 危险工具：需要审批。执行时把 title 写进 [log]；被拒时不应被调用。
class _DeleteTool extends ac.SkillTool {
  final List<String> log;
  _DeleteTool(this.log) : super('delete_item', 'Delete an item (dangerous)');

  @override
  bool get requiresApproval => true;

  @override
  Map<String, Object?> get jsonSchema => const {
        'type': 'object',
        'properties': {'title': {'type': 'string'}},
        'required': ['title'],
      };

  @override
  Future<ac.ToolOutput> execute(Map<String, Object?> args) async {
    final title = args['title'] as String;
    log.add(title);
    return ac.ToolOutput.text('deleted $title');
  }
}

/// 永远放行的审批器。
class _AllowAllApprover extends ac.ToolApprover {
  @override
  Future<ac.ToolApproval> approve(String toolName, Map<String, Object?> args) =>
      Future.value(const ac.Allow());
}

/// 永远拒绝的审批器。
class _DenyAllApprover extends ac.ToolApprover {
  @override
  Future<ac.ToolApproval> approve(String toolName, Map<String, Object?> args) =>
      Future.value(const ac.Deny('blocked by test'));
}

dac.ModelMessage _toolCallTurn(String name, Map<String, Object?> args) =>
    dac.ModelMessage(
      model: 'fake-model',
      stopReason: 'tool_use',
      functionCalls: [
        dac.FunctionCall(
          id: 'fc1',
          name: name,
          arguments: jsonEncode(args),
        ),
      ],
    );

dac.ModelMessage _finalTextTurn(String text) => dac.ModelMessage(
      model: 'fake-model',
      stopReason: 'end_turn',
      textOutput: text,
    );

Future<List<ac.AgentEvent>> _run(
  ac.SkillDefinition skill,
  ac.ToolApprover? approver,
  _ScriptedClient client, {
  bool debug = false,
}) async {
  final runtime = ac.DartAgentRuntime(apiKey: 'test', client: client);
  final session = runtime.session(skill, approver: approver);
  final events = <ac.AgentEvent>[];
  await for (final e in session.send('please do it')) {
    events.add(e);
    if (debug) {
      final s = switch (e) {
        ac.AgentEventText t => 'Text(${t.text})',
        ac.AgentEventToolUse u => 'ToolUse(${u.name})',
        ac.AgentEventToolDone d => 'ToolDone(${d.name},${d.result})',
        ac.AgentEventToolFailed f => 'ToolFailed(${f.name},${f.message})',
        ac.AgentEventResult r => 'Result(${r.text})',
        ac.AgentEventError er => 'Error(${er.message})',
        // AgentEvent 是 sealed，上面已穷尽全部分支 —— 加 `_` 反而是死代码。
      };
      // ignore: avoid_print
      print('  EVENT: $s');
    }
  }
  return events;
}

void main() {
  group('DartAgentRuntime 集成（脚本化假 LLM，不连网）', () {
    test('工具被真正执行 + 事件流正确映射', () async {
      final log = <String>[];
      final skill = ac.SkillDefinition(
        id: 'todo',
        name: 'Todo',
        description: 'todo',
        systemPrompt: 'you are a todo helper',
        model: 'fake-model',
        maxTurns: 10,
        tools: [_AddTool(log)],
      );
      final client = _ScriptedClient([
        _toolCallTurn('add_item', {'title': 'milk'}),
        _finalTextTurn('done'),
      ]);

      final events = await _run(skill, _AllowAllApprover(), client);

      // 1) 工具真的执行了（副作用发生）
      expect(log, contains('milk'),
          reason: 'add_item 的 execute 应当被调用，写入副作用');

      // 2) 事件流：先 ToolUse，再 ToolDone，最后 Result
      final names = events.map((e) => e.runtimeType.toString()).toList();
      expect(names, contains('AgentEventToolUse'));
      expect(names, contains('AgentEventToolDone'));
      expect(names, contains('AgentEventResult'));

      // 3) ToolUse 携带了正确工具名与入参
      final toolUse = events.whereType<ac.AgentEventToolUse>().first;
      expect(toolUse.name, 'add_item');
      expect(toolUse.args['title'], 'milk');

      // 4) 最终完整回复事件（取最后一次，因为工具调用那一轮也会发一个空 Result）
      final result = events.whereType<ac.AgentEventResult>().last;
      expect(result.text, 'done');
    });

    test('危险工具被审批闸门拦截：execute 根本没跑', () async {
      final log = <String>[];
      final skill = ac.SkillDefinition(
        id: 'todo',
        name: 'Todo',
        description: 'todo',
        systemPrompt: 'you are a todo helper',
        model: 'fake-model',
        maxTurns: 10,
        tools: [_DeleteTool(log)],
      );
      final client = _ScriptedClient([
        _toolCallTurn('delete_item', {'title': 'milk'}),
        _finalTextTurn('ok, did nothing'),
      ]);

      final events = await _run(skill, _DenyAllApprover(), client);

      // 核心断言：被拒时 execute 不应被调用（无副作用）
      expect(log, isEmpty,
          reason: 'delete_item 被 Deny，execute 不应执行');

      // 闸门把"拒绝"作为工具结果回给模型：框架标记为 isError -> ToolFailed，
      // 模型据此改道（这正是"执行前拦截"闸门想要的语义）。
      final failed = events.whereType<ac.AgentEventToolFailed>().firstWhere(
        (e) => e.name == 'delete_item',
        orElse: () => throw StateError('缺少 delete_item 的工具结果事件'),
      );
      expect(failed.message, contains('denied'),
          reason: '拒绝理由应作为工具结果文本回传');
    });

    test('无审批器时：需要审批的工具直接放行', () async {
      final log = <String>[];
      final skill = ac.SkillDefinition(
        id: 'todo',
        name: 'Todo',
        description: 'todo',
        systemPrompt: 'you are a todo helper',
        model: 'fake-model',
        maxTurns: 10,
        tools: [_DeleteTool(log)],
      );
      final client = _ScriptedClient([
        _toolCallTurn('delete_item', {'title': 'milk'}),
        _finalTextTurn('deleted'),
      ]);

      // approver 传 null：_ApprovalHook 对无审批器的工具直接 proceed
      final events = await _run(skill, null, client);

      expect(log, contains('milk'),
          reason: '无审批器时 delete_item 应被直接放行执行');
      final done = events.whereType<ac.AgentEventToolDone>().firstWhere(
        (e) => e.name == 'delete_item',
        orElse: () => throw StateError('缺少 delete_item 的工具结果事件'),
      );
      expect(done.result, contains('deleted'));
    });
  });
}
