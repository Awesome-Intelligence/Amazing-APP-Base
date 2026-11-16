import 'package:flutter_test/flutter_test.dart';
import 'package:kit/kit.dart' show ThemeStyle;
import 'package:kit/kit_ui.dart';
import 'package:material_ui/material_ui.dart';

/// 「重按当前 tab 回顶部」的联动 —— 关键是**只在 tick 变化时触发**，
/// 首次组合和普通重建都不该跳。
void main() {
  Future<int> pumpWithTick(
    WidgetTester tester,
    int tick,
    Future<void> Function() onScrollToTop,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      KitApp(
        style: ThemeStyle.mono,
        home: Scaffold(
          body: ScrollToTopEffect(
            tick: tick,
            onScrollToTop: () async {
              calls++;
              await onScrollToTop();
            },
          ),
        ),
      ),
    );
    return calls;
  }

  testWidgets('首次组合不触发', (tester) async {
    var hits = 0;
    await pumpWithTick(tester, 0, () async => hits++);
    expect(hits, 0, reason: '第一次挂载不是「重按」，不该回顶');
  });

  testWidgets('tick 变化时触发一次', (tester) async {
    var hits = 0;
    Future<void> onTop() async => hits++;

    await pumpWithTick(tester, 0, onTop);
    await pumpWithTick(tester, 1, onTop);
    expect(hits, 1);

    await pumpWithTick(tester, 2, onTop);
    expect(hits, 2);
  });

  testWidgets('tick 不变的重建不触发', (tester) async {
    var hits = 0;
    Future<void> onTop() async => hits++;

    await pumpWithTick(tester, 5, onTop);
    await pumpWithTick(tester, 5, onTop);
    await pumpWithTick(tester, 5, onTop);
    expect(hits, 0);
  });

  testWidgets('本身不占位置（渲染成零尺寸）', (tester) async {
    await tester.pumpWidget(
      KitApp(
        style: ThemeStyle.mono,
        home: const Scaffold(
          body: Row(
            children: [
              ScrollToTopEffect(tick: 0, onScrollToTop: _noop),
              Text('后面的内容'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('后面的内容'), findsOneWidget);
    final size = tester.getSize(find.byType(ScrollToTopEffect));
    expect(size, Size.zero);
  });

  group('ScrollToTopControllerEffect', () {
    testWidgets('tick 变化时把列表滚回顶部', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      Widget build(int tick) => KitApp(
            style: ThemeStyle.mono,
            home: Scaffold(
              body: Column(
                children: [
                  ScrollToTopControllerEffect(tick: tick, controller: controller),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      controller: controller,
                      itemCount: 60,
                      itemBuilder: (_, i) => SizedBox(height: 40, child: Text('行$i')),
                    ),
                  ),
                ],
              ),
            ),
          );

      await tester.pumpWidget(build(0));
      controller.jumpTo(500);
      expect(controller.offset, greaterThan(0));

      await tester.pumpWidget(build(1));
      await tester.pumpAndSettle();

      expect(controller.offset, 0, reason: '重按当前 tab 应该回到顶部');
    });

    testWidgets('列表还没挂上（没有 client）时不抛异常', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      Widget build(int tick) => KitApp(
            style: ThemeStyle.mono,
            home: Scaffold(
              body: ScrollToTopControllerEffect(tick: tick, controller: controller),
            ),
          );

      await tester.pumpWidget(build(0));
      await tester.pumpWidget(build(1));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}

Future<void> _noop() async {}
