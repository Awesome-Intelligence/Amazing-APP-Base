import 'package:material_ui/material_ui.dart';

import '../../settings/theme_enums.dart' show ThemeStyle;
import '../../theme/kit_theme.dart';

/// 主按钮 —— M3 实心按钮。高度 48，圆角走主题的 medium 桶。
///
/// 对应 KMP 的 `PrimaryButton`。hover/press 只叠 state layer，不做位移 ——
/// 这是 M3 的规矩，也是 Swiss 规范「不位移、不缩放」的要求。
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.enabled = true,
    this.expand = false,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool enabled;

  /// 撑满父宽度（表单底部主操作常用）。
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    final button = SizedBox(
      height: 48,
      child: FilledButton(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: themedControlRadius(context, tokens.shapes.medium),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: tokens.textTheme.labelLarge,
          disabledForegroundColor: themedDisabledContentColor(context),
        ),
        child: Text(text),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// 次级按钮 —— M3 FilledTonal。高度 48。
///
/// Swiss 规范要求次级按钮是「白底黑字黑边」而不是色调色块 —— 只用黑白原色。
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.enabled = true,
    this.icon,
    this.expand = false,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool enabled;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    final swiss = tokens.themeStyle == ThemeStyle.swiss;
    final radius = themedControlRadius(context, tokens.shapes.medium);

    final button = SizedBox(
      height: 48,
      child: FilledButton.tonal(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: radius),
          backgroundColor: swiss ? tokens.extras.background : null,
          foregroundColor: swiss ? tokens.colorScheme.onSurface : null,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: tokens.textTheme.labelLarge,
          disabledForegroundColor: themedDisabledContentColor(context),
        ).copyWith(
          side: swiss
              ? WidgetStatePropertyAll(
                  BorderSide(color: tokens.colorScheme.onSurface, width: 1),
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            Text(text),
          ],
        ),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// 小号次级按钮 —— M3 Outlined 文字按钮，卡片内操作用。
///
/// 对应 KMP 的 `SmallSecondaryButton`（工具审批卡的三个动作就是它）。
class SmallSecondaryButton extends StatelessWidget {
  const SmallSecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.enabled = true,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: themedControlRadius(context, tokens.shapes.medium),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: tokens.textTheme.labelLarge,
        disabledForegroundColor: themedDisabledContentColor(context),
      ),
      child: Text(text),
    );
  }
}

/// 图标按钮 —— 40×40，无背景，图标 24，色 onSurfaceVariant。
class FilledIconButton extends StatelessWidget {
  const FilledIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.enabled = true,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  /// 语义标签（读屏用）。装饰性图标可留空。
  final String? tooltip;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        onPressed: enabled ? onPressed : null,
        tooltip: tooltip,
        iconSize: 24,
        padding: EdgeInsets.zero,
        color: tokens.colorScheme.onSurfaceVariant,
        icon: Icon(icon),
      ),
    );
  }
}

/// 文字按钮 —— M3 TextButton，表单里的次级操作（「更多字段」展开等）。
class TextActionButton extends StatelessWidget {
  const TextActionButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.enabled = true,
    this.icon,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool enabled;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    return TextButton(
      onPressed: enabled ? onPressed : null,
      style: TextButton.styleFrom(
        textStyle: tokens.textTheme.labelLarge,
        disabledForegroundColor: themedDisabledContentColor(context),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 6),
          ],
          Text(text),
        ],
      ),
    );
  }
}
