import 'package:demo/demo_store.dart';
import 'package:demo/gallery_page.dart';
import 'package:demo/main.dart';
import 'package:demo/todo_chat_page.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit/kit.dart' show AppLanguage, AppSettings, ThemeStyle;
import 'package:kit/kit_ui.dart';

import 'support.dart';

/// demo 页面级验证：不连模型，只看「页面能不能起来、主题能不能切」。
///
/// 这一层能抓到主题组合导致的崩溃（比如某套 tokens 的 textTheme 缺槽位、
/// 圆角为 0 时 shape 断言失败），比只跑 `flutter build` 更接近真实运行。
void main() {
  /// 用固定中文的 shell 起页面：`AppLanguage.system` 会跟测试环境 locale 走
  /// （flutter test 默认 en），不固定的话断言的文案会随环境变。
  Future<DemoStore> pumpShell(
    WidgetTester tester, {
    AppSettings settings = const AppSettings(language: AppLanguage.chinese),
  }) => pumpDemoApp(tester, settings: settings);

  testWidgets('demo 首屏渲染：标题 / 档位 / 输入区都在', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.pumpAndSettle();

    expect(find.text('待办助手'), findsOneWidget);
    expect(find.textContaining('免费版'), findsOneWidget);
    expect(find.text('删最后一个'), findsOneWidget);
    expect(find.text('说点什么…'), findsOneWidget);
    expect(find.byIcon(Icons.send), findsOneWidget);
  });

  testWidgets('五套主题风格都能渲染且不抛异常', (tester) async {
    // 换主题 = 改 store 里的设置（app 根监听着），不是重起一个 app：
    // 重起会造第二个 DemoApp，Flutter 复用同一个 State，注入的 store 就丢了。
    final store = await pumpShell(tester);
    for (final style in ThemeStyle.values) {
      store.updateSettings(AppSettings(themeStyle: style));
      await tester.pumpAndSettle();

      expect(
        find.text('待办助手'),
        findsOneWidget,
        reason: '$style 主题下页面应正常渲染',
      );
      expect(tester.takeException(), isNull, reason: '$style 主题渲染异常');
      expect(KitTheme.of(tester.element(find.byType(TodoChatPage))).themeStyle, style);
    }
  });

  testWidgets('从设置页切主题：Mono 圆角 → Swiss 直角，返回后仍然生效', (tester) async {
    final store = await pumpShell(tester);
    await tester.pumpAndSettle();

    ThemeTokens tokensNow() =>
        KitTheme.of(tester.element(find.byType(TodoChatPage)));

    expect(tokensNow().themeStyle, ThemeStyle.mono);
    expect(tokensNow().cornerStyle, CornerStyle.rounded);

    // 页头「设置」→ 设置页 → 主题风格 → 瑞士 → 确认
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('主题风格'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('瑞士'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认'));
    await tester.pumpAndSettle();

    expect(store.settings.themeStyle, ThemeStyle.swiss);

    // 返回列表页，风格仍然生效（状态在根上，不是设置页自己的）
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(tokensNow().themeStyle, ThemeStyle.swiss);
    expect(tokensNow().cornerStyle, CornerStyle.square);
    expect(tokensNow().shapes.medium.topLeft.x, 0, reason: 'Swiss 应把圆角归零');
  });

  testWidgets('从设置页切深色：配色真的换掉', (tester) async {
    await pumpShell(tester);
    await tester.pumpAndSettle();

    Color surfaceNow() =>
        KitTheme.of(tester.element(find.byType(TodoChatPage))).colorScheme.surface;

    final lightSurface = surfaceNow();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('深浅模式'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('深色'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(surfaceNow(), isNot(lightSurface), reason: '切深色后底色应变化');
    expect(KitTheme.of(tester.element(find.byType(TodoChatPage))).isDark, isTrue);
  });

  testWidgets('切英文：页头与设置页文案都变英文', (tester) async {
    await pumpShell(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('界面语言'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认'));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
  });

  testWidgets('添加待办：走 InputDialog，确认后列表和聊天都出现', (tester) async {
    // 走固定中文的 shell：弹窗按钮文案来自 KitStrings，
    // 跟系统 locale 走会让断言随环境漂。
    await pumpShell(tester);
    await tester.pumpAndSettle();

    expect(find.text('0 条'), findsOneWidget);

    await tester.tap(find.text('添加待办'));
    await tester.pumpAndSettle();
    expect(find.text('例如：周五交周报'), findsOneWidget);

    await tester.enterText(
      find.descendant(of: find.byType(InputDialog), matching: find.byType(TextField)),
      '周五交周报',
    );
    await tester.pump();
    await tester.tap(find.text('确认'));
    await tester.pumpAndSettle();

    // 列表条目（AppListItem）与聊天系统消息都来自同一个 store
    expect(find.text('周五交周报'), findsOneWidget);
    expect(find.text('已添加：周五交周报'), findsOneWidget);
    expect(find.text('1 条'), findsOneWidget);
  });

  testWidgets('删单条：DeleteConfirmDialog 确认后条目消失', (tester) async {
    await pumpShell(tester);
    await tester.pumpAndSettle();

    // 先加一条
    await tester.tap(find.text('添加待办'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(of: find.byType(InputDialog), matching: find.byType(TextField)),
      '买牛奶',
    );
    await tester.tap(find.text('确认'));
    await tester.pumpAndSettle();
    expect(find.text('买牛奶'), findsOneWidget);

    // 取消不删
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('确认删除'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.text('买牛奶'), findsOneWidget, reason: '取消后不该删');

    // 确认才删
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    expect(find.text('买牛奶'), findsNothing);
    expect(find.text('0 条'), findsOneWidget);
  });

  testWidgets('输入条用 ComposerField，文字能进到框里', (tester) async {
    await pumpShell(tester);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.descendant(
        of: find.byType(ComposerField),
        matching: find.byType(TextField),
      ),
      '今天有什么安排',
    );
    await tester.pump();
    expect(find.text('今天有什么安排'), findsOneWidget);
  });

  testWidgets('组件目录页：切过去能看到各分组', (tester) async {
    await pumpShell(tester);
    await tester.pumpAndSettle();

    // 首屏是待办页，组件页还没构建
    expect(find.byType(TodoChatPage), findsOneWidget);
    expect(find.byType(GalleryPage), findsNothing);

    await tester.tap(find.text('组件'));
    // 组件页里有骨架屏（无限循环的呼吸动画），不能 pumpAndSettle ——
    // 永远等不到「静止」那一帧。
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(GalleryPage), findsOneWidget);
    expect(find.text('组件目录'), findsOneWidget);
    // 只断言首屏可见的分组：ListView 是懒加载，下面的「日历」「骨架屏」
    // 还没被构建出来，断言它们存在只会得到一个假的失败。
    expect(find.text('按钮'), findsOneWidget);
    expect(find.text('卡片'), findsOneWidget);

    // 往下滚，逐个确认新增分组真的能构建出来（懒加载不滚就没有）。
    for (final title in const [
      '空状态',
      '反馈与进度',
      '菜单与下拉',
      '头像',
      '统计卡',
      '底部导航 + 分页指示器',
      '会员',
    ]) {
      await tester.scrollUntilVisible(
        find.text(title),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(title), findsOneWidget, reason: '分组「$title」应能滚到');
      expect(tester.takeException(), isNull, reason: '分组「$title」渲染异常');
    }
    expect(tester.takeException(), isNull);
  });
}
