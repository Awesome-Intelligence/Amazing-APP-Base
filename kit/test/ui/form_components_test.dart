import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit/kit.dart';
import 'package:kit/kit_ui.dart';

/// 表单/列表这批组件的行为验证：真的 pump 出来、真的点、真的回传。
void main() {
  Future<void> pumpInApp(
    WidgetTester tester,
    Widget child, {
    ThemeStyle style = ThemeStyle.mono,
  }) {
    return tester.pumpWidget(
      KitApp(style: style, home: Scaffold(body: child)),
    );
  }

  group('KitFilterChip', () {
    testWidgets('选中态透传到 M3 FilterChip，点击触发回调', (tester) async {
      var taps = 0;
      await pumpInApp(
        tester,
        KitFilterChip(
          title: '全部',
          isSelected: true,
          onTap: () => taps++,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('全部'), findsOneWidget);
      final chip = tester.widget<FilterChip>(find.byType(FilterChip));
      expect(chip.selected, isTrue);
      // Compose 版选中不画勾，靠底色；Flutter 必须显式关掉默认勾。
      expect(chip.showCheckmark, isFalse);

      await tester.tap(find.text('全部'));
      expect(taps, 1);
    });

    testWidgets('泛型横排：回传被点的那个选项（不是下标）', (tester) async {
      String selected = '全部';
      await pumpInApp(
        tester,
        KitFilterChipRow<String>(
          options: const ['全部', '工作', '生活'],
          selectedOption: selected,
          onOptionSelected: (v) => selected = v,
          optionLabel: (v) => v,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('生活'));
      expect(selected, '生活');
    });

    testWidgets('按下标版：回传下标', (tester) async {
      var index = 0;
      await pumpInApp(
        tester,
        KitFilterChipRowIndexed(
          options: const ['全部', '工作', '生活'],
          selectedIndex: 0,
          onSelect: (i) => index = i,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('工作'));
      expect(index, 1);
    });
  });

  group('标签类组件', () {
    testWidgets('TagText 带 # 前缀；选中时多一个勾', (tester) async {
      await pumpInApp(
        tester,
        const Column(
          children: [
            TagText(text: '工作', color: Color(0xFF3355FF)),
            TagText(text: '生活', color: Color(0xFFEE7744), isSelected: true),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('# 工作'), findsOneWidget);
      expect(find.text('# 生活'), findsOneWidget);
      // 只有选中那个画勾
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('SelectableTag 选中态切换底色、文字转黑', (tester) async {
      var taps = 0;
      await pumpInApp(
        tester,
        SelectableTag(
          text: '标签',
          isSelected: true,
          onTap: () => taps++,
          selectedColor: const Color(0xFFFFDD00), // 亮底 → 黑字
        ),
      );
      await tester.pumpAndSettle();

      final text = tester.widget<Text>(find.text('标签'));
      expect(text.style?.color, Colors.black);

      await tester.tap(find.text('标签'));
      expect(taps, 1);
    });

    testWidgets('ColorDotRow 点哪个圆点回传哪个色名', (tester) async {
      String? picked;
      await pumpInApp(
        tester,
        ColorDotRow(
          colorNames: tagColorNames,
          selectedColorName: 'neutral',
          onColorSelected: (name) => picked = name,
        ),
      );
      await tester.pumpAndSettle();

      // 6 个色点，2 个语义节点（每个点一个）
      expect(find.byType(ColorDot), findsNWidgets(tagColorNames.length));

      await tester.tap(find.byType(ColorDot).at(2));
      expect(picked, tagColorNames[2]);
    });

    testWidgets('AppBadge 渲染文字', (tester) async {
      await pumpInApp(tester, const AppBadge(text: 'NEW'));
      await tester.pumpAndSettle();
      expect(find.text('NEW'), findsOneWidget);
    });

    testWidgets('AddTagChip / AnswerChip 可点且不溢出', (tester) async {
      var add = 0;
      var answer = 0;
      await pumpInApp(
        tester,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AddTagChip(onTap: () => add++),
            AnswerChip(text: '今天', onTap: () => answer++),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('+'), findsOneWidget);
      expect(find.text('今天'), findsOneWidget);

      await tester.tap(find.text('+'));
      await tester.tap(find.text('今天'));
      expect(add, 1);
      expect(answer, 1);

      // 布局溢出在测试里会是异常；这里显式确认没有。
      expect(tester.takeException(), isNull);
    });
  });

  group('KitCheckbox', () {
    testWidgets('点击回传新值', (tester) async {
      bool? value;
      await pumpInApp(
        tester,
        KitCheckbox(isChecked: false, onCheckedChange: (v) => value = v),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Checkbox));
      expect(value, isTrue);
    });

    testWidgets('默认无障碍描述随勾选状态变化', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpInApp(
        tester,
        const Column(
          children: [
            KitCheckbox(isChecked: true, onCheckedChange: _noop),
            KitCheckbox(isChecked: false, onCheckedChange: _noop),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('已选中'), findsOneWidget);
      expect(find.bySemanticsLabel('未选中'), findsOneWidget);
      handle.dispose();
    });
  });

  group('SimpleTextField', () {
    testWidgets('输入回传；外部重置 value 能反映到输入框', (tester) async {
      var value = '初始';
      late StateSetter setOuter;

      await tester.pumpWidget(
        KitApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                setOuter = setState;
                return SimpleTextField(
                  value: value,
                  onValueChange: (v) => setState(() => value = v),
                  label: '标题',
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('标题'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '买牛奶');
      await tester.pump();
      expect(value, '买牛奶');

      // 关键：外部把 value 清空（表单提交后重置），屏幕上必须也是空的。
      // 只改外部 state 不动 controller 的话，文字会赖在屏幕上不走。
      setOuter(() => value = '');
      await tester.pumpAndSettle();
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.controller.text, isEmpty);
    });

    testWidgets('isError 时辅助文案走 errorText 槽位', (tester) async {
      await pumpInApp(
        tester,
        const SimpleTextField(
          value: '',
          onValueChange: _noopStr,
          helperText: '名称不能为空',
          isError: true,
        ),
      );
      await tester.pumpAndSettle();

      final decorator =
          tester.widget<InputDecorator>(find.byType(InputDecorator));
      expect(decorator.decoration.errorText, '名称不能为空');
      expect(find.text('名称不能为空'), findsOneWidget);
    });
  });

  group('ComposerField', () {
    testWidgets('占位符可见、语音键可点、发送键回调', (tester) async {
      var mic = 0;
      var submitted = 0;
      var text = '';

      await pumpInApp(
        tester,
        ComposerField(
          value: text,
          onValueChange: (v) => text = v,
          placeholder: '说点什么',
          onMicTap: () => mic++,
          micContentDescription: '语音输入',
          onSubmit: () => submitted++,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('说点什么'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.mic_none));
      expect(mic, 1);

      await tester.enterText(find.byType(TextField), '你好');
      await tester.pump();
      expect(text, '你好');

      // 键盘上的「发送」→ 触发 onSubmit
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();
      expect(submitted, 1);
    });
  });

  group('对话框', () {
    /// 挂一个带 Navigator 的宿主，并拿到它的 context 用来弹窗。
    Future<BuildContext> host(WidgetTester tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        KitApp(
          home: Builder(
            builder: (context) {
              ctx = context;
              return const Scaffold(body: SizedBox.shrink());
            },
          ),
        ),
      );
      return ctx;
    }

    testWidgets('ConfirmDialog：确认返回 true，取消返回 false', (tester) async {
      final ctx = await host(tester);

      final ok = ConfirmDialog.show(ctx, title: '保存修改？', message: '会覆盖原内容');
      await tester.pumpAndSettle();
      expect(find.text('保存修改？'), findsOneWidget);
      expect(find.text('会覆盖原内容'), findsOneWidget);
      await tester.tap(find.text('确认'));
      await tester.pumpAndSettle();
      expect(await ok, isTrue);

      final no = ConfirmDialog.show(ctx, title: '保存修改？');
      await tester.pumpAndSettle();
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(await no, isFalse);
    });

    testWidgets('DeleteConfirmDialog 默认用「确认删除」文案与垃圾桶图标', (tester) async {
      final ctx = await host(tester);

      final ok = DeleteConfirmDialog.show(ctx);
      await tester.pumpAndSettle();
      expect(find.text('确认删除'), findsOneWidget);
      expect(find.text('删除后无法恢复，确定要删除吗？'), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);

      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();
      expect(await ok, isTrue);
    });

    testWidgets('SelectDialog：先选后确认才生效', (tester) async {
      final ctx = await host(tester);

      final picked = SelectDialog.show(
        ctx,
        title: '选择排序',
        options: const ['按时间', '按优先级', '按标题'],
        selectedIndex: 0,
      );
      await tester.pumpAndSettle();

      // 只点选项不确认时，弹窗还没关
      await tester.tap(find.text('按优先级'));
      await tester.pumpAndSettle();
      expect(find.text('选择排序'), findsOneWidget);

      await tester.tap(find.text('确认'));
      await tester.pumpAndSettle();
      expect(await picked, 1);
    });

    testWidgets('InputDialog 返回输入文本', (tester) async {
      final ctx = await host(tester);

      final result = InputDialog.show(ctx, title: '重命名', hint: '新名字');
      await tester.pumpAndSettle();
      expect(find.text('重命名'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '周报');
      await tester.pump();
      await tester.tap(find.text('确认'));
      await tester.pumpAndSettle();

      expect(await result, '周报');
    });

    testWidgets('LoadingDialog.show 返回的关闭函数能关掉弹窗', (tester) async {
      final ctx = await host(tester);

      final close = LoadingDialog.show(ctx, message: '正在保存', cancellable: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('正在保存'), findsOneWidget);

      await close();
      await tester.pumpAndSettle();
      expect(find.text('正在保存'), findsNothing);
    });
  });

  group('列表条目', () {
    testWidgets('AppListItem 渲染标题/副标题/尾部/标签/进度', (tester) async {
      await pumpInApp(
        tester,
        const AppListItem(
          headlineText: '买牛奶',
          supportingText: '今天到期',
          trailingText: '2 件',
          progress: 0.5,
          tags: ['家务', '购物'],
          leadingBadge: 3,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('买牛奶'), findsOneWidget);
      expect(find.text('今天到期'), findsOneWidget);
      expect(find.text('2 件'), findsOneWidget);
      expect(find.text('# 家务'), findsOneWidget);
      expect(find.text('# 购物'), findsOneWidget);
      // leadingBadge 渲染成 40 圆里的编号
      expect(find.text('3'), findsOneWidget);

      final bar =
          tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
      expect(bar.value, 0.5);
    });

    testWidgets('AppListItem 点击回调；没有 onTap 时不铺水波纹', (tester) async {
      var taps = 0;
      await pumpInApp(
        tester,
        Column(
          children: [
            AppListItem(headlineText: '可点', onTap: () => taps++),
            const AppListItem(headlineText: '不可点'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('可点'));
      expect(taps, 1);
      // 只有可点那条有 InkWell
      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('AddListItem 渲染加号与文字，点击回调', (tester) async {
      var taps = 0;
      await pumpInApp(
        tester,
        AddListItem(text: '添加待办', onTap: () => taps++),
      );
      await tester.pumpAndSettle();

      expect(find.text('添加待办'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);

      await tester.tap(find.text('添加待办'));
      expect(taps, 1);
    });
  });
}

void _noop(bool _) {}
void _noopStr(String _) {}
