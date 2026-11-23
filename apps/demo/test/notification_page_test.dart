import 'package:demo/notification_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit/kit.dart';
import 'package:kit/kit_ui.dart';
import 'package:material_ui/material_ui.dart';

/// 通知页：空态 → 有条目 → 点开即已读 → 全部已读。
void main() {
  Future<void> pumpPage(
    WidgetTester tester, {
    required List<AppNotification> notifications,
    ValueChanged<AppNotification>? onOpen,
    VoidCallback? onMarkAll,
  }) async {
    await tester.pumpWidget(
      KitAppShell(
        settings: const AppSettings(language: AppLanguage.chinese),
        home: NotificationPage(
          notifications: notifications,
          onOpen: onOpen ?? (_) {},
          onMarkAll: onMarkAll ?? () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('没有通知时显示空态', (tester) async {
    await pumpPage(tester, notifications: const []);
    expect(find.text('暂无通知'), findsOneWidget);
  });

  testWidgets('有条目时渲染标题，点开回调、全部已读回调都通', (tester) async {
    AppNotification? opened;
    var markedAll = false;
    final n = AppNotification(
      id: '1',
      title: '助手回复完成',
      body: '内容',
      createdAt: DateTime(2026, 11, 19, 12),
    );

    await pumpPage(
      tester,
      notifications: [n],
      onOpen: (x) => opened = x,
      onMarkAll: () => markedAll = true,
    );

    expect(find.text('助手回复完成'), findsOneWidget);
    expect(find.text('内容'), findsOneWidget);

    await tester.tap(find.text('助手回复完成'));
    expect(opened?.id, '1');

    await tester.tap(find.text('全部已读'));
    expect(markedAll, isTrue);
  });
}
