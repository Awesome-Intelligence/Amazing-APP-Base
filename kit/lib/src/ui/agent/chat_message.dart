/// 一条聊天消息。
///
/// 为什么要分类型：用户的话、助手的回复、系统提示、出错 —— 四种长得不一样
/// （气泡颜色、对齐、能不能折叠都不一样）。早先一个 `Msg(fromUser, text)` 只够
/// 「把字显示出来」，过程（工具调用）就没地方挂 —— 那一层是 agent 界面真正需要的东西。
///
/// Dart 没有嵌套类，所以用 `ChatMessage.user(...)` 这类重定向构造器保持 KMP 的调用手感，
/// 匹配时用具体类型（`case ChatMessageAssistant()`）。
sealed class ChatMessage {
  const ChatMessage();

  /// 用户说的话。
  const factory ChatMessage.user(String text) = ChatMessageUser;

  /// 助手回复（默认值由 [ChatMessageAssistant] 提供，redirecting 构造器不能自带默认值）。
  const factory ChatMessage.assistant({String text, List<ChatStep> steps}) =
      ChatMessageAssistant;

  /// 系统提示：模式切换、这一轮没有结果之类的中性信息。
  const factory ChatMessage.system(String text) = ChatMessageSystem;

  /// 出错。
  const factory ChatMessage.error(String text) = ChatMessageError;
}

/// 用户说的话。
final class ChatMessageUser extends ChatMessage {
  const ChatMessageUser(this.text);

  final String text;
}

/// 助手的回复。
final class ChatMessageAssistant extends ChatMessage {
  const ChatMessageAssistant({this.text = '', this.steps = const <ChatStep>[]});

  /// 正文（流式增量直接追加到尾巴上，就是打字机效果）。
  final String text;

  /// 这一轮里做过的工具调用 —— 折叠成一行，展开才看得到细节。
  final List<ChatStep> steps;

  ChatMessageAssistant copyWith({String? text, List<ChatStep>? steps}) =>
      ChatMessageAssistant(text: text ?? this.text, steps: steps ?? this.steps);

  /// 追加流式文本（打字机：每次增量接到尾巴）。
  ChatMessageAssistant appendText(String delta) => copyWith(text: text + delta);

  /// 追加一步工具调用。
  ChatMessageAssistant addStep(ChatStep step) => copyWith(steps: [...steps, step]);

  /// 按工具名更新最近一步的状态（工具跑完/失败时回填）。
  ChatMessageAssistant updateStep(
    String tool, {
    ChatStepStatus? status,
    String? result,
  }) {
    final index = steps.lastIndexWhere((s) => s.tool == tool);
    if (index < 0) return this;
    final next = [...steps];
    next[index] = next[index].copyWith(status: status, result: result);
    return copyWith(steps: next);
  }
}

/// 系统提示。
final class ChatMessageSystem extends ChatMessage {
  const ChatMessageSystem(this.text);

  final String text;
}

/// 出错。
final class ChatMessageError extends ChatMessage {
  const ChatMessageError(this.text);

  final String text;
}

/// 一次工具调用 —— 折叠条上的一行。
class ChatStep {
  const ChatStep({
    required this.tool,
    this.args = '',
    this.status = ChatStepStatus.running,
    this.result,
  });

  /// 工具名（snake_case，和模型看到的名字一致）。
  final String tool;

  /// 入参摘要（JSON 字符串）。
  final String args;

  /// 跑到哪一步了。
  final ChatStepStatus status;

  /// 工具返回的文案（跑完才有）。
  final String? result;

  ChatStep copyWith({
    String? tool,
    String? args,
    ChatStepStatus? status,
    String? result,
  }) =>
      ChatStep(
        tool: tool ?? this.tool,
        args: args ?? this.args,
        status: status ?? this.status,
        result: result ?? this.result,
      );
}

/// 工具调用的状态。
enum ChatStepStatus {
  /// 模型要调这个工具，正在等结果（也可能正在等用户点头）。
  running,

  /// 跑完了。
  done,

  /// 没跑成。
  failed,
}
