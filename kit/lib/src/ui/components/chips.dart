import 'package:material_ui/material_ui.dart';

import '../../i18n/kit_strings.dart';
import '../../theme/kit_theme.dart';

/// 筛选 Chip —— M3 FilterChip 封装。圆角走主题的 medium 桶，内边距水平 12 垂直 4。
///
/// 命名带 `Kit` 前缀：Flutter 的 material 里已经有 `FilterChip`，同名会和
/// `import 'package:material_ui/material_ui.dart'` 撞车（调用方两个都得 import）。
///
/// 不写死高度：M3 Chip 默认 32 视觉高 + 自动扩展到 48 触控目标，
/// 加 `SizedBox(height:)` 会把触控扩展压掉、缩小可点区域。
class KitFilterChip extends StatelessWidget {
  const KitFilterChip({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
    this.leadingDotColor,
    this.leadingIcon,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  /// 前置色点（优先级 / 标签色）。
  final Color? leadingDotColor;

  /// 前置图标（和色点互斥，同时传会两个都显示）。
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    final scheme = tokens.colorScheme;

    return FilterChip(
      selected: isSelected,
      onSelected: (_) => onTap(),
      // FilterChip 选中时不画勾，靠底色变化表达。
      showCheckmark: false,
      backgroundColor: scheme.surface,
      selectedColor: scheme.primary,
      // 不写死 labelStyle.color：选中态要整块反色。
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingDotColor != null) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: leadingDotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
          ],
          if (leadingIcon != null) ...[
            Icon(
              leadingIcon,
              size: 16,
              color: isSelected ? scheme.onPrimary : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
          ],
          // 不用 Flexible：chip 放在横向滚动里时宽度约束是无界的，Flexible 会直接抛
          // 「non-zero flex but incoming width constraints are unbounded」。
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tokens.textTheme.labelSmall?.copyWith(
              color: isSelected ? scheme.onPrimary : scheme.onSurfaceVariant,
              fontWeight: themedFontWeight(
                context,
                isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
      side: BorderSide(
        color: isSelected ? scheme.primary : Colors.transparent,
        width: isSelected ? themedStrokeWidth(context, 2) : 0,
      ),
      shape: RoundedRectangleBorder(borderRadius: tokens.shapes.medium),
    );
  }
}

/// 添加标签 Chip —— M3 AssistChip 形态（Flutter 里对应 `ActionChip`）。
/// 高 24、圆角 6、surfaceVariant 底，一个「+」。
class AddTagChip extends StatelessWidget {
  const AddTagChip({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    return SizedBox(
      height: 24,
      child: ActionChip(
        onPressed: onTap,
        label: Text('+', style: tokens.textTheme.labelSmall),
        backgroundColor: tokens.extras.surfaceVariant,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: themedCorner(context, 6),
        ),
        // 不让 chip 自己撑到 48：这里刻意是「贴着文字」的小 chip。
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        labelPadding: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
    );
  }
}

/// 答题 Chip —— 问题卡里的可点选项。
///
/// 描边 chip：`outlineVariant` 边框 + `surfaceContainerLowest` 底，比卡片本身亮一层。
/// 没有选中态 —— 点一下即生效。
class AnswerChip extends StatelessWidget {
  const AnswerChip({super.key, required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    return ActionChip(
      onPressed: onTap,
      label: Text(text, style: tokens.textTheme.labelLarge),
      backgroundColor: tokens.colorScheme.surfaceContainerLowest,
      labelStyle: TextStyle(color: tokens.colorScheme.onSurface),
      side: BorderSide(color: tokens.colorScheme.outlineVariant, width: 1),
      shape: RoundedRectangleBorder(borderRadius: tokens.shapes.medium),
    );
  }
}

/// 筛选 Chip 横排（字符串版，按下标选中）。
///
/// 规格：水平内边距 16、chip 间距 8，可横向滚动。
/// 新代码优先用泛型版 [KitFilterChipRow]（和下拉选择器 API 对齐）；
/// 这个版本按下标回传，给还在按下标的老调用点用。
class KitFilterChipRowIndexed extends StatelessWidget {
  const KitFilterChipRowIndexed({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onSelect,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              KitFilterChip(
                title: options[i],
                isSelected: selectedIndex == i,
                onTap: () => onSelect(i),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 筛选 Chip 横排（泛型版）。
///
/// 与下拉选择器 API 对齐：`selectedOption` / `onOptionSelected` / `optionLabel`。
/// [leadingDotColors] 参与表达式 —— 每项一个色点（优先级色）。
class KitFilterChipRow<T> extends StatelessWidget {
  const KitFilterChipRow({
    super.key,
    required this.options,
    required this.selectedOption,
    required this.onOptionSelected,
    required this.optionLabel,
    this.leadingDotColors,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final List<T> options;
  final T selectedOption;
  final ValueChanged<T> onOptionSelected;
  final String Function(T) optionLabel;

  /// 按位置取色点；长度不足的项不画点。
  final List<Color>? leadingDotColors;

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              KitFilterChip(
                title: optionLabel(options[i]),
                isSelected: options[i] == selectedOption,
                onTap: () => onOptionSelected(options[i]),
                leadingDotColor: (leadingDotColors != null &&
                        i < leadingDotColors!.length)
                    ? leadingDotColors![i]
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 可选中的标签 —— M3 FilterChip，固定 32 高。
///
/// 和 [KitFilterChip] 的区别：这个用在「多选标签」场景，选中色可由调用方指定
/// （标签色做底），文字颜色按底色亮度自动取黑/白。
class SelectableTag extends StatelessWidget {
  const SelectableTag({
    super.key,
    required this.text,
    required this.isSelected,
    required this.onTap,
    this.selectedColor,
    this.unselectedColor,
  });

  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  /// 选中时的底色，默认 primary。
  final Color? selectedColor;

  /// 未选中时的底色，默认 surfaceVariant。
  final Color? unselectedColor;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    final scheme = tokens.colorScheme;
    final sel = selectedColor ?? scheme.primary;
    final unsel = unselectedColor ?? tokens.extras.surfaceVariant;

    return SizedBox(
      height: 32,
      child: FilterChip(
        selected: isSelected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        label: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: tokens.textTheme.labelMedium?.copyWith(
            color: isSelected
                ? (sel.computeLuminance() > 0.5 ? Colors.black : Colors.white)
                : scheme.onSurfaceVariant,
          ),
        ),
        backgroundColor: unsel,
        selectedColor: sel,
        side: BorderSide(
          color: isSelected ? Colors.transparent : tokens.extras.surfaceVariant,
        ),
        shape: RoundedRectangleBorder(borderRadius: tokens.shapes.medium),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

/// 静态徽章（不可点）。圆角走 shapes.small，padding 8/4，labelMedium，
/// primaryContainer 底。
class AppBadge extends StatelessWidget {
  const AppBadge({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tokens.colorScheme.primaryContainer,
        borderRadius: tokens.shapes.small,
      ),
      child: Text(
        text,
        style: tokens.textTheme.labelMedium?.copyWith(
          color: tokens.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

/// 复选框 —— M3 Checkbox 封装。
///
/// 命名带 `Kit` 前缀，理由同 [KitFilterChip]（material 里有 `Checkbox`）。
/// 无障碍：读屏念「已选中 / 未选中」，而不是只说「复选框」。
class KitCheckbox extends StatelessWidget {
  const KitCheckbox({
    super.key,
    required this.isChecked,
    required this.onCheckedChange,
    this.contentDescription,
    this.checkedColor,
  });

  final bool isChecked;
  final ValueChanged<bool> onCheckedChange;

  /// 覆盖无障碍描述；不传按勾选状态取「已选中 / 未选中」。
  final String? contentDescription;

  /// 选中色，默认 primary。
  final Color? checkedColor;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    final scheme = tokens.colorScheme;
    final strings = KitStringsScope.of(context);

    return Semantics(
      label: contentDescription ??
          (isChecked ? strings.selectedState : strings.unselectedState),
      child: Checkbox(
        value: isChecked,
        onChanged: (v) => onCheckedChange(v ?? false),
        activeColor: checkedColor ?? scheme.primary,
        checkColor: scheme.onPrimary,
        side: BorderSide(color: scheme.onSurfaceVariant, width: 2),
      ),
    );
  }
}

/// 色板圆点 —— 单个可选颜色。
///
/// 视觉 40 圆、点击区 48（M3 最小触控目标）；选中态 2px onSurface 描边 + 勾。
class ColorDot extends StatelessWidget {
  const ColorDot({
    super.key,
    required this.color,
    required this.isSelected,
    required this.colorName,
    required this.onTap,
  });

  final Color color;
  final bool isSelected;

  /// 无障碍念出的颜色名（也是点击标签）。
  final String colorName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = KitTheme.of(context).colorScheme;
    // 深色模式的色板偏浅，按亮度选黑/白勾保证对比。
    final checkColor = color.computeLuminance() > 0.5 ? Colors.black : Colors.white;

    return Semantics(
      button: true,
      label: colorName,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(color: scheme.onSurface, width: 2)
                    : null,
              ),
              child: isSelected
                  // 装饰性勾：选中态已由描边 + 无障碍 selected 传达。
                  ? Icon(Icons.check, size: 16, color: checkColor)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// 色板选择行 —— 自动换行排列颜色圆点。
///
/// 传 [tagColorNames] 保证色名与 `tagColor()` 的映射一致，别自己造名字。
class ColorDotRow extends StatelessWidget {
  const ColorDotRow({
    super.key,
    required this.colorNames,
    required this.selectedColorName,
    required this.onColorSelected,
  });

  final List<String> colorNames;
  final String selectedColorName;
  final ValueChanged<String> onColorSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      // 视觉 40 + 点击区 48：4px 间距下视觉间距正好 12。
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final name in colorNames)
          ColorDot(
            color: tagColor(context, name),
            isSelected: name == selectedColorName,
            colorName: name,
            onTap: () => onColorSelected(name),
          ),
      ],
    );
  }
}

/// 色名清单见 `color_schemes.dart` 的 `tagColorNames`（生成物，与 tagColor 映射同源）。
