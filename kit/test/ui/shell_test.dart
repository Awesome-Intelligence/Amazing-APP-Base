import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit/kit.dart';
import 'package:kit/kit_ui.dart';

/// 应用骨架的行为验证：外壳主题真的生效、设置页真的能改设置。
void main() {
  group('Header', () {
    Future<void> pumpHeader(WidgetTester tester, Widget header) {
      return tester.pumpWidget(KitApp(home: Scaffold(body: header)));
    }

    testWidgets('渲染标题与左右两侧内容', (tester) async {
      await pumpHeader(
        tester,
        Header(
          title: '待办',
          leading1: IconButton(onPressed: () {}, icon: const Icon(Icons.arrow_back)),
          action1: IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('待办'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('maxChars 按码点截断并补省略号', (tester) async {
      await pumpHeader(tester, const Header(title: '一二三四五六', maxChars: 3));
      await tester.pumpAndSettle();

      expect(find.text('一二三…'), findsOneWidget);
      expect(find.text('一二三四五六'), findsNothing);
    });

    testWidgets('maxChars 不超长时原样显示', (tester) async {
      await pumpHeader(tester, const Header(title: '待办', maxChars: 10));
      await tester.pumpAndSettle();

      expect(find.text('待办'), findsOneWidget);
    });
  });

  group('ToggleRow', () {
    testWidgets('点整行触发回调，传的是取反后的值', (tester) async {
      bool? got;
      await tester.pumpWidget(
        KitApp(
          home: Scaffold(
            body: ToggleRow(
              title: '减动效',
              subtitle: '关掉页面动效',
              isChecked: false,
              onCheckedChange: (v) => got = v,
            ),
          ),
        ),
      );

      await tester.tap(find.text('减动效'));
      await tester.pumpAndSettle();

      expect(got, isTrue);
    });
  });

  group('AppSettingsRow', () {
    testWidgets('显示标题/副标题，点击可点，默认带箭头', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        KitApp(
          home: Scaffold(
            body: AppSettingsRow(
              title: '主题风格',
              subtitle: '单色',
              icon: Icons.palette_outlined,
              onClick: () => taps++,
            ),
          ),
        ),
      );

      expect(find.text('主题风格'), findsOneWidget);
      expect(find.text('单色'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);

      await tester.tap(find.text('主题风格'));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });
  });

  group('SettingsScreen', () {
    /// 把设置页接在真实外壳里，模拟 app 的用法：状态在外壳持有，页面只回调。
    ///
    /// 默认固定成中文：`AppLanguage.system` 会跟测试环境的系统 locale 走
    /// （flutter test 默认 en），不固定的话断言语种就随环境漂。
    Future<AppSettings Function()> pumpSettings(
      WidgetTester tester, {
      AppSettings initial = const AppSettings(language: AppLanguage.chinese),
    }) async {
      var current = initial;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => KitAppShell(
            settings: current,
            home: SettingsScreen(
              settings: current,
              onSettingsChange: (s) => setState(() => current = s),
              onBackClick: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return () => current;
    }

    testWidgets('通用设置三组都在：外观、动效、语言', (tester) async {
      await pumpSettings(tester);

      expect(find.text('设置'), findsOneWidget);
      expect(find.text('外观'), findsOneWidget);
      expect(find.text('主题风格'), findsOneWidget);
      expect(find.text('深浅模式'), findsOneWidget);
      expect(find.text('减动效'), findsOneWidget);
      expect(find.text('界面语言'), findsOneWidget);
    });

    testWidgets('选主题风格 → 回调收到新风格，且只关一层弹窗（回归：以前会连弹两层）', (tester) async {
      final read = await pumpSettings(tester);

      await tester.tap(find.text('主题风格'));
      await tester.pumpAndSettle();
      expect(find.text('瑞士'), findsOneWidget, reason: '弹窗里应该有 Swiss 选项');

      await tester.tap(find.text('瑞士'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确认'));
      await tester.pumpAndSettle();

      expect(read().themeStyle, ThemeStyle.swiss);
      // 弹窗关掉了，但设置页还在 —— 连 pop 两次会把页面一起退掉。
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('瑞士'), findsOneWidget, reason: '副标题应更新为当前风格');
    });

    testWidgets('选深浅模式 → appearanceMode 变 dark，整棵树跟着变深色', (tester) async {
      final read = await pumpSettings(tester);

      await tester.tap(find.text('深浅模式'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('深色').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('确认'));
      await tester.pumpAndSettle();

      expect(read().appearanceMode, AppearanceMode.dark);
      final context = tester.element(find.byType(SettingsScreen));
      expect(Theme.of(context).brightness, Brightness.dark);
      expect(KitTheme.of(context).isDark, isTrue);
    });

    testWidgets('选界面语言 English → 文案切成英文', (tester) async {
      final read = await pumpSettings(tester);

      await tester.tap(find.text('界面语言'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('确认'));
      await tester.pumpAndSettle();

      expect(read().language, AppLanguage.english);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Theme style'), findsOneWidget);
    });

    testWidgets('减动效开关能改设置', (tester) async {
      final read = await pumpSettings(tester);

      await tester.tap(find.text('减动效'));
      await tester.pumpAndSettle();

      expect(read().reducedMotion, isTrue);
    });

    testWidgets('extraSections 插在通用设置下面', (tester) async {
      var current = const AppSettings();
      await tester.pumpWidget(
        KitAppShell(
          settings: current,
          home: SettingsScreen(
            settings: current,
            onSettingsChange: (s) => current = s,
            onBackClick: () {},
            extraSections: const [
              SettingsSectionHeader(title: '账号'),
              SettingsCard(children: [SizedBox(height: 8, key: ValueKey('app-extra'))]),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('账号'), findsOneWidget);
      expect(find.byKey(const ValueKey('app-extra')), findsOneWidget);
    });
  });

  group('KitAppShell', () {
    Future<void> pumpShell(WidgetTester tester, AppSettings settings) {
      return tester.pumpWidget(
        KitAppShell(
          settings: settings,
          home: const Scaffold(body: Center(child: Text('内容'))),
        ),
      );
    }

    testWidgets('5 套风格都能落到 KitTheme', (tester) async {
      for (final style in ThemeStyle.values) {
        await pumpShell(tester, AppSettings(themeStyle: style));
        await tester.pumpAndSettle();

        final context = tester.element(find.text('内容'));
        expect(KitTheme.of(context).themeStyle, style, reason: '$style 未生效');
      }
    });

    testWidgets('appearanceMode 决定实际深浅', (tester) async {
      for (final mode in [AppearanceMode.light, AppearanceMode.dark]) {
        await pumpShell(tester, AppSettings(appearanceMode: mode));
        await tester.pumpAndSettle();

        final context = tester.element(find.text('内容'));
        final expected = mode == AppearanceMode.dark;
        expect(KitTheme.of(context).isDark, expected, reason: '$mode 未生效');
        expect(Theme.of(context).brightness,
            expected ? Brightness.dark : Brightness.light);
      }
    });

    testWidgets('reducedMotion 透传到主题作用域', (tester) async {
      await pumpShell(tester, const AppSettings(reducedMotion: true));
      await tester.pumpAndSettle();

      final context = tester.element(find.text('内容'));
      expect(KitTheme.reducedMotionOf(context), isTrue);
    });

    testWidgets('语言切换到英文后 KitStrings 也跟着切', (tester) async {
      await pumpShell(tester, const AppSettings(language: AppLanguage.english));
      await tester.pumpAndSettle();

      final context = tester.element(find.text('内容'));
      expect(KitStringsScope.of(context), KitStrings.english);
      expect(KitStringsScope.of(context).cancel, 'Cancel');
    });
  });
}
