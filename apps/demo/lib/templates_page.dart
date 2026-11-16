import 'package:material_ui/material_ui.dart';
import 'package:kit/kit.dart' show AppSettings;
import 'package:kit/kit_ui.dart';

/// 模板屏演示：`KitListScreen` + `KitFormScreen`。
///
/// 这一页的作用和组件目录不同 —— 目录看的是「单个组件长得对不对」，
/// 这里看的是**页面结构**：搜索怎么接管页头、筛选怎么切、空态有几种、
/// 网格/日历怎么换。所有业务列表页都照这个结构抄。
class TemplatesPage extends StatefulWidget {
  const TemplatesPage({
    super.key,
    required this.settings,
    required this.onSettingsChange,
  });

  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChange;

  @override
  State<TemplatesPage> createState() => _TemplatesPageState();
}

class _TemplatesPageState extends State<TemplatesPage> {
  bool _searchActive = false;
  String _query = '';
  int _filter = 0;
  ListViewMode _mode = ListViewMode.list;

  /// 「宠物」这一档刻意留空 —— 用来演示「有筛选条件却没有结果」那一支空态。
  static const _filters = ['全部', '家人', '同事', '朋友', '宠物'];

  final List<KitListItem> _items = [
    const KitListItem(id: '1', name: '张三', category: '家人', isEmergency: true),
    const KitListItem(id: '2', name: '李四', category: '同事'),
    const KitListItem(id: '3', name: '王五', category: '朋友'),
    const KitListItem(id: '4', name: '赵六', category: '同事', isEmergency: true),
    const KitListItem(id: '5', name: '孙七', category: '家人'),
    const KitListItem(id: '6', name: '周八', category: '朋友'),
  ];

  /// 过滤放在页面里做（真实项目里放 ViewModel）—— 模板拿到的永远已经是结果。
  List<KitListItem> get _visible {
    final category = _filter == 0 ? null : _filters[_filter];
    return _items.where((item) {
      final byFilter = category == null || item.category == category;
      final byQuery = _query.isEmpty || item.name.contains(_query);
      return byFilter && byQuery;
    }).toList();
  }

  Future<void> _openForm({KitListItem? editing}) async {
    final saved = await Navigator.of(context).push<KitListItem>(
      MaterialPageRoute<KitListItem>(
        builder: (_) => _ContactFormPage(initial: editing),
      ),
    );
    if (saved == null || !mounted) return;
    setState(() {
      final i = _items.indexWhere((e) => e.id == saved.id);
      if (i >= 0) {
        _items[i] = saved;
      } else {
        _items.insert(0, saved);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KitListScreen<KitListItem>(
        title: '模板屏',
        isSearchActive: _searchActive,
        onSearchClick: () => setState(() => _searchActive = true),
        onSearchActiveChange: (v) => setState(() => _searchActive = v),
        searchQuery: _query,
        onSearchQueryChange: (v) => setState(() => _query = v),
        selectedFilterIndex: _filter,
        onFilterSelected: (i) => setState(() => _filter = i),
        filterOptions: _filters,
        items: _visible,
        itemKey: (item) => item.id,
        // 画廊格子里放不下「头像 + 两行字 + 徽标」的列表卡（100px 宽直接溢出），
        // 所以按视图换一套卡片 —— 真实页面也是这么做的。
        itemContent: (context, item) => _mode == ListViewMode.gallery
            ? _ContactTile(item: item, onTap: () => _openForm(editing: item))
            : KitListItemCard(item: item, onTap: () => _openForm(editing: item)),
        emptyState: EmptyStates.contacts(),
        noResultsState: EmptyStates.noSearchResults(_query),
        viewMode: _mode,
        action2: _viewModeButton(),
        menu: PopupMenuButton<String>(
          icon: const Icon(Icons.settings_outlined),
          tooltip: '设置',
          onSelected: (value) {
            if (value == 'settings') {
              _openSettings();
            } else {
              setState(() {
                _mode = ListViewMode.values.firstWhere((m) => m.name == value);
              });
            }
          },
          itemBuilder: (_) => [
            for (final m in ListViewMode.values)
              CheckedPopupMenuItem(
                value: m.name,
                checked: _mode == m,
                child: Text(_modeName(m)),
              ),
            const PopupMenuDivider(),
            const PopupMenuItem(value: 'settings', child: Text('设置')),
          ],
        ),
        calendarContent: _calendar(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        tooltip: '新增',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 视图模式在页头直接切换 —— 比塞进二级菜单少两次点击。
  Widget _viewModeButton() {
    final next = switch (_mode) {
      ListViewMode.list => (ListViewMode.gallery, Icons.grid_view, '切网格'),
      ListViewMode.gallery => (ListViewMode.calendar, Icons.calendar_month, '切日历'),
      ListViewMode.calendar => (ListViewMode.list, Icons.view_list, '切列表'),
    };
    return IconButton(
      icon: Icon(next.$2, size: 24),
      tooltip: next.$3,
      onPressed: () => setState(() => _mode = next.$1),
    );
  }

  Widget _calendar() => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: AppCalendar(
            selectedDate: DateTime(2026, 11, 15),
            onDateSelected: (_) {},
          ),
        ),
      );

  String _modeName(ListViewMode m) => switch (m) {
        ListViewMode.list => '列表',
        ListViewMode.gallery => '网格',
        ListViewMode.calendar => '日历',
      };

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StatefulBuilder(
          builder: (routeContext, setLocal) => SettingsScreen(
            settings: widget.settings,
            onSettingsChange: (next) {
              widget.onSettingsChange(next);
              setLocal(() {});
            },
            onBackClick: () => Navigator.of(routeContext).pop(),
          ),
        ),
      ),
    );
  }
}

/// 画廊用的方块卡片：一个大首字母 + 名字，宽度只有 100–160 也不溢出。
class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.item, required this.onTap});

  final KitListItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    final scheme = tokens.colorScheme;
    final initial =
        item.name.runes.isEmpty ? '?' : String.fromCharCode(item.name.runes.first);

    return SmallCard(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
          const SizedBox(height: 8),
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tokens.textTheme.bodyMedium,
          ),
          if (item.isEmergency)
            Text(
              KitStringsScope.of(context).urgent,
              style: tokens.textTheme.labelSmall?.copyWith(color: scheme.error),
            ),
        ],
      ),
    );
  }
}

/// 表单页演示：新增 / 编辑共用一套。这一页**不再自带 Scaffold 的页头**，
/// 页头由 `KitFormScreen` 提供。
class _ContactFormPage extends StatefulWidget {
  const _ContactFormPage({this.initial});

  final KitListItem? initial;

  @override
  State<_ContactFormPage> createState() => _ContactFormPageState();
}

class _ContactFormPageState extends State<_ContactFormPage> {
  late String _name = widget.initial?.name ?? '';
  late String _category = widget.initial?.category ?? '家人';
  late bool _urgent = widget.initial?.isEmergency ?? false;

  static const _categories = ['家人', '同事', '朋友'];

  bool get _valid => _name.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final editing = widget.initial != null;
    return Scaffold(
      // Scaffold 只为承载 SnackBar；页头在模板里。
      body: KitFormScreen(
        title: editing ? '编辑联系人' : '',
        isEditMode: editing,
        saveEnabled: _valid,
        onCloseClick: () => Navigator.of(context).pop(),
        onSaveClick: () {
          Navigator.of(context).pop(
            KitListItem(
              id: widget.initial?.id ??
                  DateTime.now().microsecondsSinceEpoch.toString(),
              name: _name.trim(),
              category: _category,
              isEmergency: _urgent,
            ),
          );
        },
        content: Column(
          children: [
            FormSection(
              title: '基本信息',
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SimpleTextField(
                    label: '姓名',
                    value: _name,
                    onValueChange: (v) => setState(() => _name = v),
                    isError: _name.isNotEmpty && !_valid,
                    helperText: _valid ? null : '必填',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SelectDropdown<String>(
                    label: '分类',
                    options: [
                      for (final c in _categories)
                        DropdownOption(label: c, value: c),
                    ],
                    selectedOption: _category,
                    onOptionSelected: (v) => setState(() => _category = v),
                  ),
                ),
              ],
            ),
            FormSection(
              title: '标记',
              children: [
                ToggleRow(
                  title: '紧急联系人',
                  subtitle: '列表里会带一枚紧急徽标',
                  isChecked: _urgent,
                  onCheckedChange: (v) => setState(() => _urgent = v),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
