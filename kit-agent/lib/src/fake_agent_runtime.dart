import 'dart:async';

import 'agent_event.dart';
import 'agent_runtime.dart';
import 'skill_definition.dart';
import 'tool_approval.dart';

/// 假 agent 运行时：不联网、不花钱、不需要 API key，按脚本吐事件。
///
/// 实现的是和 `DartAgentRuntime` 同一个 [AgentRuntime] 契约，所以 UI 代码一行都不用改。
///
/// 三个用途：
/// - **预览 / 无 key 演示**：聊天页在没有 key 的机器上也能跑通
/// - **UI 单测**：不用 mock 整条链，直接断言气泡怎么长
/// - **复现 bug**：把线上事件序列录成 [FakeReply]，稳定重放
///
/// 注意：审批闸门（[ToolApprover]）在这里**不生效** —— 闸门挂在工具执行上，
/// 而假运行时根本不执行工具。[FakeReply.toolCall] 只发一条 [AgentEventToolUse] 给 UI 看。
class FakeAgentRuntime implements AgentRuntime {
  final List<FakeReply> replies;
  final Duration chunkDelay;

  FakeAgentRuntime({
    List<FakeReply>? replies,
    this.chunkDelay = Duration.zero,
  }) : replies = replies == null || replies.isEmpty
            ? [const FakeReply.text(defaultReplyText)]
            : replies;

  /// 默认回复文案。
  static const String defaultReplyText = '（演示模式）这是一条本地假回复，没有调用模型。';

  final List<String> _inputs = <String>[];

  /// 所有 send 过的输入（按顺序），测试里用来断言 UI 真的把话送进来了。
  List<String> get inputs => List.unmodifiable(_inputs);

  @override
  AgentSession session(SkillDefinition skill, {ToolApprover? approver}) =>
      _FakeAgentSession(
        replies: replies,
        chunkDelay: chunkDelay,
        onInput: _inputs.add,
      );
}

/// 一轮假回复。
sealed class FakeReply {
  const FakeReply();

  /// 回一段文本；按 [chunkSize] 个字符切块，模拟流式增量。
  ///
  /// 注意：redirecting factory 不能自带默认值，默认值由目标构造器提供。
  const factory FakeReply.text(String text, {int chunkSize}) = _FakeReplyText;

  /// 先发一条工具调用事件，再（可选）回一段文本。
  ///
  /// 真正的工具执行不会发生 —— [then] 只是让 UI 看到「调用工具 → 继续回答」的完整事件序列。
  const factory FakeReply.toolCall(String name, {String then}) =
      _FakeReplyToolCall;

  /// 直接出错（鉴权失败、网络断开这类）。
  const factory FakeReply.failure(String message) = _FakeReplyFailure;
}

final class _FakeReplyText extends FakeReply {
  final String text;
  final int chunkSize;
  const _FakeReplyText(this.text, {this.chunkSize = 8});
}

final class _FakeReplyToolCall extends FakeReply {
  final String name;
  final String then;
  const _FakeReplyToolCall(this.name, {this.then = ''});
}

final class _FakeReplyFailure extends FakeReply {
  final String message;
  const _FakeReplyFailure(this.message);
}

/// 一个假会话：无状态服务端，只按顺序消费 replies。
class _FakeAgentSession implements AgentSession {
  final List<FakeReply> replies;
  final Duration chunkDelay;
  final void Function(String) onInput;

  _FakeAgentSession({
    required this.replies,
    required this.chunkDelay,
    required this.onInput,
  });

  int _turn = 0;

  @override
  Stream<AgentEvent> send(String input) async* {
    onInput(input);
    final reply = replies[_turn.clamp(0, replies.length - 1)];
    _turn++;

    switch (reply) {
      case _FakeReplyText(:final text, :final chunkSize):
        yield* _emitChunks(text, chunkSize);
        yield AgentEventResult(text);
      case _FakeReplyToolCall(:final name, :final then):
        yield AgentEventToolUse(name, const {});
        yield AgentEventToolDone(name, fakeToolResult);
        yield* _emitChunks(then, defaultChunkSize);
        yield AgentEventResult(then);
      case _FakeReplyFailure(:final message):
        yield AgentEventError(message);
    }
  }

  Stream<AgentEvent> _emitChunks(String text, int chunkSize) async* {
    if (text.isEmpty) return;
    final size = chunkSize < 1 ? 1 : chunkSize;
    final runes = text.runes.toList();
    var index = 0;
    while (index < runes.length) {
      final end = (index + size).clamp(0, runes.length);
      final chunk = String.fromCharCodes(runes.sublist(index, end));
      index = end;
      if (chunkDelay > Duration.zero) await Future<void>.delayed(chunkDelay);
      yield AgentEventText(chunk);
    }
  }

  @override
  void dispose() {}

  static const int defaultChunkSize = 8;

  /// 假工具的返回文案 —— 让 UI 的"过程折叠"在没有模型时也能看到完成态。
  static const String fakeToolResult = '（演示模式）工具执行完毕';
}
