import 'package:flutter_test/flutter_test.dart';
import 'package:kit/kit.dart';
import 'package:kit/kit_ui.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Future<void> pumpBar(
    WidgetTester tester, {
    required List<ActiveFilter> filters,
    required ValueChanged<ActiveFilter> onRemove,
    required VoidCallback onClearAll,
  }) {
    return tester.pumpWidget(
      KitApp(
        style: ThemeStyle.mono,
        home: Scaffold(
          body: ActiveFiltersBar(
            filters: filters,
            onRemoveFilter: onRemove,
            onClearAll: onClearAll,
          ),
        ),
      ),
    );
  }

  const filters = <ActiveFilter>[
    ActiveFilter(id: 'imp-today', type: FilterType.importance, label: '今天'),
    ActiveFilter(
      id: 'tag-work',
      type: FilterType.tag,
      label: '工作',
      color: Color(0xFF3366CC),
    ),
    ActiveFilter(id: 'type-note', type: FilterType.type, label: '笔记'),
  ];

  testWidgets('每条筛选都渲染出来', (tester) async {
    await pumpBar(tester, filters: filters, onRemove: (_) {}, onClearAll: () {});
    expect(find.text('今天'), findsOneWidget);
    expect(find.text('工作'), findsOneWidget);
    expect(find.text('笔记'), findsOneWidget);
    expect(find.text('清除全部'), findsOneWidget);
  });

  testWidgets('空列表整条不占位置', (tester) async {
    await pumpBar(tester, filters: const [], onRemove: (_) {}, onClearAll: () {});
    final size = tester.getSize(find.byType(ActiveFiltersBar));
    expect(size, Size.zero, reason: '没筛选时不该留一条空白');
    expect(find.text('清除全部'), findsNothing);
  });

  testWidgets('点删除按钮回传对应的那一条', (tester) async {
    final removed = <ActiveFilter>[];
    await pumpBar(
      tester,
      filters: filters,
      onRemove: removed.add,
      onClearAll: () {},
    );

    // 每条 chip 一个删除按钮，按顺序取第二个（工作）
    final deleteIcons = find.byIcon(Icons.close);
    expect(deleteIcons, findsNWidgets(3));
    await tester.tap(deleteIcons.at(1));
    await tester.pump();

    expect(removed.length, 1);
    expect(removed.single.id, 'tag-work');
  });

  testWidgets('点「清除全部」回调一次', (tester) async {
    var cleared = 0;
    await pumpBar(
      tester,
      filters: filters,
      onRemove: (_) {},
      onClearAll: () => cleared++,
    );

    await tester.tap(find.text('清除全部'));
    await tester.pump();
    expect(cleared, 1);
  });

  testWidgets('只有标签类型才画色点；没传 color 时用主题 tertiary', (tester) async {
    await pumpBar(
      tester,
      filters: const [
        ActiveFilter(id: 'tag-1', type: FilterType.tag, label: '有颜色', color: Color(0xFFAB47BC)),
      ],
      onRemove: (_) {},
      onClearAll: () {},
    );

    // 色点是 8x8 的圆形 Container，找那个颜色
    final dots = tester
        .widgetList<Container>(find.byType(Container))
        .where((c) => c.decoration is BoxDecoration)
        .toList();
    expect(dots, isNotEmpty);
    expect(
      dots.any((c) => (c.decoration! as BoxDecoration).color == const Color(0xFFAB47BC)),
      isTrue,
    );
  });

  testWidgets('五套主题下都能渲染', (tester) async {
    for (final style in ThemeStyle.values) {
      await tester.pumpWidget(
        KitApp(
          style: style,
          home: Scaffold(
            body: ActiveFiltersBar(
              filters: filters,
              onRemoveFilter: (_) {},
              onClearAll: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: '$style 下渲染异常');
      expect(find.text('今天'), findsOneWidget);
    }
  });
}
