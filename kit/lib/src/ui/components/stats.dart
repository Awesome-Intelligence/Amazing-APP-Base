import 'package:material_ui/material_ui.dart';

import '../../theme/kit_theme.dart';

/// 一条统计：图标 + 数值 + 标签。
@immutable
class StatItemData {
  const StatItemData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.iconContentDescription,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? iconContentDescription;
}

/// 单条统计（图标 + 上下两行：数值大、标签小）。
class StatItem extends StatelessWidget {
  const StatItem({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: tokens.textTheme.labelMedium),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: tokens.textTheme.labelSmall?.copyWith(
                    color: tokens.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 统计卡片：一行平分几条统计，底色 surfaceVariant、无阴影。
class StatsCard extends StatelessWidget {
  const StatsCard({super.key, required this.stats});

  final List<StatItemData> stats;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);

    return Material(
      color: tokens.extras.surfaceVariant,
      borderRadius: tokens.shapes.medium,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            for (var i = 0; i < stats.length; i++)
              Expanded(
                child: StatItem(
                  title: stats[i].title,
                  value: stats[i].value,
                  icon: stats[i].icon,
                  color: stats[i].color,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
