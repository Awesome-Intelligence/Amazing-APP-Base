import 'package:material_ui/material_ui.dart';

import '../../settings/theme_enums.dart' show ThemeStyle;
import '../../theme/kit_theme.dart';
import '../../theme/palettes.dart' show Swiss;

/// 项目统一输入框圆角 —— M3 规范 4（macOS 走 6，见 [themedControlRadius]）。
BorderRadius textFieldCorner(BuildContext context) =>
    themedControlRadius(context, BorderRadius.circular(themedRadius(context, 4)));

/// 输入框的边框/聚焦色。
///
/// 三套规范三种答案，所以不能交给 M3 默认值：
/// - macOS 毛玻璃：聚焦边框是白 25%，**不是主色蓝**（蓝框在毛玻璃上像系统控件串味）；
/// - 瑞士：聚焦边框是信号红（规范原文 `focus:border-red`）；
/// - 其余：主色。
InputDecoration themedInputDecoration(
  BuildContext context, {
  String? label,
  String? hint,
  String? helper,
  String? error,
  Widget? suffix,
  Widget? prefix,
}) {
  final tokens = KitTheme.of(context);
  final scheme = tokens.colorScheme;
  final focused = switch (tokens.themeStyle) {
    ThemeStyle.macOS => scheme.onSurface.withValues(alpha: 0.25),
    ThemeStyle.swiss => Swiss.redBlock,
    _ => scheme.primary,
  };
  final corner = textFieldCorner(context);

  return InputDecoration(
    labelText: (label != null && label.isNotEmpty) ? label : null,
    hintText: (hint != null && hint.isNotEmpty) ? hint : null,
    helperText: error == null ? helper : null,
    errorText: error,
    suffixIcon: suffix,
    prefixIcon: prefix,
    border: OutlineInputBorder(borderRadius: corner),
    enabledBorder: OutlineInputBorder(
      borderRadius: corner,
      borderSide: BorderSide(color: scheme.outline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: corner,
      borderSide: BorderSide(color: focused, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: corner,
      borderSide: BorderSide(color: scheme.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: corner,
      borderSide: BorderSide(color: scheme.error, width: 2),
    ),
  );
}

/// 简单文本输入框 —— M3 OutlinedTextField 等价物。
///
/// 受控组件：`value` 是唯一真相，外部重置 `value` 时输入框会跟着变。
/// （Flutter 的 `TextField` 自己管光标，所以内部同步 controller —— 不这样做的话，
/// 「清空输入框」这类操作只会改外部 state，屏幕上文字不动。）
///
/// [singleLine] = false 时起手 3 行（不是 1 行），否则多行框会先挤成一条再跳高。
/// [helperText] 在有 [isError] 时按错误色显示 —— 和 Compose 的 supportingText 一致。
class SimpleTextField extends StatefulWidget {
  const SimpleTextField({
    super.key,
    required this.value,
    required this.onValueChange,
    this.label = '',
    this.hint = '',
    this.singleLine = true,
    this.enabled = true,
    this.isError = false,
    this.helperText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.contentDescription,
    this.focusNode,
  });

  final String value;
  final ValueChanged<String> onValueChange;
  final String label;
  final String hint;
  final bool singleLine;
  final bool enabled;
  final bool isError;

  /// 辅助说明；[isError] 时改按错误色显示。
  final String? helperText;

  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  /// 无障碍描述（表单里 label 已足够时可留空）。
  final String? contentDescription;

  final FocusNode? focusNode;

  @override
  State<SimpleTextField> createState() => _SimpleTextFieldState();
}

class _SimpleTextFieldState extends State<SimpleTextField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(SimpleTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 外部改了 value 才回灌；输入过程中的 value 变化与 controller 已经一致，不会动光标。
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    final single = widget.singleLine;

    Widget field = TextField(
      controller: _controller,
      focusNode: widget.focusNode,
      onChanged: widget.onValueChange,
      enabled: widget.enabled,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType ??
          (single ? TextInputType.text : TextInputType.multiline),
      textInputAction: widget.textInputAction ??
          (single ? TextInputAction.done : TextInputAction.newline),
      onSubmitted: widget.onSubmitted,
      minLines: single ? 1 : 3,
      maxLines: single ? 1 : null,
      style: tokens.textTheme.bodyLarge,
      decoration: themedInputDecoration(
        context,
        label: widget.label,
        hint: widget.hint,
        helper: widget.helperText,
        error: widget.isError ? (widget.helperText ?? '') : null,
      ),
    );

    if (widget.contentDescription != null) {
      field = Semantics(label: widget.contentDescription, child: field);
    }
    return field;
  }
}

/// 聊天输入条 —— 56 高填充胶囊（surfaceContainerHigh），文字和语音键都在里面。
///
/// 和搜索框同一套视觉语言；**表单里的方框输入框别用它**。
/// [onSubmit] 给了就在键盘上显示「发送」，不给就是普通换行输入。
class ComposerField extends StatefulWidget {
  const ComposerField({
    super.key,
    required this.value,
    required this.onValueChange,
    required this.placeholder,
    required this.onMicTap,
    required this.micContentDescription,
    this.onSubmit,
    this.focusNode,
    this.controller,
  });

  final String value;
  final ValueChanged<String> onValueChange;
  final String placeholder;
  final VoidCallback onMicTap;

  /// 语音键的无障碍描述（必需，纯图标按钮没有文字标签）。
  final String micContentDescription;

  final VoidCallback? onSubmit;

  /// 外部托管输入内容时传它（发送后要 `clear()` 的场景）。
  /// 不传就用内部 controller，靠 [value] 回灌。
  final TextEditingController? controller;

  final FocusNode? focusNode;

  @override
  State<ComposerField> createState() => _ComposerFieldState();
}

class _ComposerFieldState extends State<ComposerField> {
  late final TextEditingController _own =
      TextEditingController(text: widget.value);

  TextEditingController get _controller => widget.controller ?? _own;

  @override
  void didUpdateWidget(ComposerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 外部托管 controller 时由调用方负责清空，这里别抢。
    if (widget.controller == null && widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _own.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    final scheme = tokens.colorScheme;
    final hasSubmit = widget.onSubmit != null;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: tokens.shapes.extraLarge,
      ),
      padding: const EdgeInsets.fromLTRB(20, 4, 4, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: TextField(
                controller: _controller,
                focusNode: widget.focusNode,
                onChanged: widget.onValueChange,
                minLines: 1,
                maxLines: 4,
                keyboardType: TextInputType.multiline,
                textInputAction:
                    hasSubmit ? TextInputAction.send : TextInputAction.newline,
                onSubmitted: hasSubmit ? (_) => widget.onSubmit!() : null,
                style: tokens.textTheme.bodyLarge?.copyWith(color: scheme.onSurface),
                cursorColor: scheme.primary,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintText: widget.placeholder,
                  hintStyle: tokens.textTheme.bodyLarge
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              onPressed: widget.onMicTap,
              tooltip: widget.micContentDescription,
              iconSize: 22,
              color: scheme.primary,
              icon: const Icon(Icons.mic_none),
            ),
          ),
        ],
      ),
    );
  }
}
