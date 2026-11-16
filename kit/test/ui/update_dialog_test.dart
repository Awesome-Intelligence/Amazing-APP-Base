import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit/kit.dart';
import 'package:kit/kit_ui.dart';

/// 更新弹窗的行为验证 —— 不只是「能渲染」，而是三种闸门分支都对：
/// 可关闭 / 强制不可关闭 / 没下载地址时按钮灰掉。
void main() {
  Future<void> pumpInApp(WidgetTester tester, Widget child) {
    return tester.pumpWidget(
      KitApp(style: ThemeStyle.mono, home: Scaffold(body: child)),
    );
  }

  UpdateDialog buildDialog({
    bool mandatory = false,
    bool updateEnabled = true,
    VoidCallback? onSkip,
    VoidCallback? onUpdate,
    VoidCallback? onLater,
    String notes = '- 修复登录闪退\n- 新增深色模式',
  }) {
    return UpdateDialog(
      latestVersion: '1.4.0',
      currentVersion: '1.2.0',
      releaseNotes: notes,
      mandatory: mandatory,
      updateEnabled: updateEnabled,
      onUpdate: onUpdate ?? () {},
      onLater: onLater ?? () {},
      onSkipVersion: onSkip,
    );
  }

  group('非强制更新', () {
    testWidgets('标题、版本行、更新内容、三个按钮都在', (tester) async {
      await pumpInApp(tester, buildDialog(onSkip: () {}));

      expect(find.text('发现新版本'), findsOneWidget);
      expect(find.text('当前 1.2.0 → 最新 1.4.0'), findsOneWidget);
      expect(find.text('更新内容'), findsOneWidget);
      expect(find.textContaining('新增深色模式'), findsOneWidget);
      expect(find.text('立即更新'), findsOneWidget);
      expect(find.text('稍后'), findsOneWidget);
      expect(find.text('跳过此版本'), findsOneWidget);
      // 非强制不该出现强制更新的警告文案
      expect(find.text('当前版本已不再支持，请更新后继续使用。'), findsNothing);
    });

    testWidgets('没给 onSkipVersion 就不显示跳过按钮', (tester) async {
      await pumpInApp(tester, buildDialog());
      expect(find.text('跳过此版本'), findsNothing);
      expect(find.text('稍后'), findsOneWidget);
    });

    testWidgets('没有更新说明时不渲染「更新内容」标题', (tester) async {
      await pumpInApp(tester, buildDialog(notes: '   '));
      expect(find.text('更新内容'), findsNothing);
    });

    testWidgets('点三个按钮各自回调一次', (tester) async {
      var updates = 0;
      var laters = 0;
      var skips = 0;
      await pumpInApp(
        tester,
        buildDialog(
          onUpdate: () => updates++,
          onLater: () => laters++,
          onSkip: () => skips++,
        ),
      );

      await tester.tap(find.text('立即更新'));
      await tester.tap(find.text('稍后'));
      await tester.tap(find.text('跳过此版本'));
      await tester.pump();

      expect(updates, 1);
      expect(laters, 1);
      expect(skips, 1);
    });
  });

  group('强制更新', () {
    testWidgets('只留更新按钮，没有稍后/跳过', (tester) async {
      await pumpInApp(tester, buildDialog(mandatory: true, onSkip: () {}));

      expect(find.text('需要更新'), findsOneWidget);
      expect(find.text('当前版本已不再支持，请更新后继续使用。'), findsOneWidget);
      expect(find.text('立即更新'), findsOneWidget);
      expect(find.text('稍后'), findsNothing);
      expect(find.text('跳过此版本'), findsNothing);
    });

    testWidgets('强制时即使传了 onSkipVersion 也不显示', (tester) async {
      await pumpInApp(tester, buildDialog(mandatory: true, onSkip: () {}));
      expect(find.text('跳过此版本'), findsNothing);
    });
  });

  group('下载地址没配', () {
    testWidgets('更新按钮灰掉，点了不回调', (tester) async {
      var updates = 0;
      await pumpInApp(
        tester,
        buildDialog(updateEnabled: false, onUpdate: () => updates++),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton).first);
      expect(button.onPressed, isNull, reason: '灰掉的按钮不该有回调');

      await tester.tap(find.text('立即更新'), warnIfMissed: false);
      await tester.pump();
      expect(updates, 0);
    });
  });

  group('UpdateDialog.show', () {
    testWidgets('点「立即更新」返回 UpdateChoice.update', (tester) async {
      UpdateChoice? choice;
      await tester.pumpWidget(
        KitApp(
          style: ThemeStyle.mono,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  choice = await UpdateDialog.show(
                    context,
                    latestVersion: '1.4.0',
                    currentVersion: '1.2.0',
                    releaseNotes: '- 修复',
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('发现新版本'), findsOneWidget);

      await tester.tap(find.text('立即更新'));
      await tester.pumpAndSettle();
      expect(choice, UpdateChoice.update);
      expect(find.text('发现新版本'), findsNothing, reason: '选完应该关掉');
    });

    testWidgets('点「跳过此版本」返回 UpdateChoice.skip', (tester) async {
      UpdateChoice? choice;
      await tester.pumpWidget(
        KitApp(
          style: ThemeStyle.mono,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  choice = await UpdateDialog.show(
                    context,
                    latestVersion: '1.4.0',
                    currentVersion: '1.2.0',
                    releaseNotes: '',
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('跳过此版本'));
      await tester.pumpAndSettle();
      expect(choice, UpdateChoice.skip);
    });

    testWidgets('allowSkip=false 时没有跳过按钮', (tester) async {
      await tester.pumpWidget(
        KitApp(
          style: ThemeStyle.mono,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => UpdateDialog.show(
                  context,
                  latestVersion: '1.4.0',
                  currentVersion: '1.2.0',
                  releaseNotes: '',
                  allowSkip: false,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('跳过此版本'), findsNothing);
      expect(find.text('稍后'), findsOneWidget);
    });

    testWidgets('强制更新时点外部关不掉', (tester) async {
      await tester.pumpWidget(
        KitApp(
          style: ThemeStyle.mono,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => UpdateDialog.show(
                  context,
                  latestVersion: '1.4.0',
                  currentVersion: '1.2.0',
                  releaseNotes: '',
                  mandatory: true,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // 点左上角（弹窗外的遮罩）
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(find.text('需要更新'), findsOneWidget, reason: '强制更新不该被点外部关掉');
    });
  });
}
