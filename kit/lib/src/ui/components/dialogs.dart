import 'package:material_ui/material_ui.dart';

import '../../i18n/kit_strings.dart';
import '../../theme/kit_theme.dart';
import 'buttons.dart';

/// 弹窗外壳 —— 统一 28 圆角、surface 底、0 阴影。
///
/// M3 的对话框用色阶分层，不叠阴影；Swiss / Notion / E-Ink 更是明确禁阴影。
Widget kitDialogShell(BuildContext context, Widget child) {
  final tokens = KitTheme.of(context);
  return Dialog(
    backgroundColor: tokens.colorScheme.surface,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: tokens.shapes.extraLarge),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Padding(padding: const EdgeInsets.all(24), child: child),
    ),
  );
}

/// 确认弹窗 —— M3 规范，28 圆角、紧凑内边距。
///
/// 用法（弹窗当成路由内容推开，而不是靠条件渲染）：
/// ```dart
/// final ok = await ConfirmDialog.show(context, title: '…', message: '…');
/// ```
/// 也可以自己塞进 `showDialog(builder: ...)`。
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
    required this.onDismiss,
    this.confirmText,
    this.dismissText,
    this.icon,
    this.iconContentDescription,
    this.iconBackgroundColor,
  });

  final String title;
  final String message;
  final VoidCallback onConfirm;
  final VoidCallback onDismiss;
  final String? confirmText;
  final String? dismissText;

  /// 顶部图标（删除确认用垃圾桶）。给了才会渲染 64 的圆角图标块。
  final IconData? icon;

  /// 图标的无障碍描述；图标只是强化语义时可留空。
  final String? iconContentDescription;

  final Color? iconBackgroundColor;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    final strings = KitStringsScope.of(context);

    return kitDialogShell(
      context,
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: themedCrossAxisAlignment(context, CrossAxisAlignment.center),
        children: [
          if (icon != null) ...[
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: iconBackgroundColor ?? tokens.colorScheme.primaryContainer,
                borderRadius: tokens.shapes.large,
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 32,
                color: tokens.colorScheme.onPrimaryContainer,
                semanticLabel: iconContentDescription,
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            title,
            textAlign: themedTextAlign(context, TextAlign.center),
            style: tokens.textTheme.headlineSmall,
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: themedTextAlign(context, TextAlign.center),
              style: tokens.textTheme.bodyMedium
                  ?.copyWith(color: tokens.colorScheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SmallSecondaryButton(
                text: dismissText ?? strings.cancel,
                onPressed: onDismiss,
              ),
              const SizedBox(width: 8),
              SmallSecondaryButton(
                text: confirmText ?? strings.confirm,
                onPressed: onConfirm,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 直接弹窗并等结果：确认返回 true，取消/点外部返回 false。
  static Future<bool> show(
    BuildContext context, {
    required String title,
    String message = '',
    String? confirmText,
    String? dismissText,
    IconData? icon,
    String? iconContentDescription,
    Color? iconBackgroundColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => ConfirmDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        dismissText: dismissText,
        icon: icon,
        iconContentDescription: iconContentDescription,
        iconBackgroundColor: iconBackgroundColor,
        onConfirm: () => Navigator.of(dialogContext).pop(true),
        onDismiss: () => Navigator.of(dialogContext).pop(false),
      ),
    );
    return result ?? false;
  }
}

/// 单选弹窗。
///
/// 「先选后确认」：点选项只改待提交值，点确认才回调 —— 这样误触单选不会立刻生效。
class SelectDialog extends StatefulWidget {
  const SelectDialog({
    super.key,
    required this.title,
    required this.options,
    required this.selectedIndex,
    required this.onSelect,
    required this.onDismiss,
  });

  final String title;
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onDismiss;

  @override
  State<SelectDialog> createState() => _SelectDialogState();

  /// 弹窗并返回选中下标；取消返回 null。
  static Future<int?> show(
    BuildContext context, {
    required String title,
    required List<String> options,
    required int selectedIndex,
  }) {
    return showDialog<int>(
      context: context,
      builder: (dialogContext) => SelectDialog(
        title: title,
        options: options,
        selectedIndex: selectedIndex,
        onSelect: (i) => Navigator.of(dialogContext).pop(i),
        onDismiss: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }
}

class _SelectDialogState extends State<SelectDialog> {
  late int _pending = widget.selectedIndex;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    final strings = KitStringsScope.of(context);

    return kitDialogShell(
      context,
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: themedCrossAxisAlignment(context, CrossAxisAlignment.center),
        children: [
          Text(
            widget.title,
            textAlign: themedTextAlign(context, TextAlign.center),
            style: tokens.textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          // Flutter 3.32+ 起 Radio 的 groupValue/onChanged 已弃用，改由 RadioGroup 统一管。
          RadioGroup<int>(
            groupValue: _pending,
            onChanged: (v) => setState(() => _pending = v ?? _pending),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < widget.options.length; i++)
                  // 整行都能点，不用非得戳那个小圆点。
                  InkWell(
                    onTap: () => setState(() => _pending = i),
                    borderRadius: tokens.shapes.small,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Radio<int>(value: i),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.options[i],
                              style: tokens.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SmallSecondaryButton(text: strings.cancel, onPressed: widget.onDismiss),
              const SizedBox(width: 8),
              SmallSecondaryButton(
                text: strings.confirm,
                // 只调 onSelect：关闭弹窗是它的责任。
                // 早先这里还跟着调了一次 onDismiss，而 `show()` 的两个回调
                // 各自都 pop 了一次 —— 点确认会连弹两层，把底下的页面也退掉。
                onPressed: () => widget.onSelect(_pending),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 删除确认弹窗 —— 垃圾桶图标 + errorContainer 底 + 「删除」确认键。
class DeleteConfirmDialog extends StatelessWidget {
  const DeleteConfirmDialog({
    super.key,
    required this.onConfirm,
    required this.onDismiss,
    this.title,
    this.message,
  });

  final VoidCallback onConfirm;
  final VoidCallback onDismiss;
  final String? title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    final strings = KitStringsScope.of(context);
    return ConfirmDialog(
      title: title ?? strings.deleteConfirmTitle,
      message: message ?? strings.deleteConfirmMessage,
      confirmText: strings.delete,
      dismissText: strings.cancel,
      onConfirm: onConfirm,
      onDismiss: onDismiss,
      icon: Icons.delete,
      iconContentDescription: strings.delete,
      iconBackgroundColor: tokens.colorScheme.errorContainer,
    );
  }

  /// 弹窗并等结果：确认删除返回 true。
  static Future<bool> show(
    BuildContext context, {
    String? title,
    String? message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => DeleteConfirmDialog(
        title: title,
        message: message,
        onConfirm: () => Navigator.of(dialogContext).pop(true),
        onDismiss: () => Navigator.of(dialogContext).pop(false),
      ),
    );
    return result ?? false;
  }
}

/// 文本输入弹窗。
class InputDialog extends StatefulWidget {
  const InputDialog({
    super.key,
    required this.title,
    required this.onConfirm,
    required this.onDismiss,
    this.hint = '',
    this.initialValue = '',
    this.confirmText,
    this.dismissText,
    this.singleLine = true,
    this.isPassword = false,
  });

  final String title;
  final ValueChanged<String> onConfirm;
  final VoidCallback onDismiss;
  final String hint;
  final String initialValue;
  final String? confirmText;
  final String? dismissText;
  final bool singleLine;
  final bool isPassword;

  @override
  State<InputDialog> createState() => _InputDialogState();

  /// 弹窗并返回输入内容；取消返回 null。
  static Future<String?> show(
    BuildContext context, {
    required String title,
    String hint = '',
    String initialValue = '',
    String? confirmText,
    String? dismissText,
    bool singleLine = true,
    bool isPassword = false,
  }) {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => InputDialog(
        title: title,
        hint: hint,
        initialValue: initialValue,
        confirmText: confirmText,
        dismissText: dismissText,
        singleLine: singleLine,
        isPassword: isPassword,
        onConfirm: (text) => Navigator.of(dialogContext).pop(text),
        onDismiss: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }
}

class _InputDialogState extends State<InputDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);
  late final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    widget.onConfirm(_controller.text);
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    final strings = KitStringsScope.of(context);

    return kitDialogShell(
      context,
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: themedCrossAxisAlignment(context, CrossAxisAlignment.center),
        children: [
          Text(
            widget.title,
            textAlign: themedTextAlign(context, TextAlign.center),
            style: tokens.textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          // 这里刻意用原生 TextField：输入弹窗是「一次性取值」，
          // 不需要 SimpleTextField 的受控同步（那个是给表单用的）。
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            obscureText: widget.isPassword,
            minLines: widget.singleLine ? 1 : 3,
            maxLines: widget.singleLine ? 1 : null,
            keyboardType: widget.isPassword
                ? TextInputType.visiblePassword
                : (widget.singleLine ? TextInputType.text : TextInputType.multiline),
            textCapitalization: widget.singleLine
                ? TextCapitalization.sentences
                : TextCapitalization.none,
            textInputAction: widget.singleLine
                ? TextInputAction.done
                : TextInputAction.newline,
            onSubmitted: widget.singleLine ? (_) => _submit() : null,
            style: tokens.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: widget.hint.isNotEmpty ? widget.hint : null,
              border: OutlineInputBorder(
                borderRadius: tokens.shapes.extraSmall,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SmallSecondaryButton(
                text: widget.dismissText ?? strings.cancel,
                onPressed: widget.onDismiss,
              ),
              const SizedBox(width: 8),
              SmallSecondaryButton(
                text: widget.confirmText ?? strings.confirm,
                onPressed: _submit,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 加载弹窗 —— 转圈 + 一句说明。
///
/// [cancellable] = false 时点外部/返回键都关不掉（防重复提交时用）。
/// 关掉它请 `Navigator.pop`，别指望用户点外面。
class LoadingDialog extends StatelessWidget {
  const LoadingDialog({
    super.key,
    this.message = '',
    this.cancellable = true,
  });

  final String message;
  final bool cancellable;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    return PopScope(
      canPop: cancellable,
      child: Dialog(
        backgroundColor: tokens.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: tokens.shapes.extraLarge),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              if (message.isNotEmpty) ...[
                const SizedBox(width: 16),
                Flexible(
                  child: Text(
                    message,
                    style: tokens.textTheme.bodyMedium
                        ?.copyWith(color: tokens.colorScheme.onSurface),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 显示加载弹窗。返回的函数用来关掉它（务必在 finally 里调）。
  static Future<void> Function() show(
    BuildContext context, {
    String message = '',
    bool cancellable = true,
  }) {
    var closed = false;
    showDialog<void>(
      context: context,
      barrierDismissible: cancellable,
      builder: (_) => LoadingDialog(message: message, cancellable: cancellable),
    );
    return () async {
      if (closed) return;
      closed = true;
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    };
  }
}
