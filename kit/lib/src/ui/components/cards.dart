import 'package:material_ui/material_ui.dart';

import '../../settings/theme_enums.dart' show ThemeStyle;
import '../../theme/kit_theme.dart';
import '../../theme/theme_tokens.dart';

/// 卡片容器 —— M3 Card 的等价物（无点击 / 有点击两用）。
///
/// 规格：圆角走主题的 medium 桶、内边距 16、surfaceContainer 背景、0 elevation
/// （M3 用色阶分层不用阴影；Swiss / Notion / E-Ink / macOS 更是明确禁阴影）。
///
/// 对应 KMP 的 `AppCard`（它拆成了「无点击 / 有点击」两个重载，Dart 用可空 [onTap] 合并）。
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.border,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  /// 自定义描边；不传时按主题决定（macOS 会自动加 1px 发丝边）。
  final BorderSide? border;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    final side = border ??
        (tokens.themeStyle == ThemeStyle.macOS
            ? BorderSide(
                color: tokens.colorScheme.outlineVariant,
                width: themedStrokeWidth(context, 1),
              )
            : BorderSide.none);

    final content = Padding(padding: padding, child: child);
    final shape = RoundedRectangleBorder(
      borderRadius: tokens.shapes.medium,
      side: side,
    );

    return Material(
      color: _containerColor(context, tokens),
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : InkWell(onTap: onTap, borderRadius: tokens.shapes.medium, child: content),
    );
  }
}

/// 小卡片 —— 内边距 12，用于密集列表。
class SmallCard extends StatelessWidget {
  const SmallCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(12),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) =>
      AppCard(onTap: onTap, padding: padding, child: child);
}

/// 卡片标题：图标 + 文本。详情页各卡片顶部统一用它。
class CardTitle extends StatelessWidget {
  const CardTitle({
    super.key,
    required this.icon,
    required this.title,
    this.trailing,
  });

  final IconData icon;
  final String title;

  /// 尾部操作（按钮/徽标），可空。
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: tokens.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(title, style: tokens.textTheme.titleMedium)),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Swiss 的卡片是「白底 + 黑边」而不是灰块 —— 只用黑白原色。
Color _containerColor(BuildContext context, ThemeTokens tokens) {
  return tokens.themeStyle == ThemeStyle.swiss
      ? tokens.extras.background
      : tokens.colorScheme.surfaceContainer;
}
