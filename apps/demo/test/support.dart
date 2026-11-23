import 'package:demo/demo_store.dart';
import 'package:demo/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit/kit.dart' show AppLanguage, AppSettings;

/// 起一个完整的 demo app（带路由），返回它的 store。
///
/// 语言固定中文：`AppLanguage.system` 会跟测试环境 locale 走
/// （flutter test 默认 en），不固定的话断言的文案会随环境变。
Future<DemoStore> pumpDemoApp(
  WidgetTester tester, {
  AppSettings settings = const AppSettings(language: AppLanguage.chinese),
}) async {
  final store = DemoStore(initialSettings: settings);
  await tester.pumpWidget(DemoApp(store: store));
  await tester.pumpAndSettle();
  return store;
}
