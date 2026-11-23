/// Agent 运行时向 UI 抛的事件。
///
/// 关键语义：
/// - [AgentEventText] 是**增量块**，不是整段回复；同一轮会来很多次，UI 追加进当前气泡。
/// - [AgentEventResult.text] 是拼好的完整回复，只用来标记"说完了"，**别再追加一遍**。
sealed class AgentEvent {
  const AgentEvent();
}

/// 流式文本增量块（打字机效果）。
final class AgentEventText extends AgentEvent {
  final String text;
  const AgentEventText(this.text);
}

/// 工具被调用，带入参（UI 可做确认 / 进度）。
final class AgentEventToolUse extends AgentEvent {
  final String name;
  final Map<String, Object?> args;
  const AgentEventToolUse(this.name, this.args);
}

/// 工具跑完，带结果。
final class AgentEventToolDone extends AgentEvent {
  final String name;
  final String result;
  const AgentEventToolDone(this.name, this.result);
}

/// 工具没跑成，带原因。
final class AgentEventToolFailed extends AgentEvent {
  final String name;
  final String message;
  const AgentEventToolFailed(this.name, this.message);
}

/// 整轮完成，带拼好的完整回复（只标记"说完了"，别再追加）。
final class AgentEventResult extends AgentEvent {
  final String text;
  const AgentEventResult(this.text);
}

/// 出错。
final class AgentEventError extends AgentEvent {
  final String message;
  const AgentEventError(this.message);
}
