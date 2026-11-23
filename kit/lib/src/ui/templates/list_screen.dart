import 'package:material_ui/material_ui.dart';

import '../../i18n/kit_strings.dart';
import '../../theme/kit_theme.dart';
import '../../theme/theme_tokens.dart';
import '../components/adaptive_grid.dart';
import '../components/cards.dart';
import '../components/chips.dart';
import '../components/header.dart';
import '../components/motion.dart';
import '../components/search_bar.dart';

/// 列表页的三种呈现方式。
enum ListViewMode {
  /// 单列卡片（默认）。
  list,

  /// 网格卡片。列数自动按窗口宽度算，[KitListScreen.galleryColumns] 是下限。
  gallery,

  /// 日历。给了 [KitListScreen.calendarContent] 才生效，否则退回列表。
  calendar,
}

/// 列表页模板 —— 搜索 + 筛选 + 列表的标准套路。
///
/// **所有列表页都按这个结构实现**，别自己拼页头。
///
/// 用法（外面自带 `Scaffold`，模板自己会铺底色，中间不要再套容器）：
/// ```dart
/// Scaffold(
///   floatingActionButton: FloatingActionButton(onPressed: ...),
///   body: KitListScreen<Contact>(
///     title: '联系人',
///     items: vm.contacts,
///     itemContent: (ctx, c) => ContactCard(c),
///     emptyState: EmptyStates.contacts(),
///     noResultsState: EmptyStates.noSearchResults(vm.query),
///     ...
///   ),
/// )
/// ```
///
/// 搜索框和筛选标签是**互斥**的：M3 规范里搜索是「接管页头」的模态态，
/// 同一屏同时出现筛选行会让"现在筛的是什么"变得含糊。所以搜索激活时
/// 筛选行收起、页头标题清空、左侧换成返回箭头。
///
/// **筛选和搜索不在模板里做**：`items` 传进来就该是过滤/排序后的结果，
/// 模板只负责画。放模板里做的话，每个页面的筛选逻辑都得往模板塞开关。
class KitListScreen<T> extends StatelessWidget {
  const KitListScreen({
    super.key,
    required this.title,
    required this.onSearchClick,
    required this.isSearchActive,
    required this.onSearchActiveChange,
    required this.searchQuery,
    required this.onSearchQueryChange,
    required this.selectedFilterIndex,
    required this.onFilterSelected,
    required this.filterOptions,
    required this.items,
    required this.itemContent,
    required this.emptyState,
    required this.noResultsState,
    this.headerContentTop,
    this.headerContentBottom,
    this.footerContent,
    this.action2,
    this.menu,
    this.viewMode = ListViewMode.list,
    this.galleryColumns = 2,
    this.calendarContent,
    this.itemKey,
    this.listPadding = const EdgeInsets.all(16),
    this.itemSpacing = 8,
  });

  final String title;

  /// 点页头搜索图标。通常是 `() => setState(() => _searchActive = true)`。
  final VoidCallback onSearchClick;

  final bool isSearchActive;
  final ValueChanged<bool> onSearchActiveChange;

  final String searchQuery;
  final ValueChanged<String> onSearchQueryChange;

  final int selectedFilterIndex;
  final ValueChanged<int> onFilterSelected;
  final List<String> filterOptions;

  /// 已过滤 / 已排序的条目 —— 模板不再筛一遍。
  final List<T> items;

  /// 单条渲染。第二个参数是条目本身。
  ///
  /// **画廊模式要换一套内容**：网格格子通常只有 100–160px 宽，
  /// 「头像 + 两行字 + 徽标」那种列表卡在里面必然溢出。真实页面的做法是
  /// `viewMode == gallery ? 方块卡 : 列表卡`。
  final Widget Function(BuildContext context, T item) itemContent;

  /// 完全没有数据时的空态（通常是 `EmptyStates.contacts()`）。
  final Widget emptyState;

  /// 有搜索词或选了非首个筛选时的空态（通常是 `EmptyStates.noSearchResults(query)`）。
  final Widget noResultsState;

  /// 搜索/筛选区上方的额外内容（如日期导航条）。
  final Widget? headerContentTop;

  /// 筛选标签下方的额外内容（如第二行筛选）。
  final Widget? headerContentBottom;

  /// 列表下方的额外内容（如浮起的选择工具条）。
  final Widget? footerContent;

  /// 页头右侧第二个按钮位。
  final Widget? action2;

  /// 页头最右侧菜单位（通常放 `PopupMenuButton`）。
  final Widget? menu;

  final ListViewMode viewMode;

  /// 网格视图的列数**下限**（窗口更宽时自动加列）。
  final int galleryColumns;

  /// 日历视图内容。视图模式为 [ListViewMode.calendar] 且非空时替代列表，
  /// 且**无视空态逻辑** —— 没有记录的月份，日历本身仍然有意义。
  final Widget? calendarContent;

  /// 条目 key。给了才能在列表重排时保住条目内部状态（输入框内容、展开态）。
  final Object Function(T item)? itemKey;

  /// 列表内容区边距。
  final EdgeInsetsGeometry listPadding;

  /// 列表项间距。
  final double itemSpacing;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);

    return ColoredBox(
      color: tokens.extras.background,
      child: Column(
        children: [
          Header(
            // 搜索态下标题清空：搜索框本身就是"我在找什么"的上下文，
            // 标题和搜索框挤在一行会互相吃宽度。
            title: isSearchActive ? '' : title,
            leading1: isSearchActive
                ? IconButton(
                    icon: const Icon(Icons.arrow_back, size: 24),
                    tooltip: KitStringsScope.of(context).back,
                    onPressed: () => onSearchActiveChange(false),
                  )
                : null,
            action1: isSearchActive
                ? null
                : IconButton(
                    icon: const Icon(Icons.search, size: 24),
                    tooltip: KitStringsScope.of(context).search,
                    onPressed: onSearchClick,
                  ),
            action2: action2,
            menu: menu,
          ),
          Expanded(child: _body(context, tokens)),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, ThemeTokens tokens) {
    final showNoResults = searchQuery.isNotEmpty || selectedFilterIndex != 0;

    return Column(
      children: [
        // 搜索 + 筛选区：底色用 surface，和列表区的 background 拉开一层，
        // 滚动时列表从下面穿过去也不会粘在一起。
        ColoredBox(
          color: tokens.colorScheme.surface,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    CollapsibleSection(
                      isVisible: isSearchActive,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: KitSearchBar(
                          query: searchQuery,
                          onQueryChange: onSearchQueryChange,
                          onSearch: () {},
                        ),
                      ),
                    ),
                    CollapsibleSection(
                      isVisible: !isSearchActive,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        // 用 Row 而不是横向 ListView：筛选标签一般 3–6 个，
                        // 建一份懒列表不划算，还会因为拿不到确定高度而需要写死行高
                        // （写死就会把 Chip 的 48 触控区裁掉）。
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (var i = 0; i < filterOptions.length; i++) ...[
                                if (i > 0) const SizedBox(width: 8),
                                KitFilterChip(
                                  title: filterOptions[i],
                                  isSelected: selectedFilterIndex == i,
                                  onTap: () => onFilterSelected(i),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (headerContentTop != null) headerContentTop!,
            ],
          ),
        ),
        if (headerContentBottom != null) headerContentBottom!,
        Expanded(
          child: viewMode == ListViewMode.calendar && calendarContent != null
              ? calendarContent!
              : AnimatedContentSwitch<bool>(
                  target: items.isEmpty,
                  builder: (context, isEmpty) {
                    if (isEmpty) {
                      // 有筛选条件却空 → 说"没搜到"；什么都没设就空 → 说"还没有内容"。
                      // 两句文案的区别是「要不要教用户改检索」，用错了会让人白翻一遍。
                      return Center(
                        child: SingleChildScrollView(
                          child: showNoResults ? noResultsState : emptyState,
                        ),
                      );
                    }
                    return viewMode == ListViewMode.gallery
                        ? _gallery(context)
                        : _list();
                  },
                ),
        ),
        if (footerContent != null) footerContent!,
      ],
    );
  }

  Widget _list() {
    // 空列表走不到这里（上面已经分给空态），所以 items 非空。
    if (itemSpacing <= 0) {
      return ListView.builder(
        padding: listPadding,
        itemCount: items.length,
        itemBuilder: (context, i) => _item(items[i]),
      );
    }
    return ListView.separated(
      padding: listPadding,
      itemCount: items.length,
      separatorBuilder: (_, __) => SizedBox(height: itemSpacing),
      itemBuilder: (context, i) => _item(items[i]),
    );
  }

  Widget _gallery(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = gridSpacingFor(constraints.maxWidth);
        return GridView.builder(
          padding: EdgeInsets.all(spacing.margin),
          // 列数下限用调用方给的 galleryColumns：自适应算法在窄窗口下只保证 2 列，
          // 而两列的照片墙在平板上显得很空。
          gridDelegate: adaptiveGridDelegate(
            width: constraints.maxWidth,
            minColumns: galleryColumns,
            spacing: spacing.gutter,
            // 画廊卡片一般是"图 + 一行字"，接近正方形。
            childAspectRatio: 1,
          ),
          itemCount: items.length,
          itemBuilder: (context, i) => _item(items[i]),
        );
      },
    );
  }

  Widget _item(T item) {
    // `Builder` 是给 `itemContent` 一个「本条目自己的」context：
    // 模板自己的 context 在列表项里也能用，但它指向模板根部，
    // 条目内部再 `Navigator.push` / `Theme.of` 都会找错位置。
    final content = Builder(builder: (context) => itemContent(context, item));
    final key = itemKey?.call(item);
    // 包一层 KeyedSubtree：列表/网格只给子树挂 key，条目自己的 State 才能
    // 跟着条目走，而不是跟着位置走。不给 key 时只能按位置复用。
    if (key == null) return content;
    return KeyedSubtree(key: ValueKey<Object>(key), child: content);
  }
}

/// 列表条目数据模型。
@immutable
class KitListItem {
  const KitListItem({
    required this.id,
    required this.name,
    required this.category,
    this.isEmergency = false,
  });

  final String id;
  final String name;
  final String category;

  /// 紧急标记：右上角带一块 `errorContainer` 底的小标签。
  final bool isEmergency;
}

/// 标准列表项卡片 —— 圆形首字母头像 + 标题/分类 + 可选紧急标记。
///
/// 只是「最朴素的那种条目」，业务页可以照它改。
class KitListItemCard extends StatelessWidget {
  const KitListItemCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final KitListItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    final scheme = tokens.colorScheme;
    final strings = KitStringsScope.of(context);
    // 首字母要按「一个字符」取 —— 用 `item.name[0]` 会把 emoji 或组合字符
    // 从中间砍成半个，渲染出方块。
    final initial = item.name.runes.isEmpty
        ? '?'
        : String.fromCharCode(item.name.runes.first);

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: themedCircleShape(context),
            ),
            child: Text(
              initial,
              style: tokens.textTheme.titleMedium?.copyWith(
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: tokens.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.category,
                  style: tokens.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (item.isEmergency) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: tokens.shapes.small,
              ),
              child: Text(
                strings.urgent,
                style: tokens.textTheme.labelSmall?.copyWith(
                  color: scheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
