import 'dart:async';
import 'agent_event.dart';

/// 工具调用步骤的状态。
enum ChatStepStatus { pending, running, done, failed }

/// 聊天里的一次工具调用（过程折叠用）。
class ChatStep {
  final String toolName;
  final Map<String, Object?> args;
  ChatStepStatus status;
  String? result;
  String? error;

  ChatStep(this.toolName, this.args, [this.status = ChatStepStatus.pending]);
}

/// 一条聊天消息（UI 只认消息，不认事件）。
sealed class ChatMessage {
  const ChatMessage();
}

final class UserChatMessage extends ChatMessage {
  final String text;
  const UserChatMessage(this.text);
}

final class AssistantChatMessage extends ChatMessage {
  String text; // 累计文本
  final List<ChatStep> steps;
  AssistantChatMessage([this.text = '']) : steps = [];
}

final class SystemChatMessage extends ChatMessage {
  final String text;
  const SystemChatMessage(this.text);
}

final class ErrorChatMessage extends ChatMessage {
  final String message;
  const ErrorChatMessage(this.message);
}

/// 事件 → 消息的映射。app 只 `log.user(...)` / `log.onEvent(...)`，不自己写状态机。
class ChatLog {
  final List<ChatMessage> _messages = [];
  final StreamController<List<ChatMessage>> _controller =
      StreamController<List<ChatMessage>>.broadcast();

  /// 消息列表（只读视图）。
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  /// 消息变化流（每次变更推整个列表），UI 直接 collect 渲染。
  Stream<List<ChatMessage>> get stream => _controller.stream;

  /// 记一条用户消息。
  void user(String text) {
    _messages.add(UserChatMessage(text));
    _emit();
  }

  /// 把 agent 事件灌进日志，内部维护"当前气泡"与工具步骤。
  void onEvent(AgentEvent event) {
    switch (event) {
      case AgentEventText():
        _currentAssistant().text += event.text;
      case AgentEventToolUse():
        _currentAssistant().steps.add(
              ChatStep(event.name, event.args, ChatStepStatus.running),
            );
      case AgentEventToolDone():
        _lastStep(event.name)?.status = ChatStepStatus.done;
        _lastStep(event.name)?.result = event.result;
      case AgentEventToolFailed():
        final s = _lastStep(event.name);
        s?.status = ChatStepStatus.failed;
        s?.error = event.message;
      case AgentEventResult():
        // 完整回复已通过增量块累计，这里只确保气泡存在；不要再追加一遍。
        _currentAssistant();
      case AgentEventError():
        _messages.add(ErrorChatMessage(event.message));
    }
    _emit();
  }

  /// 记一条系统消息。
  void system(String text) {
    _messages.add(SystemChatMessage(text));
    _emit();
  }

  AssistantChatMessage _currentAssistant() {
    final last = _messages.lastOrNull;
    if (last is AssistantChatMessage) return last;
    final m = AssistantChatMessage();
    _messages.add(m);
    return m;
  }

  ChatStep? _lastStep(String toolName) {
    final a = _messages.lastWhere(
      (m) => m is AssistantChatMessage,
      orElse: () => AssistantChatMessage(),
    );
    if (a is! AssistantChatMessage) return null;
    for (var i = a.steps.length - 1; i >= 0; i--) {
      if (a.steps[i].toolName == toolName) return a.steps[i];
    }
    return null;
  }

  void _emit() => _controller.add(messages);

  void dispose() => _controller.close();
}
