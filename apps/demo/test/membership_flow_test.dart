import 'package:demo/home_shell.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit/kit.dart' show AppLanguage, AppSettings;
import 'package:kit/kit_ui.dart';

/// 付费流程的端到端验证：页头「升级」→ 升级面板 → 买一单 → 档位和额度真的变。
///
/// 走的是真实路径（真实 `MembershipManager` + 假商店 `DemoBilling`），
/// 只把「平台支付通道」换成假的 —— 这和真机的差别只在网络那一段。
void main() {
  Future<void> pumpShell(WidgetTester tester) {
    const settings = AppSettings(language: AppLanguage.chinese);
    return tester.pumpWidget(
      KitAppShell(
        settings: settings,
        home: HomeShell(settings: settings, onSettingsChange: (_) {}),
      ),
    );
  }

  /// 假商店有两处 `Future.delayed(300ms)`，pump 到足够长再 settle。
  Future<void> settlePurchase(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  Future<void> openUpgrade(WidgetTester tester) async {
    await tester.tap(find.text('升级'));
    await tester.pumpAndSettle();
  }

  testWidgets('点「升级」弹出档位面板，价格来自商店而不是本地拼的', (tester) async {
    await pumpShell(tester);
    await tester.pumpAndSettle();
    await openUpgrade(tester);

    expect(find.byType(UpgradeSheet), findsOneWidget);
    expect(find.text('高级版'), findsOneWidget);
    expect(find.text('¥28 / 月'), findsOneWidget);
    expect(find.text('专业版'), findsOneWidget);
    expect(find.text('¥68 / 月'), findsOneWidget);
    // 免费档没有商品，不该出现在升级页里
    expect(find.text('免费版'), findsNothing);
  });

  testWidgets('买高级版：面板关闭、档位变高级、额度涨到 100', (tester) async {
    await pumpShell(tester);
    await tester.pumpAndSettle();
    expect(find.textContaining('免费版'), findsOneWidget);

    await openUpgrade(tester);
    // 两个档位都能买，点第一个（高级版）
    await tester.tap(find.text('购买').first);
    await settlePurchase(tester);

    expect(find.byType(UpgradeSheet), findsNothing, reason: '买完面板应收起');
    expect(find.textContaining('高级版'), findsWidgets, reason: '页头档位应更新');
    expect(find.textContaining('剩 100 次'), findsOneWidget);
    expect(find.textContaining('已开通 高级版'), findsOneWidget);
    expect(find.textContaining('已解锁导出'), findsOneWidget);
  });

  testWidgets('再打开面板时已买档位显示「当前方案」且点不动', (tester) async {
    await pumpShell(tester);
    await tester.pumpAndSettle();
    await openUpgrade(tester);
    await tester.tap(find.text('购买').first);
    await settlePurchase(tester);

    // 此时页头按钮从「升级」变成「档位」
    await tester.tap(find.text('档位'));
    await tester.pumpAndSettle();

    expect(find.byType(UpgradeSheet), findsOneWidget);
    expect(find.text('当前方案'), findsOneWidget);
    // 专业版仍可买
    expect(find.text('购买'), findsOneWidget);

    await tester.tap(find.text('当前方案'), warnIfMissed: false);
    await settlePurchase(tester);
    // 点当前方案不会关面板，也不会再买一次 —— 聊天里那条「已开通」还是**一**条。
    // 重买会多出一条，所以数量本身就是断言。
    expect(find.byType(UpgradeSheet), findsOneWidget);
    expect(find.textContaining('已开通'), findsOneWidget);
  });

  testWidgets('没买过时恢复购买走失败分支，原因说清楚', (tester) async {
    await pumpShell(tester);
    await tester.pumpAndSettle();
    await openUpgrade(tester);

    await tester.tap(find.text('恢复购买'));
    await settlePurchase(tester);

    expect(find.byType(UpgradeSheet), findsNothing);
    expect(find.textContaining('恢复失败'), findsOneWidget);
    expect(find.textContaining('没有可恢复的购买'), findsOneWidget);
    expect(find.textContaining('免费版'), findsOneWidget, reason: '失败不该改档位');
  });

  testWidgets('买过之后恢复购买能把档位拿回来', (tester) async {
    await pumpShell(tester);
    await tester.pumpAndSettle();
    await openUpgrade(tester);
    await tester.tap(find.text('购买').first);
    await settlePurchase(tester);

    await tester.tap(find.text('档位'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('恢复购买'));
    await settlePurchase(tester);

    expect(find.textContaining('已恢复购买：高级版'), findsOneWidget);
  });
}
