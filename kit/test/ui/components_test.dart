import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit/kit.dart';
import 'package:kit/kit_ui.dart';

/// 组件行为验证 —— 不只是「能编译」，而是**真的被 pump 出来、点了有反应**。
void main() {
  Future<void> pumpInApp(WidgetTester tester, Widget child, {ThemeStyle style = ThemeStyle.mono}) {
    return tester.pumpWidget(
      KitApp(
        style: style,
        home: Scaffold(body: child),
      ),
    );
  }

  group('ChatMessageList', () {
    const messages = <ChatMessage>[
      ChatMessage.user('我今天有几件事？'),
      ChatMessage.assistant(
        text: '你有 3 件待办，其中 1 件今天到期。',
        steps: [
          ChatStep(tool: 'list_todos', args: '{}', status: ChatStepStatus.done, result: '共 3 条'),
          ChatStep(tool: 'add_todo', args: '{"title":"买牛奶"}'),
        ],
      ),
      ChatMessage.error('网络断了'),
    ];

    testWidgets('用户/助手/错误三种消息都能渲染', (tester) async {
      await pumpInApp(tester, const ChatMessageList(messages: messages));
      await tester.pumpAndSettle();

      expect(find.text('我今天有几件事？'), findsOneWidget);
      expect(find.text('你有 3 件待办，其中 1 件今天到期。'), findsOneWidget);
      // 错误前缀是组件加的
      expect(find.text('⚠️ 网络断了'), findsOneWidget);
    });

    testWidgets('过程默认折叠成一行，点击后展开每一步', (tester) async {
      await pumpInApp(tester, const ChatMessageList(messages: messages));
      await tester.pumpAndSettle();

      // 折叠态：只说「过程 2 步」，看不到工具名
      expect(find.text('过程 2 步'), findsOneWidget);
      expect(find.text('list_todos'), findsNothing);

      await tester.tap(find.text('过程 2 步'));
      await tester.pumpAndSettle();

      // 展开态：工具名 + 参数 + 结果都在
      expect(find.text('list_todos'), findsOneWidget);
      expect(find.text('add_todo'), findsOneWidget);
      expect(find.text('共 3 条'), findsOneWidget);
      expect(find.textContaining('买牛奶'), findsOneWidget);

      // 状态文案按状态分发（done / running）
      expect(find.text(' · 完成'), findsOneWidget);
      expect(find.text(' · 进行中'), findsOneWidget);
    });

    testWidgets('流式追加文本会更新气泡（打字机语义）', (tester) async {
      var msg = const ChatMessage.assistant(text: '你');
      await pumpInApp(tester, ChatMessageList(messages: [msg]));
      await tester.pumpAndSettle();
      expect(find.text('你'), findsOneWidget);

      msg = (msg as ChatMessageAssistant).appendText('好');
      await pumpInApp(tester, ChatMessageList(messages: [msg]));
      await tester.pumpAndSettle();
      expect(find.text('你好'), findsOneWidget);
      expect(find.text('你'), findsNothing);
    });
  });

  group('ToolApprovalCard', () {
    testWidgets('三个动作各自触发对应回调', (tester) async {
      var deny = 0, always = 0, once = 0;
      await pumpInApp(
        tester,
        Center(
          child: ToolApprovalCard(
            tool: 'delete_todo',
            args: '{"id":"42"}',
            risk: '删除后无法恢复',
            onDeny: () => deny++,
            onAllowAlways: () => always++,
            onAllowOnce: () => once++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 参数与风险说明要可见（这正是用「卡」不用「对话框」的理由）
      expect(find.text('需要你确认'), findsOneWidget);
      expect(find.text('delete_todo'), findsOneWidget);
      expect(find.text('{"id":"42"}'), findsOneWidget);
      expect(find.text('删除后无法恢复'), findsOneWidget);

      await tester.tap(find.text('允许一次'));
      await tester.tap(find.text('本任务免确认'));
      await tester.tap(find.text('拒绝'));
      await tester.pumpAndSettle();

      expect(once, 1);
      expect(always, 1);
      expect(deny, 1);
    });

    testWidgets('自定义标题与空参数', (tester) async {
      await pumpInApp(
        tester,
        ToolApprovalCard(
          tool: 'clear_all',
          title: '危险操作',
          onDeny: () {},
          onAllowAlways: () {},
          onAllowOnce: () {},
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('危险操作'), findsOneWidget);
      expect(find.text('需要你确认'), findsNothing);
    });
  });

  group('按钮', () {
    testWidgets('PrimaryButton 可点，禁用时不触发', (tester) async {
      var taps = 0;
      await pumpInApp(
        tester,
        Column(
          children: [
            PrimaryButton(text: '保存', onPressed: () => taps++),
            const PrimaryButton(text: '禁用', onPressed: null, enabled: false),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('保存'));
      expect(taps, 1);

      await tester.tap(find.text('禁用'));
      expect(taps, 1, reason: '禁用的按钮不应触发回调');
    });

    testWidgets('Swiss 主题下卡片变白底、控件圆角归零', (tester) async {
      await pumpInApp(
        tester,
        const Column(
          children: [
            AppCard(child: Text('卡片内容')),
            SecondaryButton(text: '次级', onPressed: null),
          ],
        ),
        style: ThemeStyle.swiss,
      );
      await tester.pumpAndSettle();

      expect(find.text('卡片内容'), findsOneWidget);
      // Swiss 全直角
      final material = tester.widget<Material>(
        find.ancestor(of: find.text('卡片内容'), matching: find.byType(Material)).first,
      );
      final shape = material.shape! as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.zero);
    });
  });

  group('AppCard / CardTitle', () {
    testWidgets('可点卡片触发 onTap，标题渲染图标与文字', (tester) async {
      var taps = 0;
      await pumpInApp(
        tester,
        AppCard(
          onTap: () => taps++,
          child: const CardTitle(icon: Icons.check, title: '今日待办'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('今日待办'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);

      await tester.tap(find.text('今日待办'));
      expect(taps, 1);
    });
  });

  group('文案', () {
    testWidgets('英文作用域下折叠条文案切换', (tester) async {
      await tester.pumpWidget(
        KitApp(
          home: Scaffold(
            body: KitStringsScope(
              strings: KitStrings.english,
              child: const ChatMessageList(
                messages: [
                  ChatMessage.assistant(
                    text: 'ok',
                    steps: [ChatStep(tool: 'a'), ChatStep(tool: 'b')],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('2 steps'), findsOneWidget);
    });
  });
}
