import 'package:material_ui/material_ui.dart';

import '../../i18n/kit_strings.dart';
import '../../theme/kit_theme.dart';
import 'chat_message.dart';

/// 聊天消息列表 —— 气泡 + 过程折叠。
///
/// 过程（工具调用）折叠成一行是刻意的：agent 一轮里可能调五六个工具，
/// 全摊开会把正文挤没。折叠行只说「做了几件事」，点开才看得到每一步的参数和结果。
///
/// 新消息进来会自动滚到底（[controller] 可以传进来自己控制）。
class ChatMessageList extends StatefulWidget {
  const ChatMessageList({
    super.key,
    required this.messages,
    this.controller,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.spacing = 8,
  });

  final List<ChatMessage> messages;
  final ScrollController? controller;
  final EdgeInsetsGeometry padding;
  final double spacing;

  @override
  State<ChatMessageList> createState() => _ChatMessageListState();
}

class _ChatMessageListState extends State<ChatMessageList> {
  ScrollController? _own;

  ScrollController get _controller => widget.controller ?? (_own ??= ScrollController());

  @override
  void didUpdateWidget(ChatMessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 只在新消息「数量变化」时滚 —— 流式追加文本时每帧都滚会打扰用户翻看历史。
    if (widget.messages.length != oldWidget.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
    }
  }

  void _scrollToEnd() {
    if (!mounted || !_controller.hasClients) return;
    final position = _controller.position;
    if (!position.hasContentDimensions) return;
    _controller.animateTo(
      position.maxScrollExtent,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: _controller,
      padding: widget.padding,
      itemCount: widget.messages.length,
      separatorBuilder: (_, __) => SizedBox(height: widget.spacing),
      itemBuilder: (context, index) => ChatMessageRow(message: widget.messages[index]),
    );
  }
}

/// 一条消息。用户靠右、助手靠左、系统与错误整行铺开。
class ChatMessageRow extends StatelessWidget {
  const ChatMessageRow({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    switch (message) {
      case ChatMessageUser(:final text):
        return _ChatBubble(
          container: tokens.colorScheme.primaryContainer,
          foreground: tokens.colorScheme.onPrimaryContainer,
          alignEnd: true,
          text: text,
        );
      case ChatMessageAssistant(:final text, :final steps):
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 过程在前、正文在后：工具先发生，话后说
            if (steps.isNotEmpty) ChatStepsFold(steps: steps),
            if (text.isNotEmpty)
              _ChatBubble(
                container: tokens.extras.surfaceVariant,
                foreground: tokens.colorScheme.onSurface,
                alignEnd: false,
                text: text,
              ),
          ],
        );
      case ChatMessageSystem(:final text):
        return Text(
          text,
          style: tokens.textTheme.bodySmall?.copyWith(
            color: tokens.colorScheme.onSurfaceVariant,
          ),
        );
      case ChatMessageError(:final text):
        return Text(
          '⚠️ $text',
          style: tokens.textTheme.bodyMedium?.copyWith(color: tokens.colorScheme.error),
        );
    }
  }
}

/// 过程折叠条 —— 收起时一行，展开时每步一行。
///
/// 折叠状态记在组件里（没提到上层）：换一轮对话就该重新收起，上层不需要管这个。
class ChatStepsFold extends StatefulWidget {
  const ChatStepsFold({super.key, required this.steps, this.initiallyExpanded = false});

  final List<ChatStep> steps;
  final bool initiallyExpanded;

  @override
  State<ChatStepsFold> createState() => _ChatStepsFoldState();
}

class _ChatStepsFoldState extends State<ChatStepsFold> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    final strings = KitStringsScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: tokens.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 2),
                Text(
                  strings.chatProcessCount(widget.steps.length),
                  style: tokens.textTheme.labelMedium?.copyWith(
                    color: tokens.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          for (final step in widget.steps) ChatStepRow(step: step),
      ],
    );
  }
}

/// 折叠展开后的其中一步：工具名 + 状态 + 参数 + 结果。
class ChatStepRow extends StatelessWidget {
  const ChatStepRow({super.key, required this.step});

  final ChatStep step;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    final strings = KitStringsScope.of(context);
    final statusLabel = switch (step.status) {
      ChatStepStatus.running => strings.chatStepRunning,
      ChatStepStatus.done => strings.chatStepDone,
      ChatStepStatus.failed => strings.chatStepFailed,
    };
    final statusColor = switch (step.status) {
      ChatStepStatus.running => tokens.colorScheme.onSurfaceVariant,
      ChatStepStatus.done => tokens.colorScheme.primary,
      ChatStepStatus.failed => tokens.colorScheme.error,
    };

    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 2, bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(step.tool, style: tokens.textTheme.labelMedium),
              Text(
                ' · $statusLabel',
                style: tokens.textTheme.labelSmall?.copyWith(color: statusColor),
              ),
            ],
          ),
          if (step.args.trim().isNotEmpty)
            Text(
              step.args,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: tokens.textTheme.bodySmall?.copyWith(
                color: tokens.colorScheme.onSurfaceVariant,
              ),
            ),
          if ((step.result ?? '').trim().isNotEmpty)
            Text(
              step.result!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: tokens.textTheme.bodySmall?.copyWith(
                color: tokens.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

/// 一个气泡。用户的靠右，助手的靠左。
class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.container,
    required this.foreground,
    required this.alignEnd,
    required this.text,
  });

  final Color container;
  final Color foreground;
  final bool alignEnd;
  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    return Align(
      alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: container,
          borderRadius: themedCorner(context, 12),
        ),
        child: Text(
          text,
          style: tokens.textTheme.bodyMedium?.copyWith(color: foreground),
        ),
      ),
    );
  }
}
