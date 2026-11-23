import 'package:material_ui/material_ui.dart';

import '../../theme/kit_theme.dart';

/// 底部导航项。
///
/// [alwaysFilled] 是「动作按钮」而不是目的地（比如「快速添加」）：图标常驻一块
/// 主色底，视觉上不随选中态变化。
@immutable
class BottomNavItem {
  const BottomNavItem({
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.badgeCount,
    this.alwaysFilled = false,
  });

  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final int? badgeCount;
  final bool alwaysFilled;
}

/// 底部导航栏。
///
/// 选中项的背景条是 primary @12%，未选中图标/文字走 onSurfaceVariant。
///

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  final List<BottomNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    final reduced = KitTheme.reducedMotionOf(context);
    // 框架自己也断言了这条，但报错信息只有一行 "destinations.length >= 2"，
    // 看不出是谁传错了。在这里先拦一道，把原因说清楚。
    assert(
      items.length >= 2,
      '底部导航至少要 2 个目的地；只有一个的话它不是导航，是个按钮',
    );

    final bar = NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: tokens.colorScheme.surface,
        indicatorColor: tokens.colorScheme.primary.withValues(alpha: 0.12),
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return tokens.textTheme.labelMedium?.copyWith(
            color: selected
                ? tokens.colorScheme.primary
                : tokens.colorScheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected
                ? tokens.colorScheme.primary
                : tokens.colorScheme.onSurfaceVariant,
          );
        }),
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onItemSelected,
        height: 80,
        destinations: [
          for (final item in items)
            NavigationDestination(
              icon: _icon(context, item, false, reduced),
              selectedIcon: _icon(context, item, true, reduced),
              // alwaysFilled 的项不要文字，但也不能传 null —— 那会让整列
              // 垂直居中、图标和别的项不在一条线上。给个空串占住行高。
              label: item.alwaysFilled ? '' : item.label,
              tooltip: item.alwaysFilled ? item.label : null,
            ),
        ],
      ),
    );

    return bar;
  }

  Widget _icon(BuildContext context, BottomNavItem item, bool selected, bool reduced) {
    final tokens = KitTheme.of(context);

    if (item.alwaysFilled) {
      // 常驻底色：主色圆角长条 + onPrimary 图标。
      return Container(
        width: 48,
        height: 32,
        decoration: BoxDecoration(
          color: tokens.colorScheme.primary,
          borderRadius: tokens.shapes.medium,
        ),
        child: Icon(item.icon, size: 24, color: tokens.colorScheme.onPrimary),
      );
    }

    final glyph = Icon(
      selected && item.selectedIcon != null ? item.selectedIcon : item.icon,
      size: 24,
    );

    Widget content = glyph;
    if (item.badgeCount != null && item.badgeCount! > 0) {
      content = Badge(
        label: Text(item.badgeCount! > 99 ? '99+' : '${item.badgeCount}'),
        child: content,
      );
    }

    if (reduced) return content;
    // 选中态换图标时淡入淡出 —— 直接换会「啪」一下。
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      child: KeyedSubtree(
        key: ValueKey(selected ? 'sel' : 'unsel'),
        child: content,
      ),
    );
  }
}
