import 'package:material_ui/material_ui.dart';

import '../../theme/kit_theme.dart';

/// 页头 —— 完全对齐 M3 TopAppBar 规范。
///
/// 布局：`[leading1][leading2] [标题] [action1][action2][menu]`，
/// 64 高、标题绝对居中、没有多余空行。
///
/// 状态栏内边距在组件内部处理（`SafeArea` 只吃顶部）：内容往下避开状态栏，
/// 底色仍然铺到屏幕最顶端 —— app 开了 edge-to-edge 也不会被状态栏盖住。
class Header extends StatelessWidget {
  const Header({
    super.key,
    required this.title,
    this.leading1,
    this.leading2,
    this.titleIcon,
    this.action1,
    this.action2,
    this.menu,
    this.onTitleClick,
    this.maxChars,
  });

  final String title;
  final Widget? leading1;
  final Widget? leading2;

  /// 标题前面的小图标（如清单的 emoji / 分类图标）。
  final Widget? titleIcon;
  final Widget? action1;
  final Widget? action2;

  /// 最右侧的菜单按钮（通常放 `PopupMenuButton`）。
  final Widget? menu;

  /// 给了就整块标题可点（详情页点标题重命名）。
  final VoidCallback? onTitleClick;

  /// 按「人眼看到的字数」截断标题；`null` = 不截断。
  ///
  /// 按 Unicode 码点算，emoji 算 1 个字且不会从 emoji 中间砍断。
  /// 组合 emoji（如 👨‍👩‍👧、国旗）仍算多个字 —— 要完全按视觉字数得上 BreakIterator，
  /// 标题场景用不上。
  final int? maxChars;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);

    return Container(
      // 底色先铺满（含状态栏区域），再由 SafeArea 把内容顶下来。
      color: tokens.colorScheme.surface,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 64,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (leading1 != null) leading1!,
                      if (leading2 != null) leading2!,
                    ],
                  ),
                ),
              ),
              // 标题行用 maxLines/ellipsis 自己收字，所以这里不用 Expanded ——
              // 左右两组按钮压在 Stack 上层，标题超宽会先被截断再被盖住。
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 96),
                child: InkWell(
                  onTap: onTitleClick,
                  borderRadius: tokens.shapes.small,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (titleIcon != null) ...[
                        titleIcon!,
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          _truncate(title, maxChars),
                          style: tokens.textTheme.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (action1 != null) action1!,
                      if (action2 != null) action2!,
                      if (menu != null) menu!,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _truncate(String title, int? maxChars) {
  if (maxChars == null || maxChars <= 0) return title;
  final runes = title.runes.toList();
  if (runes.length <= maxChars) return title;
  return '${String.fromCharCodes(runes.take(maxChars))}…';
}
