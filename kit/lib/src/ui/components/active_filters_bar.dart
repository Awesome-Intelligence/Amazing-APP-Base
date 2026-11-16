import 'package:material_ui/material_ui.dart';

import '../../i18n/kit_strings.dart';
import '../../theme/kit_theme.dart';

/// 筛选类型。对应 KMP 的 `FilterType` 枚举。
enum FilterType {
  /// 重要性（今天 / 本周 …）。
  importance,

  /// 标签（带颜色）。
  tag,

  /// 条目类型。
  type,
}

/// 一条活跃筛选条件。对应 KMP 的 `ActiveFilter`。
class ActiveFilter {
  /// 唯一标识 —— 同一个 label 可能出现两次（不同来源），所以不能拿 label 当 key。
  final String id;

  final FilterType type;

  /// 显示文本（已本地化，调用方给）。
  final String label;

  /// 标签色的色点；其余类型忽略。
  final Color? color;

  const ActiveFilter({
    required this.id,
    required this.type,
    required this.label,
    this.color,
  });

  @override
  String toString() => 'ActiveFilter($id, $type, $label)';
}

/// 活跃筛选条件展示栏。对应 KMP 的 `ui/components/ActiveFiltersBar.kt`。
///
/// 显示当前生效的筛选条件（重要性 / 标签 / 类型），每条可单点移除；
/// 右侧「清除全部」一键清空。列表为空时**整条不占位置** ——
/// 没筛选时留一条空白，用户会以为界面坏了。
///
/// ```dart
/// ActiveFiltersBar(
///   filters: [
///     ActiveFilter(id: 'imp-today', type: FilterType.importance, label: '今天'),
///     ActiveFilter(id: 'tag-work', type: FilterType.tag, label: '工作', color: Colors.blue),
///   ],
///   onRemoveFilter: (f) => setState(() => filters.remove(f)),
///   onClearAll: () => setState(filters.clear),
/// )
/// ```
class ActiveFiltersBar extends StatelessWidget {
  const ActiveFiltersBar({
    super.key,
    required this.filters,
    required this.onRemoveFilter,
    required this.onClearAll,
  });

  final List<ActiveFilter> filters;
  final ValueChanged<ActiveFilter> onRemoveFilter;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    // 空列表什么都不渲染：占位会让列表整体下移一块空白
    if (filters.isEmpty) return const SizedBox.shrink();

    final tokens = KitTheme.of(context);
    final strings = KitStringsScope.of(context);

    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (final filter in filters)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterChip(
                        filter: filter,
                        onRemove: () => onRemoveFilter(filter),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: onClearAll,
              style: TextButton.styleFrom(
                foregroundColor: tokens.colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: tokens.textTheme.labelMedium,
              ),
              child: Text(strings.clearAll),
            ),
          ),
        ],
      ),
    );
  }
}

/// 单个条件芯片：带色点（标签类型）+ 尾部关闭按钮。
///
/// 用 Material 的 [InputChip] 而不是自己拼容器 —— onDeleted 自带正确的
/// 触控目标与无障碍语义（"移除 X" 会被读屏念出来）。
class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.filter, required this.onRemove});

  final ActiveFilter filter;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    final strings = KitStringsScope.of(context);
    final scheme = tokens.colorScheme;
    final dotColor = filter.color ??
        (filter.type == FilterType.tag ? scheme.tertiary : null);

    return InputChip(
      selected: true,
      onDeleted: onRemove,
      // 选中态不画勾（Compose 版靠底色表达选中）
      showCheckmark: false,
      backgroundColor: scheme.secondaryContainer,
      selectedColor: scheme.secondaryContainer,
      labelStyle: tokens.textTheme.labelMedium?.copyWith(
        color: scheme.onSecondaryContainer,
      ),
      deleteIcon: Icon(Icons.close, size: 16, color: scheme.onSecondaryContainer),
      deleteButtonTooltipMessage: strings.removeFilter(filter.label),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(filter.label),
        ],
      ),
    );
  }
}
