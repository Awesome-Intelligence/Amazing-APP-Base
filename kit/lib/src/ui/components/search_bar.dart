import 'package:material_ui/material_ui.dart';

import '../../i18n/kit_strings.dart';
import '../../theme/kit_theme.dart';

/// 搜索框（Google 风格）—— M3 filled search bar。
///
/// 56 高、`surfaceVariant` 八成底、无边框，右侧可挂清除与筛选按钮。
///
/// 名字带 `Kit` 前缀：Flutter material 自带 `SearchBar`，调用方两个包都要 import，
/// 不隔开必撞名。
///
/// **受控组件**：[query] 是唯一真相。内部自建 controller 并在 [didUpdateWidget] 回灌，
/// 否则「点清除按钮把输入框清空」只会改外部 state、屏幕上的字还在。
class KitSearchBar extends StatefulWidget {
  const KitSearchBar({
    super.key,
    required this.query,
    required this.onQueryChange,
    required this.onSearch,
    this.placeholder,
    this.enabled = true,
    this.onFilterClick,
    this.filterActive = false,
  });

  final String query;
  final ValueChanged<String> onQueryChange;

  /// 键盘上按「搜索」时触发，随后会收起焦点。
  final VoidCallback onSearch;

  /// 占位文案；不传用底座的「搜索...」。
  final String? placeholder;

  final bool enabled;

  /// 传了才显示筛选按钮。
  final VoidCallback? onFilterClick;

  /// 筛选生效中 —— 筛选按钮变主色。
  final bool filterActive;

  @override
  State<KitSearchBar> createState() => _KitSearchBarState();
}

class _KitSearchBarState extends State<KitSearchBar> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.query);
  final FocusNode _focusNode = FocusNode();

  @override
  void didUpdateWidget(KitSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 外部改了 query（比如点清除、或搜索后清空）就回灌，
    // 否则 controller 里的旧文本会一直盖住新状态。
    if (widget.query != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.query,
        selection: TextSelection.collapsed(offset: widget.query.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    widget.onSearch();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    final strings = KitStringsScope.of(context);
    final hasFilter = widget.onFilterClick != null;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: tokens.extras.surfaceVariant.withValues(alpha: 0.8),
        borderRadius: tokens.shapes.extraLarge,
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(Icons.search, size: 24, color: tokens.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              onChanged: widget.onQueryChange,
              onSubmitted: (_) => _submit(),
              textInputAction: TextInputAction.search,
              textCapitalization: TextCapitalization.none,
              style: tokens.textTheme.bodyLarge
                  ?.copyWith(color: tokens.colorScheme.onSurface),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: widget.placeholder ?? strings.searchHint,
                hintStyle: tokens.textTheme.bodyLarge
                    ?.copyWith(color: tokens.colorScheme.onSurfaceVariant),
              ),
            ),
          ),
          // 清除 / 筛选按钮按需出现。KMP 版用了 AnimatedVisibility，
          // 这里直接条件渲染：显隐会带动 Row 宽度变化，动画反而更抖。
          if (widget.query.isNotEmpty)
            IconButton(
              onPressed: () => widget.onQueryChange(''),
              tooltip: strings.clear,
              icon: Icon(
                Icons.clear,
                size: 20,
                color: tokens.colorScheme.onSurfaceVariant,
              ),
            ),
          if (hasFilter)
            IconButton(
              onPressed: widget.onFilterClick,
              tooltip: strings.filter,
              icon: Icon(
                Icons.swap_vert,
                size: 24,
                color: widget.filterActive
                    ? tokens.colorScheme.primary
                    : tokens.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

/// 搜索开关按钮 —— 顶栏 action 用。
///
/// 未展开时是放大镜，展开后变成向上箭头：区别于 X 关闭，
/// 语义是「把搜索框收回去」，同时调用方应清空已输入的搜索词。
class SearchToggleButton extends StatelessWidget {
  const SearchToggleButton({
    super.key,
    required this.isSearchActive,
    required this.onToggle,
  });

  final bool isSearchActive;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final strings = KitStringsScope.of(context);
    return IconButton(
      onPressed: onToggle,
      tooltip: isSearchActive ? strings.collapse : strings.search,
      icon: Icon(
        isSearchActive ? Icons.keyboard_arrow_up : Icons.search,
        size: 24,
      ),
    );
  }
}
