import 'package:chat_demo/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('假运行时下能渲染并回话', (tester) async {
    await tester.pumpWidget(const ChatDemoApp(fake: true));
    await tester.pumpAndSettle();

    // 没有 key 的提示不该出现 —— 假运行时不需要 key
    expect(find.textContaining('没找到 API key'), findsNothing);
    expect(find.text('Chat demo'), findsOneWidget);
  });
}
