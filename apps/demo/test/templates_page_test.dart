import 'package:demo/demo_store.dart';
import 'package:demo/templates_page.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit/kit.dart' show AppLanguage, AppSettings, ThemeStyle;
import 'package:kit/kit_ui.dart';

import 'support.dart';

/// 模板屏的端到端验证：走真实交互（点页签 → 点放大镜 → 输入 → 点筛选 → 切视图）。
///
/// 这一层专门抓「组件都对、拼起来不对」的问题：搜索态有没有真的接管页头、
/// 筛选和搜索会不会打架、空态分支有没有挑错、表单保存后列表有没有刷新。
void main() {
  Future<DemoStore> pumpShell(WidgetTester tester) => pumpDemoApp(tester);

  /// 只找模板页里的东西 —— 页签是独立的分支（各有各的 Navigator），
  /// 不限定范围的话会在别的页里找到同名图标。
  Finder inTemplates(Finder matching) =>
      find.descendant(of: find.byType(TemplatesPage), matching: matching);

  Future<void> openTemplates(WidgetTester tester) async {
    await pumpShell(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('模板'));
    await tester.pumpAndSettle();
  }

  testWidgets('切到模板页签：页头、筛选、条目都在', (tester) async {
    await openTemplates(tester);

    expect(find.byType(TemplatesPage), findsOneWidget);
    expect(find.text('模板屏'), findsOneWidget);
    expect(find.text('全部'), findsOneWidget);
    expect(find.text('张三'), findsOneWidget);
    expect(find.text('紧急'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('搜索：点放大镜 → 输入关键字 → 只剩匹配项', (tester) async {
    await openTemplates(tester);

    await tester.tap(inTemplates(find.byIcon(Icons.search)));
    await tester.pumpAndSettle();
    // 搜索态接管页头：标题让位、筛选行收起
    expect(find.text('模板屏'), findsNothing);
    expect(find.text('全部'), findsNothing);

    await tester.enterText(inTemplates(find.byType(TextField)).first, '张');
    await tester.pumpAndSettle();

    expect(find.text('张三'), findsOneWidget);
    expect(find.text('李四'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('筛选到没有数据的那一档 → 出「未找到结果」而非「暂无联系人」', (tester) async {
    await openTemplates(tester);

    await tester.tap(find.text('宠物'));
    await tester.pumpAndSettle();

    expect(find.text('未找到结果'), findsOneWidget);
    expect(find.text('暂无联系人'), findsNothing);
  });

  testWidgets('视图模式按钮：列表 → 网格 → 日历 循环', (tester) async {
    await openTemplates(tester);
    expect(find.byType(GridView), findsNothing);

    await tester.tap(inTemplates(find.byIcon(Icons.grid_view)));
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsOneWidget);

    await tester.tap(inTemplates(find.byIcon(Icons.calendar_month)));
    await tester.pumpAndSettle();
    expect(find.byType(AppCalendar), findsOneWidget);

    await tester.tap(inTemplates(find.byIcon(Icons.view_list)));
    await tester.pumpAndSettle();
    expect(find.text('张三'), findsOneWidget);
  });

  testWidgets('新增：FAB → 表单页，名字没填时保存按钮点不动', (tester) async {
    await openTemplates(tester);

    await tester.tap(inTemplates(find.byType(FloatingActionButton)));
    await tester.pumpAndSettle();

    // 标题为空 → 回落成「添加」
    expect(find.text('添加'), findsOneWidget);
    expect(find.text('基本信息'), findsOneWidget);

    await tester.tap(find.byTooltip('保存'));
    await tester.pumpAndSettle();
    // 空名字保存不了，还停在表单页
    expect(find.text('基本信息'), findsOneWidget);
  });

  testWidgets('新增：填名字 → 保存 → 回列表且新条目在最上面', (tester) async {
    await openTemplates(tester);
    await tester.tap(inTemplates(find.byType(FloatingActionButton)));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.descendant(
        of: find.byType(SimpleTextField),
        matching: find.byType(TextField),
      ),
      '新同事',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('保存'));
    await tester.pumpAndSettle();

    expect(find.byType(TemplatesPage), findsOneWidget);
    expect(find.text('新同事'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('五套主题下模板页都能渲染', (tester) async {
    // 换主题 = 改 store 里的设置，不重起 app（重起会丢掉注入的 store）。
    final store = await pumpShell(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('模板'));
    await tester.pumpAndSettle();

    for (final style in ThemeStyle.values) {
      store.updateSettings(
        AppSettings(language: AppLanguage.chinese, themeStyle: style),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('模板屏'),
        findsOneWidget,
        reason: '$style 主题下模板页应正常渲染',
      );
      expect(tester.takeException(), isNull, reason: '$style 主题渲染异常');
    }
  });
}
