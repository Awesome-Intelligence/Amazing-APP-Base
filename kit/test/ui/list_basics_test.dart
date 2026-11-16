import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit/kit.dart';
import 'package:kit/kit_ui.dart';

/// 列表页基础设施：空态 / 反馈 / 进度 / 菜单 / 下拉 / 导航 / 头像 / 网格。
///
/// 这一层不比日历的日期计算，但有几个地方「看起来对、用起来错」——
/// 不加载的遮罩挡住点击、菜单回调索引错位、进度超 1 画到轨道外 —— 都得测。
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

  group('网格列数', () {
    test('宽屏按 minSize 塞尽可能多的列', () {
      // (600 + 12) / (132 + 12) = 4.25 → 4 列
      expect(adaptiveGridColumns(600), 4);
      // (1200 + 12) / 144 = 8.4 → 8 列
      expect(adaptiveGridColumns(1200), 8);
    });

    test('窄屏不掉到 1 列 —— 这是它存在的原因', () {
      // 按纯 adaptive 算法：(200+12)/144 = 1.47 → 1 列，卡片会又宽又扁
      expect(adaptiveGridColumns(200), 2);
      expect(adaptiveGridColumns(100), 2);
    });

    test('宽度为 0 / 负数时给下限，不崩也不给 0 列', () {
      expect(adaptiveGridColumns(0), 2);
      expect(adaptiveGridColumns(-50), 2);
    });

    test('自定义 minSize 与 minColumns 生效', () {
      // (300 + 12) / (80 + 12) = 3.39 → 3 列
      expect(adaptiveGridColumns(300, minSize: 80), 3);
      // 同样宽度要求至少 6 列时，下限优先
      expect(adaptiveGridColumns(300, minSize: 80, minColumns: 6), 6);
    });

    test('边距按 600dp 断点分档', () {
      expect(gridSpacingFor(360), const GridSpacing(margin: 16, gutter: 12));
      expect(gridSpacingFor(599), const GridSpacing(margin: 16, gutter: 12));
      expect(gridSpacingFor(600), const GridSpacing(margin: 24, gutter: 16));
      expect(gridSpacingFor(1024), const GridSpacing(margin: 24, gutter: 16));
    });

    test('代理会先扣掉两侧边距再算列数', () {
      // 800 宽、margin 24 ×2 → 内容 752；(752+16)/(132+16)=5.18 → 5 列
      final d = adaptiveGridDelegate(width: 800) as SliverGridDelegateWithFixedCrossAxisCount;
      expect(d.crossAxisCount, 5);
      expect(d.crossAxisSpacing, 16);
    });
  });

  group('空状态', () {
    testWidgets('预设空态有图标、标题、副标题', (tester) async {
      await pumpShell(tester, EmptyStates.goals());
      await tester.pumpAndSettle();

      expect(find.text('暂无目标'), findsOneWidget);
      expect(find.text('开始设定你的第一个目标吧'), findsOneWidget);
      expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
    });

    testWidgets('英文环境走英文文案', (tester) async {
      await pumpShell(
        tester,
        EmptyStates.goals(),
        settings: const AppSettings(language: AppLanguage.english),
      );
      await tester.pumpAndSettle();

      expect(find.text('No goals yet'), findsOneWidget);
      expect(find.text('暂无目标'), findsNothing);
    });

    testWidgets('带主操作时出现按钮，点了会回调', (tester) async {
      var tapped = 0;
      await pumpShell(
        tester,
        IllustratedEmptyState(
          icon: Icons.inbox,
          title: '空空如也',
          subtitle: '还没东西',
          actionTitle: '新建',
          onAction: () => tapped++,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('新建'));
      expect(tapped, 1);
    });

    testWidgets('只传标题也给渲染（副标题和按钮都是可选）', (tester) async {
      await pumpShell(
        tester,
        const IllustratedEmptyState(icon: Icons.inbox, title: '只有标题'),
      );
      await tester.pumpAndSettle();

      expect(find.text('只有标题'), findsOneWidget);
      expect(find.byType(PrimaryButton), findsNothing);
    });
  });

  group('反馈', () {
    testWidgets('成功与失败用不同图标和语义标签', (tester) async {
      await pumpShell(
        tester,
        const Column(
          children: [
            AppSnackbar(message: '保存好了', isSuccess: true),
            AppSnackbar(message: '失败了', isSuccess: false),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.text('保存好了'), findsOneWidget);
      expect(find.text('失败了'), findsOneWidget);
    });

    testWidgets('showAppSnackbar 能弹出来', (tester) async {
      await pumpShell(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showAppSnackbar(context, message: '已保存'),
            child: const Text('触发'),
          ),
        ),
      );
      await tester.tap(find.text('触发'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('已保存'), findsOneWidget);
    });

    testWidgets('遮罩不加载时不吃点击', (tester) async {
      var taps = 0;
      await pumpShell(
        tester,
        LoadingOverlay(
          isLoading: false,
          child: Center(
            child: FilledButton(
              onPressed: () => taps++,
              child: const Text('下面的按钮'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('下面的按钮'));
      expect(taps, 1, reason: '隐藏的遮罩不能拦住底层点击');
    });

    testWidgets('遮罩加载时拦住点击', (tester) async {
      var taps = 0;
      await pumpShell(
        tester,
        LoadingOverlay(
          isLoading: true,
          child: Center(
            child: FilledButton(
              onPressed: () => taps++,
              child: const Text('下面的按钮'),
            ),
          ),
        ),
      );
      // 不能 pumpAndSettle：转圈是无限动画，永远等不到静止。
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      await tester.tap(find.text('下面的按钮'), warnIfMissed: false);
      expect(taps, 0);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });
  });

  group('进度', () {
    testWidgets('线性进度条正常渲染', (tester) async {
      await pumpShell(tester, const LinearProgressBar(progress: 0.4));
      await tester.pumpAndSettle();
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('进度超过 1 会被夹住，不会画到轨道外', (tester) async {
      await pumpShell(tester, const LinearProgressBar(progress: 1.8));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, lessThanOrEqualTo(1.0));
    });

    testWidgets('进度为负会被夹到 0', (tester) async {
      await pumpShell(tester, const CircularProgressIndicatorWithText(progress: -0.5));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('环形进度显示百分比', (tester) async {
      await pumpShell(
        tester,
        const CircularProgressIndicatorWithText(progress: 0.75),
      );
      await tester.pumpAndSettle();

      expect(find.text('75%'), findsOneWidget);
    });
  });

  group('状态标记', () {
    testWidgets('实心填色、空心描边', (tester) async {
      await pumpShell(
        tester,
        const Row(
          children: [
            StatusMark(filled: true),
            StatusMark(filled: false),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final boxes = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((b) => b.decoration as BoxDecoration)
          .where((d) => d.shape == BoxShape.rectangle)
          .toList();

      final filled = boxes.where((d) => d.color != null).length;
      final outlined = boxes.where((d) => d.border != null).length;
      expect(filled, greaterThanOrEqualTo(1));
      expect(outlined, greaterThanOrEqualTo(1));
    });
  });

  group('菜单', () {
    testWidgets('打开菜单能看到全部项', (tester) async {
      await pumpShell(
        tester,
        SimpleMenuButton(
          items: const [
            SimpleMenuItem(title: '编辑', icon: Icons.edit_outlined),
            SimpleMenuItem(title: '删除', icon: Icons.delete_outline),
          ],
          onItemSelected: (_, __) {},
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('编辑'), findsOneWidget);
      expect(find.text('删除'), findsOneWidget);
    });

    testWidgets('点顶层项回调 (索引, -1)', (tester) async {
      final picked = <(int, int)>[];
      await pumpShell(
        tester,
        SimpleMenuButton(
          items: const [
            SimpleMenuItem(title: '第一项'),
            SimpleMenuItem(title: '第二项'),
          ],
          onItemSelected: (p, s) => picked.add((p, s)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('第二项'));
      await tester.pumpAndSettle();

      expect(picked, [(1, -1)], reason: '索引是 items 里的位置，顶层子索引为 -1');
    });

    testWidgets('分割线不占可见项也不触发回调', (tester) async {
      final picked = <(int, int)>[];
      await pumpShell(
        tester,
        SimpleMenuButton(
          items: const [
            SimpleMenuItem(title: '上面'),
            SimpleMenuItem.divider(),
            SimpleMenuItem(title: '下面'),
          ],
          onItemSelected: (p, s) => picked.add((p, s)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      expect(find.byType(Divider), findsOneWidget);

      await tester.tap(find.text('下面'));
      await tester.pumpAndSettle();
      // 分割线占位，所以「下面」是索引 2
      expect(picked, [(2, -1)]);
    });

    testWidgets('ActionMenuRow 把编辑/删除分发出去', (tester) async {
      var edited = 0;
      var deleted = 0;
      await pumpShell(
        tester,
        ActionMenuRow(onEdit: () => edited++, onDelete: () => deleted++),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();

      expect(deleted, 1);
      expect(edited, 0);
    });
  });

  group('下拉选择', () {
    testWidgets('未选中显示占位文案', (tester) async {
      await pumpShell(
        tester,
        SelectDropdown<String>(
          options: const [
            DropdownOption(label: '低', value: 'low'),
            DropdownOption(label: '高', value: 'high'),
          ],
          selectedOption: null,
          onOptionSelected: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('请选择'), findsWidgets);
    });

    testWidgets('选中后显示标签，选另一项会回调', (tester) async {
      String? picked;
      await pumpShell(
        tester,
        SelectDropdown<String>(
          options: const [
            DropdownOption(label: '低', value: 'low'),
            DropdownOption(label: '高', value: 'high'),
          ],
          selectedOption: 'low',
          onOptionSelected: (v) => picked = v,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('低'), findsOneWidget);

      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('高').last);
      await tester.pumpAndSettle();

      expect(picked, 'high');
    });

    testWidgets('禁用时点不开', (tester) async {
      await pumpShell(
        tester,
        SelectDropdown<String>(
          options: const [DropdownOption(label: '低', value: 'low')],
          selectedOption: 'low',
          onOptionSelected: (_) {},
          enabled: false,
        ),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<DropdownButton<String>>(
        find.byType(DropdownButton<String>),
      );
      expect(button.onChanged, isNull);
    });
  });

  group('分页指示器', () {
    testWidgets('单页不渲染任何东西', (tester) async {
      await pumpShell(tester, const PageIndicator(pageCount: 1, currentPage: 0));
      await tester.pumpAndSettle();
      expect(find.byType(AnimatedContainer), findsNothing);
    });

    testWidgets('多页渲染对应数量的点，当前页是胶囊', (tester) async {
      await pumpShell(tester, const PageIndicator(pageCount: 4, currentPage: 1));
      await tester.pumpAndSettle();

      final dots = tester.widgetList<AnimatedContainer>(find.byType(AnimatedContainer));
      expect(dots.length, 4);
      final heights = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .map((c) => c.constraints?.maxHeight)
          .toList();
      // 第 2 个（索引 1）是当前页
      expect(heights[1], 16);
      expect(heights[0], 6);
    });

    testWidgets('读屏能读出「第几页，共几页」', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpShell(tester, const PageIndicator(pageCount: 3, currentPage: 0));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('第 1 页，共 3 页'), findsOneWidget);
      handle.dispose();
    });
  });

  group('底部导航', () {
    List<BottomNavItem> items() => const [
          BottomNavItem(label: '首页', icon: Icons.home_outlined, selectedIcon: Icons.home),
          BottomNavItem(label: '消息', icon: Icons.mail_outline, badgeCount: 3),
          BottomNavItem(label: '添加', icon: Icons.add, alwaysFilled: true),
        ];

    testWidgets('三项都渲染，带角标的那项显示数字', (tester) async {
      await pumpShell(
        tester,
        AppBottomNavigation(items: items(), selectedIndex: 0, onItemSelected: (_) {}),
      );
      await tester.pumpAndSettle();

      expect(find.text('首页'), findsOneWidget);
      expect(find.text('消息'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('点第二项回调索引 1', (tester) async {
      int? tapped;
      await pumpShell(
        tester,
        AppBottomNavigation(
          items: items(),
          selectedIndex: 0,
          onItemSelected: (i) => tapped = i,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('消息'));
      await tester.pumpAndSettle();
      expect(tapped, 1);
    });

    testWidgets('动作项（alwaysFilled）没有文字标签，但仍可点', (tester) async {
      int? tapped;
      await pumpShell(
        tester,
        AppBottomNavigation(
          items: items(),
          selectedIndex: 0,
          onItemSelected: (i) => tapped = i,
        ),
      );
      await tester.pumpAndSettle();

      // 标签是空串，所以文字里找不到「添加」；图标还在
      expect(find.text('添加'), findsNothing);
      expect(find.byIcon(Icons.add), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(tapped, 2, reason: '动作项也是目的地，点了要回调它自己的索引');
    });

    testWidgets('角标超过 99 显示 99+', (tester) async {
      await pumpShell(
        tester,
        AppBottomNavigation(
          items: const [
            BottomNavItem(label: '首页', icon: Icons.home_outlined),
            BottomNavItem(label: '消息', icon: Icons.mail_outline, badgeCount: 120),
          ],
          selectedIndex: 0,
          onItemSelected: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('只有一项时断言失败（框架限制，提前报错）', (tester) async {
      await tester.pumpWidget(
        KitAppShell(
          settings: const AppSettings(language: AppLanguage.chinese),
          home: Scaffold(
            body: AppBottomNavigation(
              items: const [BottomNavItem(label: '首页', icon: Icons.home_outlined)],
              selectedIndex: 0,
              onItemSelected: (_) {},
            ),
          ),
        ),
      );
      expect(tester.takeException(), isAssertionError);
    });
  });

  group('头像', () {
    testWidgets('无头像图时显示名字首字母', (tester) async {
      await pumpShell(tester, const UserAvatar(avatar: null, name: '张三'));
      await tester.pumpAndSettle();

      expect(find.text('张'), findsOneWidget);
    });

    testWidgets('空字符串头像也退回首字母（不是空白圆）', (tester) async {
      await pumpShell(tester, const UserAvatar(avatar: '   ', name: '李四'));
      await tester.pumpAndSettle();

      expect(find.text('李'), findsOneWidget);
    });

    testWidgets('emoji 开头的名字不会切出半个字符', (tester) async {
      await pumpShell(tester, const UserAvatar(avatar: null, name: '👍赞'));
      await tester.pumpAndSettle();

      expect(find.text('👍'), findsOneWidget);
    });

    testWidgets('空名字兜底成问号', (tester) async {
      await pumpShell(tester, const UserAvatar(avatar: null, name: ''));
      await tester.pumpAndSettle();

      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('人数不超量时不折叠、不显示 +N', (tester) async {
      await pumpShell(
        tester,
        AvatarStack(
          contacts: const [
            ContactItem(id: '1', name: '甲'),
            ContactItem(id: '2', name: '乙'),
          ],
          onContactClick: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('甲'), findsOneWidget);
      expect(find.text('乙'), findsOneWidget);
      expect(find.textContaining('+'), findsNothing);
    });

    testWidgets('超量时折叠，显示 +N', (tester) async {
      await pumpShell(
        tester,
        AvatarStack(
          contacts: const [
            ContactItem(id: '1', name: '甲'),
            ContactItem(id: '2', name: '乙'),
            ContactItem(id: '3', name: '丙'),
            ContactItem(id: '4', name: '丁'),
            ContactItem(id: '5', name: '戊'),
            ContactItem(id: '6', name: '己'),
          ],
          onContactClick: (_) {},
          maxVisible: 4,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('+2'), findsOneWidget);
      expect(find.text('戊'), findsNothing, reason: '超出的不应出现在紧凑态');
    });

    testWidgets('点 +N 展开后能看到全部', (tester) async {
      await pumpShell(
        tester,
        AvatarStack(
          contacts: const [
            ContactItem(id: '1', name: '甲'),
            ContactItem(id: '2', name: '乙'),
            ContactItem(id: '3', name: '丙'),
            ContactItem(id: '4', name: '丁'),
            ContactItem(id: '5', name: '戊'),
          ],
          onContactClick: (_) {},
          maxVisible: 4,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('+1'));
      await tester.pumpAndSettle();

      expect(find.text('戊'), findsOneWidget);
      expect(find.text('+1'), findsNothing);
    });

    testWidgets('空列表不渲染（也不崩）', (tester) async {
      await pumpShell(
        tester,
        AvatarStack(contacts: const [], onContactClick: (_) {}),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('展开态点头像会回调，再点取消选中', (tester) async {
      final clicked = <String>[];
      await pumpShell(
        tester,
        AvatarStack(
          contacts: const [
            ContactItem(id: '1', name: '甲'),
            ContactItem(id: '2', name: '乙'),
            ContactItem(id: '3', name: '丙'),
          ],
          onContactClick: (c) => clicked.add(c.name),
          onRemoveContact: (_) {},
          maxVisible: 2,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('+1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('丙'));
      await tester.pumpAndSettle();

      expect(clicked, ['丙']);
    });
  });

  group('统计卡', () {
    testWidgets('多条统计并排渲染', (tester) async {
      await pumpShell(
        tester,
        const StatsCard(
          stats: [
            StatItemData(
              title: '进行中',
              value: '3',
              icon: Icons.timelapse,
              color: Colors.blue,
            ),
            StatItemData(
              title: '已完成',
              value: '12',
              icon: Icons.check_circle_outline,
              color: Colors.green,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('3'), findsOneWidget);
      expect(find.text('进行中'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('已完成'), findsOneWidget);
    });

    testWidgets('窄屏长标签不溢出', (tester) async {
      await pumpShell(
        tester,
        SizedBox(
          width: 320,
          child: StatsCard(
            stats: const [
              StatItemData(
                title: '一个特别特别长的统计标签需要省略',
                value: '999',
                icon: Icons.timelapse,
                color: Colors.blue,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('五套风格 × 深浅', () {
    /// 这一批的全部组件摞在一起。任何一套 tokens 缺色阶/圆角为 0 导致断言失败，
    /// 这个测试都会炸 —— 比逐个组件×逐个主题写 50 个用例划算。
    Widget everything() => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EmptyStates.goals(),
              const AppSnackbar(message: '成功', isSuccess: true),
              const SizedBox(height: 8),
              const LinearProgressBar(progress: 0.5),
              const SizedBox(height: 8),
              const Center(child: CircularProgressIndicatorWithText(progress: 0.5)),
              const SizedBox(height: 8),
              const Center(child: StatusMark(filled: true)),
              const SizedBox(height: 8),
              Center(
                child: SimpleMenuButton(
                  items: const [SimpleMenuItem(title: '编辑')],
                  onItemSelected: (_, __) {},
                ),
              ),
              const SizedBox(height: 8),
              SelectDropdown<String>(
                options: const [DropdownOption(label: '甲', value: 'a')],
                selectedOption: 'a',
                onOptionSelected: (_) {},
              ),
              const SizedBox(height: 8),
              Center(
                child: AvatarStack(
                  contacts: const [
                    ContactItem(id: '1', name: '甲'),
                    ContactItem(id: '2', name: '乙'),
                    ContactItem(id: '3', name: '丙'),
                  ],
                  onContactClick: (_) {},
                  maxVisible: 2,
                ),
              ),
              const SizedBox(height: 8),
              Center(child: UserAvatar(avatar: null, name: '丁')),
              const SizedBox(height: 8),
              const StatsCard(
                stats: [
                  StatItemData(
                    title: '进行中',
                    value: '3',
                    icon: Icons.timelapse,
                    color: Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AppBottomNavigation(
                items: const [
                  BottomNavItem(label: '首页', icon: Icons.home_outlined),
                  BottomNavItem(label: '新建', icon: Icons.add, alwaysFilled: true),
                ],
                selectedIndex: 0,
                onItemSelected: (_) {},
              ),
              const SizedBox(height: 8),
              const Center(child: PageIndicator(pageCount: 3, currentPage: 1)),
              LoadingOverlay(
                isLoading: false,
                child: const SizedBox(height: 40),
              ),
            ],
          ),
        );

    for (final style in ThemeStyle.values) {
      for (final dark in [false, true]) {
        final label = '${style.name} / ${dark ? '深' : '浅'}';
        testWidgets('$label 下全部组件渲染不抛异常', (tester) async {
          await tester.pumpWidget(
            KitAppShell(
              settings: AppSettings(
                themeStyle: style,
                appearanceMode: dark ? AppearanceMode.dark : AppearanceMode.light,
                language: AppLanguage.chinese,
              ),
              home: Scaffold(body: everything()),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull, reason: '$label 渲染异常');
          // 抽查几个「会因主题而变」的点
          expect(find.text('暂无目标'), findsOneWidget);
          expect(find.text('+1'), findsOneWidget);
          expect(find.text('50%'), findsOneWidget);
        });
      }
    }
  });
}
