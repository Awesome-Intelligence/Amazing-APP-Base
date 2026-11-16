import 'package:material_ui/material_ui.dart';

import '../../theme/kit_theme.dart';

/// M3 设置行图标：24 图标、无容器底色。
class AppSettingsIcon extends StatelessWidget {
  const AppSettingsIcon({
    super.key,
    required this.icon,
    required this.contentColor,
  });

  final IconData icon;
  final Color contentColor;

  @override
  Widget build(BuildContext context) => Icon(icon, size: 24, color: contentColor);
}

/// M3 列表行：最小高 56（≥48 触控目标），标题 bodyLarge + 副文本 bodyMedium。
///
/// 左侧 24 图标 + 16 间距，右侧可选箭头。
///
/// [contentPadding] 让同一个组件既能放进「无内边距」的分组卡片（设置页），
/// 也能放进自带 16 内边距的卡片（我的页）—— 不然涟漪铺不到卡片边。
class AppSettingsRow extends StatelessWidget {
  const AppSettingsRow({
    super.key,
    required this.title,
    required this.icon,
    required this.onClick,
    this.subtitle,
    this.titleColor,
    this.iconContentColor,
    this.showChevron = true,
    this.contentPadding =
        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  final String title;
  final IconData icon;
  final VoidCallback onClick;
  final String? subtitle;
  final Color? titleColor;
  final Color? iconContentColor;
  final bool showChevron;
  final EdgeInsetsGeometry contentPadding;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);

    return InkWell(
      onTap: onClick,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: contentPadding,
          child: Row(
            children: [
              AppSettingsIcon(
                icon: icon,
                contentColor: iconContentColor ?? tokens.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: tokens.textTheme.bodyLarge?.copyWith(
                        color: titleColor ?? tokens.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: tokens.textTheme.bodyMedium?.copyWith(
                          color: tokens.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (showChevron) ...[
                const SizedBox(width: 16),
                Icon(
                  Icons.chevron_right,
                  size: 24,
                  color: tokens.colorScheme.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 图标 + 文案的入口块（「我的」页的功能入口）：24 主色图标 + labelSmall 文案，整块可点。
class AppIconTile extends StatelessWidget {
  const AppIconTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onClick,
  });

  final IconData icon;
  final String label;
  final VoidCallback onClick;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);

    return InkWell(
      onTap: onClick,
      borderRadius: tokens.shapes.small,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: tokens.colorScheme.primary, semanticLabel: label),
            const SizedBox(height: 4),
            Text(
              label,
              style: tokens.textTheme.labelMedium?.copyWith(
                color: tokens.colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
