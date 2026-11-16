import 'package:material_ui/material_ui.dart';

import '../../theme/kit_theme.dart';

/// 标签文字 —— 全局唯一的标签渲染形式，**不用胶囊底色**。
///
/// 为什么不用 chip 底色：一个列表里三个标签、每个都套一层灰底，整行就被色块切碎了；
/// 只用 `# 标签` 的彩色文字，标签是「注释」而不是「按钮」。
///
/// 三种用法：
/// - 展示：`TagText(text: 'work', color: c)`
/// - 可点：`TagText(text: 'work', color: c, onTap: ...)`，自动补 32 最小触控高度
/// - 已选中：`isSelected: true` —— 加描边与尾部勾选图标
///
/// [color] **始终是文字颜色**。未选中要不要用灰色由调用方决定
/// （筛选/选择场景传 `onSurfaceVariant`）。
class TagText extends StatelessWidget {
  const TagText({
    super.key,
    required this.text,
    required this.color,
    this.isSelected = false,
    this.onTap,
    this.selectedIcon = Icons.check,
    this.showSelectedIcon = true,
  });

  final String text;
  final Color color;
  final bool isSelected;
  final VoidCallback? onTap;

  /// 选中态尾部图标（picker 里常换成别的）。
  final IconData selectedIcon;

  /// 选中态是否显示尾部图标 —— 标签选择器不需要（勾选显多余），筛选用得上。
  final bool showSelectedIcon;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 「#」前缀与正文包在一起，数字/字母的视觉中心才对得上。
        Text(
          '# $text',
          style: tokens.textTheme.labelMedium?.copyWith(
            fontWeight: themedFontWeight(context, FontWeight.w500),
            color: color,
          ),
        ),
        if (isSelected && showSelectedIcon) ...[
          const SizedBox(width: 4),
          Icon(selectedIcon, size: 14, color: color),
        ],
      ],
    );

    if (isSelected) {
      // 选中态用小圆角描边。大圆角空心描边读起来还是「胶囊」，小圆角才像勾选框。
      content = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(
            color: color,
            width: themedStrokeWidth(context, 1.5),
          ),
          borderRadius: themedCorner(context, 6),
        ),
        child: content,
      );
    }

    if (onTap == null) return content;

    // 32 而不是 M3 的 48：FlowRow 里 48 会把行距撑得很稀。
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 32),
        child: Align(alignment: Alignment.centerLeft, child: content),
      ),
    );
  }
}
