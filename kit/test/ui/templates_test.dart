import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit/kit.dart';
import 'package:kit/kit_ui.dart';

/// 模板屏：`KitListScreen` / `KitFormScreen` + 两个动效组件。
///
/// 模板是「所有页面都得照抄」的东西，所以测试重点不是"画得出来"，
/// 而是**结构约定有没有被破坏**：搜索和筛选是否互斥、空态该走哪一支、
/// 日历模式是否无视空态、保存按钮在什么条件下禁用。
void main() {
  Future<void> pumpShell(
    WidgetTester tester,
    Widget child, {
    AppSettings settings = const AppSettings(language: AppLanguage.chinese),
  }) {
    return tester.pumpWidget(
      KitAppShell(settings: settings, home: Scaffold(body: child)),
    );
  }

  const items = <KitListItem>[
    KitListItem(id: 'a', name: '张三', category: '家人', isEmergency: true),
    KitListItem(id: 'b', name: '李四', category: '同事'),
    KitListItem(id: 'c', name: '王五', category: '朋友'),
  ];

  /// 造一个「够用」的列表页：状态由测试持有，页面只回调 —— 和真实页面一致。
  Widget listScreen({
    List<KitListItem>? data,
    String query = '',
    int filter = 0,
    bool searchActive = false,
    ListViewMode mode = ListViewMode.list,
    Widget? calendarContent,
    Widget? headerContentTop,
    void Function(bool)? onSearchActiveChange,
  }) {
    final list = data ?? items;
    return KitListScreen<KitListItem>(
      title: '模板',
      onSearchClick: () => onSearchActiveChange?.call(true),
      isSearchActive: searchActive,
      onSearchActiveChange: (v) => onSearchActiveChange?.call(v),
      searchQuery: query,
      onSearchQueryChange: (_) {},
      selectedFilterIndex: filter,
      onFilterSelected: (_) {},
      filterOptions: const ['全部', '家人', '同事'],
      items: list,
      itemKey: (item) => item.id,
      itemContent: (context, item) =>
          KitListItemCard(item: item, onTap: () {}),
      emptyState: EmptyStates.contacts(),
      noResultsState: EmptyStates.noSearchResults(query),
      viewMode: mode,
      calendarContent: calendarContent,
      headerContentTop: headerContentTop,
    );
  }

  group('列表页 · 结构', () {
    testWidgets('页头标题、筛选标签、条目都在', (tester) async {
      await pumpShell(tester, listScreen());
      await tester.pumpAndSettle();

      expect(find.text('模板'), findsOneWidget);
      expect(find.text('全部'), findsOneWidget);
      expect(find.text('家人'), findsWidgets); // 筛选标签 + 条目分类
      expect(find.text('张三'), findsOneWidget);
      expect(find.text('王五'), findsOneWidget);
    });

    testWidgets('有 itemKey 时条目带 key，重排能保住条目状态', (tester) async {
      await pumpShell(tester, listScreen());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey<Object>('a')), findsOneWidget);
      expect(find.byKey(const ValueKey<Object>('c')), findsOneWidget);
    });

    testWidgets('点筛选标签回传索引', (tester) async {
      int? picked;
      await pumpShell(
        tester,
        KitListScreen<KitListItem>(
          title: '模板',
          onSearchClick: () {},
          isSearchActive: false,
          onSearchActiveChange: (_) {},
          searchQuery: '',
          onSearchQueryChange: (_) {},
          selectedFilterIndex: 0,
          onFilterSelected: (i) => picked = i,
          filterOptions: const ['全部', '家人', '同事'],
          items: items,
          itemContent: (ctx, item) => KitListItemCard(item: item, onTap: () {}),
          emptyState: EmptyStates.contacts(),
          noResultsState: EmptyStates.noSearchResults(''),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('同事').first);
      expect(picked, 2);
    });

    testWidgets('headerContentTop 排在搜索区里、列表之上', (tester) async {
      await pumpShell(
        tester,
        listScreen(headerContentTop: const SizedBox(height: 32, child: Text('日期条'))),
      );
      await tester.pumpAndSettle();

      expect(find.text('日期条'), findsOneWidget);
      final headerY = tester.getTopLeft(find.text('日期条')).dy;
      final firstItemY = tester.getTopLeft(find.text('张三')).dy;
      expect(headerY, lessThan(firstItemY));
    });
  });

  group('列表页 · 搜索与筛选互斥', () {
    testWidgets('搜索态：标题清空、出现返回、搜索框在、筛选行收起', (tester) async {
      await pumpShell(
        tester,
        listScreen(searchActive: true, onSearchActiveChange: (_) {}),
      );
      await tester.pumpAndSettle();

      // 标题位让给搜索框
      expect(find.text('模板'), findsNothing);
      // 筛选行整块拿掉（不是透明度 0）
      expect(find.text('全部'), findsNothing);
      // 搜索框与返回箭头都在
      expect(find.byType(KitSearchBar), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      // 页头那个"进入搜索"的放大镜不该再有；屏幕上唯一的放大镜是搜索框自带的
      expect(
        find.descendant(
          of: find.byType(KitSearchBar),
          matching: find.byIcon(Icons.search),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(Header),
          matching: find.byIcon(Icons.search),
        ),
        findsNothing,
      );
    });

    testWidgets('点返回把搜索态关掉', (tester) async {
      bool? active;
      await pumpShell(
        tester,
        listScreen(searchActive: true, onSearchActiveChange: (v) => active = v),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(active, isFalse);
    });

    testWidgets('非搜索态：放大镜在、搜索框不在', (tester) async {
      await pumpShell(tester, listScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byType(KitSearchBar), findsNothing);
    });

    testWidgets('点放大镜进入搜索态', (tester) async {
      bool? active;
      await pumpShell(
        tester,
        listScreen(onSearchActiveChange: (v) => active = v),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search));
      expect(active, isTrue);
    });
  });

  group('列表页 · 空态分支', () {
    testWidgets('一条都没有 + 没筛选条件 → 「还没有内容」', (tester) async {
      await pumpShell(tester, listScreen(data: const []));
      await tester.pumpAndSettle();

      expect(find.text('暂无联系人'), findsOneWidget);
      // 不该出现"换个关键词"，因为用户根本没搜
      expect(find.text('未找到结果'), findsNothing);
    });

    testWidgets('一条都没有 + 有搜索词 → 「未找到结果」', (tester) async {
      await pumpShell(tester, listScreen(data: const [], query: '阿猫'));
      await tester.pumpAndSettle();

      expect(find.text('未找到结果'), findsOneWidget);
      expect(find.text('暂无联系人'), findsNothing);
    });

    testWidgets('一条都没有 + 选了非首个筛选 → 也算「未找到结果」', (tester) async {
      await pumpShell(tester, listScreen(data: const [], filter: 2));
      await tester.pumpAndSettle();

      expect(find.text('未找到结果'), findsOneWidget);
    });

    testWidgets('先空后有：切到有数据时列表真的出来', (tester) async {
      await pumpShell(tester, listScreen(data: const []));
      await tester.pumpAndSettle();
      expect(find.text('暂无联系人'), findsOneWidget);

      await pumpShell(tester, listScreen());
      await tester.pumpAndSettle();

      expect(find.text('暂无联系人'), findsNothing);
      expect(find.text('张三'), findsOneWidget);
    });
  });

  group('列表页 · 视图模式', () {
    testWidgets('grid 视图用网格铺，列数不少于 galleryColumns', (tester) async {
      // 画廊格子约 100px 宽，标准列表卡（48 头像 + 文字 + 徽标）在里面放不下 ——
      // 画廊本来也该用自己的方块卡片，所以这里换一个最简条目，只验布局。
      await pumpShell(
        tester,
        KitListScreen<KitListItem>(
          title: '模板',
          onSearchClick: () {},
          isSearchActive: false,
          onSearchActiveChange: (_) {},
          searchQuery: '',
          onSearchQueryChange: (_) {},
          selectedFilterIndex: 0,
          onFilterSelected: (_) {},
          filterOptions: const ['全部'],
          items: items,
          itemContent: (ctx, item) => SmallCard(child: Text(item.name)),
          emptyState: EmptyStates.contacts(),
          noResultsState: EmptyStates.noSearchResults(''),
          viewMode: ListViewMode.gallery,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(ListView), findsNothing);

      final grid = tester.widget<GridView>(find.byType(GridView));
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, greaterThanOrEqualTo(2));
    });

    testWidgets('日历模式：没数据也照常渲染日历（空态不接管）', (tester) async {
      await pumpShell(
        tester,
        listScreen(
          data: const [],
          mode: ListViewMode.calendar,
          calendarContent: const Center(child: Text('日历本体')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('日历本体'), findsOneWidget);
      // 日历自己有意义，不该被「还没有内容」盖掉
      expect(find.text('暂无联系人'), findsNothing);
    });

    testWidgets('日历模式但没给内容 → 退回列表渲染', (tester) async {
      await pumpShell(
        tester,
        listScreen(mode: ListViewMode.calendar, calendarContent: null),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('张三'), findsOneWidget);
    });
  });

  group('列表项卡片', () {
    testWidgets('首字母头像 + 名称 + 分类 + 紧急标记', (tester) async {
      await pumpShell(
        tester,
        Scaffold(
          body: KitListItemCard(
            item: const KitListItem(
              id: 'x',
              name: '张三',
              category: '家人',
              isEmergency: true,
            ),
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('张'), findsOneWidget); // 首字母
      expect(find.text('张三'), findsOneWidget);
      expect(find.text('家人'), findsOneWidget);
      expect(find.text('紧急'), findsOneWidget);
    });

    testWidgets('不紧急时没有徽标', (tester) async {
      await pumpShell(
        tester,
        Scaffold(
          body: KitListItemCard(
            item: const KitListItem(id: 'y', name: '李四', category: '同事'),
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('紧急'), findsNothing);
    });

    testWidgets('emoji 开头的名字不会切出半个字符', (tester) async {
      await pumpShell(
        tester,
        Scaffold(
          body: KitListItemCard(
            item: const KitListItem(id: 'z', name: '🐱猫咪', category: '宠物'),
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 取 runes 而不是 code units，否则这里会是个孤立的代理对（渲染成方块）
      expect(find.text('🐱'), findsOneWidget);
    });

    testWidgets('空名字回落成问号，不抛 RangeError', (tester) async {
      await pumpShell(
        tester,
        Scaffold(
          body: KitListItemCard(
            item: const KitListItem(id: 'w', name: '', category: '未知'),
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('?'), findsOneWidget);
    });
  });

  group('表单页', () {
    testWidgets('标题为空串时按模式回落成「添加」', (tester) async {
      await pumpShell(
        tester,
        KitFormScreen(
          title: '',
          isEditMode: false,
          onCloseClick: () {},
          onSaveClick: () {},
          content: const SizedBox.shrink(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('添加'), findsOneWidget);
    });

    testWidgets('编辑模式标题回落成「编辑」', (tester) async {
      await pumpShell(
        tester,
        KitFormScreen(
          title: '',
          isEditMode: true,
          onCloseClick: () {},
          onSaveClick: () {},
          content: const SizedBox.shrink(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('编辑'), findsOneWidget);
    });

    testWidgets('有标题就用标题，不覆盖', (tester) async {
      await pumpShell(
        tester,
        KitFormScreen(
          title: '新增联系人',
          isEditMode: false,
          onCloseClick: () {},
          onSaveClick: () {},
          content: const SizedBox.shrink(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('新增联系人'), findsOneWidget);
      expect(find.text('添加'), findsNothing);
    });

    testWidgets('保存按钮在 saveEnabled=false 时点不动', (tester) async {
      var saved = 0;
      await pumpShell(
        tester,
        KitFormScreen(
          title: '新增',
          isEditMode: false,
          saveEnabled: false,
          onCloseClick: () {},
          onSaveClick: () => saved++,
          content: const SizedBox.shrink(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.check));
      expect(saved, 0);
    });

    testWidgets('保存中也不能再点（防重复提交）', (tester) async {
      var saved = 0;
      await pumpShell(
        tester,
        KitFormScreen(
          title: '新增',
          isEditMode: false,
          saveLoading: true,
          onSaveClick: () => saved++,
          onCloseClick: () {},
          content: const SizedBox.shrink(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.check));
      expect(saved, 0);
    });

    testWidgets('可保存时点勾回传保存、点返回回传关闭', (tester) async {
      var saved = 0;
      var closed = 0;
      await pumpShell(
        tester,
        KitFormScreen(
          title: '新增',
          isEditMode: false,
          onCloseClick: () => closed++,
          onSaveClick: () => saved++,
          content: const SizedBox.shrink(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.check));
      await tester.tap(find.byIcon(Icons.arrow_back));
      expect(saved, 1);
      expect(closed, 1);
    });

    testWidgets('分组标题 + 字段标签渲染出来', (tester) async {
      await pumpShell(
        tester,
        KitFormScreen(
          title: '新增',
          isEditMode: false,
          onCloseClick: () {},
          onSaveClick: () {},
          content: FormSection(
            title: '基本信息',
            children: [
              KitFormField(
                label: '标签',
                child: const Text('非文本控件占位'),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('基本信息'), findsOneWidget);
      expect(find.text('标签'), findsOneWidget);
      expect(find.text('非文本控件占位'), findsOneWidget);
    });

    testWidgets('内容超高时可以滚（表单页不会把字段挤掉）', (tester) async {
      await pumpShell(
        tester,
        KitFormScreen(
          title: '新增',
          isEditMode: false,
          onCloseClick: () {},
          onSaveClick: () {},
          content: Column(
            children: [
              for (var i = 0; i < 30; i++)
                SizedBox(height: 60, child: Text('字段 $i')),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final before = tester.getTopLeft(find.text('字段 0')).dy;
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();
      // 注意：`SingleChildScrollView` 不是懒加载，滚出去的子项**仍在树上**，
      // 所以不能断言 findsNothing，只能断言它被推上去了。
      expect(tester.getTopLeft(find.text('字段 0')).dy, lessThan(before));
    });
  });

  group('CollapsibleSection', () {
    testWidgets('不可见时内容完全不建（不是透明度 0）', (tester) async {
      await pumpShell(
        tester,
        const CollapsibleSection(isVisible: false, child: Text('收起的内容')),
      );
      await tester.pumpAndSettle();

      expect(find.text('收起的内容'), findsNothing);
    });

    testWidgets('可见时正常渲染', (tester) async {
      await pumpShell(
        tester,
        const CollapsibleSection(isVisible: true, child: Text('展开的内容')),
      );
      await tester.pumpAndSettle();

      expect(find.text('展开的内容'), findsOneWidget);
    });

    testWidgets('从开到关：动画结束后内容消失', (tester) async {
      await pumpShell(
        tester,
        const CollapsibleSection(isVisible: true, child: Text('内容')),
      );
      await tester.pumpAndSettle();
      expect(find.text('内容'), findsOneWidget);

      await pumpShell(
        tester,
        const CollapsibleSection(isVisible: false, child: Text('内容')),
      );
      await tester.pump(const Duration(milliseconds: 100));
      // 动画途中还在（正被裁掉）
      expect(find.text('内容'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('内容'), findsNothing);
    });

    testWidgets('减动效时立刻到位，不等动画', (tester) async {
      await tester.pumpWidget(
        KitAppShell(
          settings: const AppSettings(
            language: AppLanguage.chinese,
            reducedMotion: true,
          ),
          home: const Scaffold(
            body: CollapsibleSection(isVisible: false, child: Text('内容')),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('内容'), findsNothing);
    });
  });

  group('AnimatedContentSwitch', () {
    testWidgets('静止时只有当前内容', (tester) async {
      await pumpShell(
        tester,
        AnimatedContentSwitch<int>(
          target: 1,
          builder: (context, t) => Text('状态 $t'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('状态 1'), findsOneWidget);
      expect(find.text('状态 0'), findsNothing);
    });

    testWidgets('状态变化时两段不重叠：先只有旧的，再只有新的', (tester) async {
      await pumpShell(
        tester,
        AnimatedContentSwitch<int>(
          target: 0,
          builder: (context, t) => Text('状态 $t'),
        ),
      );
      await tester.pumpAndSettle();

      await pumpShell(
        tester,
        AnimatedContentSwitch<int>(
          target: 1,
          builder: (context, t) => Text('状态 $t'),
        ),
      );
      // 退场阶段（前 90ms）：仍能看见旧内容
      await tester.pump(const Duration(milliseconds: 40));
      expect(find.text('状态 0'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('状态 1'), findsOneWidget);
      expect(find.text('状态 0'), findsNothing);
    });

    testWidgets('target 没变就不放转场', (tester) async {
      await pumpShell(
        tester,
        AnimatedContentSwitch<int>(
          target: 5,
          builder: (context, t) => Text('状态 $t'),
        ),
      );
      await tester.pumpAndSettle();

      await pumpShell(
        tester,
        AnimatedContentSwitch<int>(
          target: 5,
          builder: (context, t) => Text('状态 $t'),
        ),
      );
      await tester.pump();
      expect(find.text('状态 5'), findsOneWidget);
    });
  });
}
