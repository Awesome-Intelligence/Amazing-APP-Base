import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit/kit.dart';
import 'package:kit/kit_ui.dart';

/// 日期格式化 / 搜索框 / 骨架屏 / 日历的行为验证。
void main() {
  /// 统一起在中文外壳里：日期与文案都跟着 locale 走，
  /// 不固定的话 `flutter test` 默认 en，断言里写的中文全对不上。
  Future<void> pumpShell(
    WidgetTester tester,
    Widget child, {
    AppSettings settings = const AppSettings(language: AppLanguage.chinese),
  }) {
    return tester.pumpWidget(
      KitAppShell(
        settings: settings,
        home: Scaffold(body: child),
      ),
    );
  }

  /// 日历要给定宽度：测试画布是 800x600，撑满的话每格 100+ 像素、
  /// 六行直接溢出屏幕 —— 真实手机上不会这样。
  Future<void> pumpCalendar(WidgetTester tester, Widget calendar) => pumpShell(
        tester,
        Center(child: SizedBox(width: 360, child: calendar)),
      );

  group('KitDateFormat', () {
    test('中文年月 / 短日期 / 完整日期', () {
      expect(
        KitDateFormat.yearMonth(DateTime(2026, 10), AppLanguage.chinese),
        '2026年10月',
      );
      expect(
        KitDateFormat.shortDate(DateTime(2026, 10, 14), AppLanguage.chinese),
        '10月14日',
      );
      expect(
        KitDateFormat.fullDate(DateTime(2026, 10, 14), AppLanguage.chinese),
        '2026年10月14日',
      );
    });

    test('英文年月 / 短日期 / 完整日期', () {
      expect(
        KitDateFormat.yearMonth(DateTime(2026, 10), AppLanguage.english),
        'October 2026',
      );
      expect(
        KitDateFormat.shortDate(DateTime(2026, 10, 14), AppLanguage.english),
        'Oct 14, 2026',
      );
      expect(
        KitDateFormat.fullDate(DateTime(2026, 10, 14), AppLanguage.english),
        'Oct 14, 2026',
      );
    });

    test('pattern token：补零与非补零、两位年', () {
      final d = DateTime(2026, 3, 5);
      expect(KitDateFormat.format(d, 'yyyy-MM-dd', AppLanguage.chinese), '2026-03-05');
      expect(KitDateFormat.format(d, 'yy/M/d', AppLanguage.chinese), '26/3/5');
      expect(KitDateFormat.format(d, 'MMM', AppLanguage.english), 'Mar');
    });

    test('引号里的字面量原样输出，单引号本身用两个单引号转义', () {
      final d = DateTime(2026, 10, 14);
      expect(KitDateFormat.format(d, "yyyy'年'M'月'", AppLanguage.chinese), '2026年10月');
      expect(KitDateFormat.format(d, "yy''MM", AppLanguage.chinese), "26'10");
    });

    test('星期窄名：周日下标 0，周一 1，周六 6', () {
      // 2026-11-15 是周日
      expect(DateTime(2026, 11, 15).weekday, DateTime.sunday);
      expect(KitDateFormat.weekdayNarrow(DateTime.sunday, AppLanguage.chinese), '日');
      expect(KitDateFormat.weekdayNarrow(DateTime.monday, AppLanguage.chinese), '一');
      expect(KitDateFormat.weekdayNarrow(DateTime.saturday, AppLanguage.chinese), '六');
      expect(KitDateFormat.weekdayNarrow(DateTime.monday, AppLanguage.english), 'M');
    });

    test('表头顺序从周日起', () {
      expect(KitDateFormat.weekColumnOrder, [7, 1, 2, 3, 4, 5, 6]);
    });

    test('system 落中文，与「默认语言是中文」一致', () {
      expect(
        KitDateFormat.yearMonth(DateTime(2026, 10), AppLanguage.system),
        '2026年10月',
      );
    });
  });

  group('formatRelativeTime', () {
    final now = DateTime(2026, 11, 15, 12, 0);

    Future<String> rel(WidgetTester tester, Duration ago) async {
      await pumpShell(tester, const SizedBox());
      final context = tester.element(find.byType(SizedBox).first);
      return formatRelativeTime(
        context,
        now.subtract(ago).millisecondsSinceEpoch,
        now: now,
      );
    }

    testWidgets('刚刚 / 分钟 / 小时 / 天', (tester) async {
      expect(await rel(tester, const Duration(seconds: 20)), '刚刚');
      expect(await rel(tester, const Duration(minutes: 5)), '5 分钟前');
      expect(await rel(tester, const Duration(hours: 3)), '3 小时前');
      expect(await rel(tester, const Duration(days: 2)), '2 天前');
    });

    testWidgets('超过一周回落成短日期', (tester) async {
      expect(await rel(tester, const Duration(days: 10)), '11月5日');
    });
  });

  group('KitSearchBar', () {
    testWidgets('输入触发 onQueryChange', (tester) async {
      String? last;
      await pumpShell(
        tester,
        KitSearchBar(
          query: '',
          onQueryChange: (v) => last = v,
          onSearch: () {},
        ),
      );

      await tester.enterText(find.byType(TextField), '周报');
      expect(last, '周报');
    });

    testWidgets('外部 query 变化会回灌到输入框（受控）', (tester) async {
      var query = '';
      Widget build() => KitAppShell(
            settings: const AppSettings(language: AppLanguage.chinese),
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) => KitSearchBar(
                  query: query,
                  onQueryChange: (v) => setState(() => query = v),
                  onSearch: () {},
                ),
              ),
            ),
          );

      await tester.pumpWidget(build());
      await tester.enterText(find.byType(TextField), '待办');
      await tester.pump();
      expect(find.text('待办'), findsOneWidget);

      // 点清除：外部 query 置空，输入框里的字也要跟着消失
      await tester.tap(find.byTooltip('清除'));
      await tester.pumpAndSettle();
      expect(query, '');
      expect(find.text('待办'), findsNothing);
      // 清空后清除按钮自己也消失
      expect(find.byTooltip('清除'), findsNothing);
    });

    testWidgets('按键盘搜索键触发 onSearch', (tester) async {
      var searches = 0;
      await pumpShell(
        tester,
        KitSearchBar(
          query: '',
          onQueryChange: (_) {},
          onSearch: () => searches++,
        ),
      );

      await tester.enterText(find.byType(TextField), 'x');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(searches, 1);
    });

    testWidgets('筛选按钮：只在传了回调时出现，生效时变主色', (tester) async {
      await pumpShell(
        tester,
        KitSearchBar(
          query: '',
          onQueryChange: (_) {},
          onSearch: () {},
        ),
      );
      expect(find.byIcon(Icons.swap_vert), findsNothing);

      var filterTaps = 0;
      await pumpShell(
        tester,
        KitSearchBar(
          query: '',
          onQueryChange: (_) {},
          onSearch: () {},
          onFilterClick: () => filterTaps++,
          filterActive: true,
        ),
      );
      expect(find.byIcon(Icons.swap_vert), findsOneWidget);

      final tokens = KitTheme.of(tester.element(find.byType(KitSearchBar)));
      final icon = tester.widget<Icon>(find.byIcon(Icons.swap_vert));
      expect(icon.color, tokens.colorScheme.primary);

      await tester.tap(find.byIcon(Icons.swap_vert));
      expect(filterTaps, 1);
    });
  });

  group('Skeleton', () {
    testWidgets('列表骨架屏能渲染且不抛异常', (tester) async {
      await pumpShell(tester, const SkeletonListScreen(itemCount: 3));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(SkeletonGridItem), findsNWidgets(3));
    });

    testWidgets('详情骨架屏能渲染且不抛异常', (tester) async {
      await pumpShell(tester, const SkeletonDetailScreen());
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(SkeletonCard), findsNWidgets(3));
    });

    testWidgets('开了减动效就不脉动（透明度恒定 1）', (tester) async {
      await pumpShell(
        tester,
        const SkeletonTextLine(width: 100),
        settings: const AppSettings(reducedMotion: true),
      );
      await tester.pump();

      double opacity() => tester
          .widget<FadeTransition>(
            find.descendant(
              of: find.byType(SkeletonTextLine),
              matching: find.byType(FadeTransition),
            ),
          )
          .opacity
          .value;

      expect(opacity(), 1.0);
      await tester.pump(const Duration(milliseconds: 400));
      expect(opacity(), 1.0);
    });

    testWidgets('没开减动效时会脉动（透明度会变）', (tester) async {
      await pumpShell(tester, const SkeletonTextLine(width: 100));
      await tester.pump();

      double opacity() => tester
          .widget<FadeTransition>(
            find.descendant(
              of: find.byType(SkeletonTextLine),
              matching: find.byType(FadeTransition),
            ),
          )
          .opacity
          .value;

      final first = opacity();
      await tester.pump(const Duration(milliseconds: 400));
      expect(opacity(), isNot(first));
    });
  });

  group('AppCalendar', () {
    /// 2026-11-01 是周日 → 11 月不需要前补；11 月 30 天，30 % 7 = 2，
    /// 末行补 5 格 → 共 35 格。
    final november15 = DateTime(2026, 11, 15);

    int cellCount(WidgetTester tester) => tester
        .widgetList(find.byWidgetPredicate((w) {
          final key = w.key;
          return key is ValueKey<String> && key.value.startsWith('cal-');
        }))
        .length;

    testWidgets('月视图：35 格，首格本月 1 号，末格补到下月 5 号', (tester) async {
      await pumpCalendar(
        tester,
        AppCalendar(selectedDate: november15),
      );
      await tester.pumpAndSettle();

      expect(find.text('2026年11月'), findsOneWidget);
      expect(cellCount(tester), 35);
      expect(find.byKey(const ValueKey('cal-2026-11-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('cal-2026-11-30')), findsOneWidget);
      expect(find.byKey(const ValueKey('cal-2026-12-5')), findsOneWidget);
      // 补位格不会跨到 12-06
      expect(find.byKey(const ValueKey('cal-2026-12-6')), findsNothing);
      // 11 月只有 30 天
      expect(find.byKey(const ValueKey('cal-2026-11-31')), findsNothing);
    });

    testWidgets('点某天回调该日期', (tester) async {
      DateTime? picked;
      await pumpCalendar(
        tester,
        AppCalendar(
          selectedDate: november15,
          onDateSelected: (d) => picked = d,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('cal-2026-11-3')));
      await tester.pumpAndSettle();

      expect(picked, DateTime(2026, 11, 3));
    });

    testWidgets('翻页只改展示月份，不动选中日期', (tester) async {
      DateTime? picked;
      await pumpCalendar(
        tester,
        AppCalendar(
          selectedDate: november15,
          onDateSelected: (d) => picked = d,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('下个月'));
      await tester.pumpAndSettle();

      expect(find.text('2026年12月'), findsOneWidget);
      expect(picked, isNull, reason: '翻页不该改选中日期');

      await tester.tap(find.byTooltip('上个月'));
      await tester.pumpAndSettle();
      expect(find.text('2026年11月'), findsOneWidget);
    });

    testWidgets('点标题请求切换视图', (tester) async {
      CalendarViewMode? requested;
      await pumpCalendar(
        tester,
        AppCalendar(
          selectedDate: november15,
          viewMode: CalendarViewMode.month,
          onViewModeChange: (m) => requested = m,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('2026年11月'));
      await tester.pumpAndSettle();

      expect(requested, CalendarViewMode.day);
    });

    testWidgets('没给 onViewModeChange 时标题点了没反应', (tester) async {
      await pumpCalendar(tester, AppCalendar(selectedDate: november15));
      await tester.pumpAndSettle();

      await tester.tap(find.text('2026年11月'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('2026年11月'), findsOneWidget);
    });

    testWidgets('周视图：7 格，从周日到周六', (tester) async {
      await pumpCalendar(
        tester,
        AppCalendar(
          selectedDate: november15,
          viewMode: CalendarViewMode.week,
        ),
      );
      await tester.pumpAndSettle();

      expect(cellCount(tester), 7);
      // 11-15 是周日，周视图应从它开始
      expect(find.byKey(const ValueKey('cal-2026-11-15')), findsOneWidget);
      expect(find.byKey(const ValueKey('cal-2026-11-21')), findsOneWidget);
    });

    testWidgets('整周高亮：选中日所在周的其它天用 primaryContainer', (tester) async {
      await pumpCalendar(
        tester,
        AppCalendar(
          selectedDate: november15,
          viewMode: CalendarViewMode.monthWeekHighlight,
          onWeekSelected: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      final tokens = KitTheme.of(tester.element(find.byType(AppCalendar)));

      Color bgOf(String key) => tester
          .widget<Material>(
            find
                .descendant(
                  of: find.byKey(ValueKey(key)),
                  matching: find.byType(Material),
                )
                .first,
          )
          .color!;

      // 选中日本身是 primary
      expect(bgOf('cal-2026-11-15'), tokens.colorScheme.primary);
      // 同一周（11-15 … 11-21）的其它天是 primaryContainer
      expect(bgOf('cal-2026-11-16'), tokens.colorScheme.primaryContainer);
      // 上一周（11-08 … 11-14）不该被点亮
      expect(bgOf('cal-2026-11-9'), isNot(tokens.colorScheme.primaryContainer));
    });

    testWidgets('无障碍：格子读得出「几月几号」与选中状态', (tester) async {
      // 语义树默认不建，不显式开启的话 bySemanticsLabel 什么都找不到。
      final handle = tester.ensureSemantics();
      // 刻意不选「今天」：今天会被追加「，今天」，写死断言就随运行日期挂掉。
      await pumpCalendar(
        tester,
        AppCalendar(selectedDate: DateTime(2026, 11, 10)),
      );
      await tester.pumpAndSettle();

      // 用正则容忍「今天」那段，断言只咬「日期 + 选中」这两件事。
      expect(
        find.bySemanticsLabel(RegExp(r'^11月10日(，今天)?，已选中$')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'^11月3日(，今天)?$')),
        findsOneWidget,
      );

      handle.dispose();
    });
  });
}
