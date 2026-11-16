import 'package:material_ui/material_ui.dart';

import '../../i18n/kit_strings.dart';
import '../../theme/kit_theme.dart';

/// 一个菜单项。
///
/// [SimpleMenuItem.divider] 渲染成分割线（其余字段被忽略，也不会触发回调）；
/// [subItems] 非空时渲染成二级菜单入口。
@immutable
class SimpleMenuItem {
  const SimpleMenuItem({
    this.title = '',
    this.icon,
    this.trailingIcon,
    this.isDivider = false,
    this.subItems = const <SimpleMenuItem>[],
  });

  /// 分割线项的便捷构造。
  const SimpleMenuItem.divider()
      : title = '',
        icon = null,
        trailingIcon = null,
        isDivider = true,
        subItems = const <SimpleMenuItem>[];

  final String title;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool isDivider;
  final List<SimpleMenuItem> subItems;

  bool get hasSubMenu => subItems.isNotEmpty;
}

/// 右上角「更多」菜单。
///
/// 对应 KMP 的 `SimpleMenuButton`。那边用 DropdownMenu 手工平面展开子菜单，
/// 因为 Compose 的 DropdownMenu 不支持嵌套；这边用 M3 的 [MenuAnchor]，
/// 子菜单是真的嵌套浮层 —— 规范做法，也不用自己维护「哪个子菜单展开着」。
///
/// 回调保留 KMP 的形状：`(父项索引, 子项索引)`。顶层项子索引为 -1；
/// 父项索引都是在传入 [items] 里的位置（**含分割线**）。
class SimpleMenuButton extends StatelessWidget {
  const SimpleMenuButton({
    super.key,
    required this.items,
    required this.onItemSelected,
    this.contentDescription,
    this.icon = Icons.more_vert,
  });

  final List<SimpleMenuItem> items;
  final void Function(int parentIndex, int subIndex) onItemSelected;
  final String? contentDescription;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final s = KitStringsScope.of(context);
    final label = contentDescription ?? s.moreOptions;

    return MenuAnchor(
      menuChildren: [
        for (var i = 0; i < items.length; i++)
          if (items[i].isDivider)
            const Divider(height: 1)
          else
            _MenuRow(
              item: items[i],
              parentIndex: i,
              subIndex: -1,
              onSelected: onItemSelected,
            ),
      ],
      builder: (context, controller, _) => IconButton(
        icon: Icon(icon),
        tooltip: label,
        onPressed: () => controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

/// 菜单里的一行：普通项 → [MenuItemButton]，有子项 → [SubmenuButton]。
///
/// 子菜单里的分割线直接跳过 —— [SubmenuButton] 的 menuChildren 只收可点项。
class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.item,
    required this.parentIndex,
    required this.subIndex,
    required this.onSelected,
  });

  final SimpleMenuItem item;
  final int parentIndex;
  final int subIndex;
  final void Function(int parentIndex, int subIndex) onSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    final leading = item.icon == null ? null : Icon(item.icon, size: 20);
    final trailing = item.trailingIcon == null ? null : Icon(item.trailingIcon, size: 20);
    final text = Text(item.title, style: tokens.textTheme.bodyMedium);

    if (item.hasSubMenu) {
      return SubmenuButton(
        leadingIcon: leading,
        menuChildren: [
          for (var j = 0; j < item.subItems.length; j++)
            if (!item.subItems[j].isDivider)
              _MenuRow(
                item: item.subItems[j],
                parentIndex: parentIndex,
                subIndex: j,
                onSelected: onSelected,
              ),
        ],
        child: text,
      );
    }

    return MenuItemButton(
      leadingIcon: leading,
      trailingIcon: trailing,
      onPressed: () => onSelected(parentIndex, subIndex),
      child: text,
    );
  }
}

/// 「编辑 / 删除」这一对最常用，单独给个壳。
class ActionMenuRow extends StatelessWidget {
  const ActionMenuRow({
    super.key,
    required this.onEdit,
    required this.onDelete,
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final s = KitStringsScope.of(context);
    return SimpleMenuButton(
      items: [
        SimpleMenuItem(title: s.edit, icon: Icons.edit_outlined),
        SimpleMenuItem(title: s.delete, icon: Icons.delete_outline),
      ],
      onItemSelected: (parentIndex, _) => switch (parentIndex) {
        0 => onEdit(),
        1 => onDelete(),
        _ => null,
      },
    );
  }
}
