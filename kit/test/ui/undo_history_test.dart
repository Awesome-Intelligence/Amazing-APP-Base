import 'package:flutter/services.dart' show TextEditingValue, TextSelection;
import 'package:flutter_test/flutter_test.dart';
import 'package:kit/kit_ui.dart';

/// 纯逻辑组件的测试 —— 撤销历史的正确性全靠这些用例，
/// 出错的代价是「用户撤销时丢内容」，比 UI 错位严重得多。
void main() {
  TextEditingValue v(String text, [int offset = -1]) => TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(
          offset: offset < 0 ? text.length : offset,
        ),
      );

  group('UndoHistory', () {
    test('新会话只有一步：不能撤销也不能重做', () {
      final h = UndoHistory();
      h.startSession('note-1', v('起步'));

      expect(h.isEmpty, isFalse);
      expect(h.stepCount, 1);
      expect(h.canUndo, isFalse);
      expect(h.canRedo, isFalse);
      expect(h.sessionKey, 'note-1');
    });

    test('推一步后能撤销，撤销后能重做', () {
      final h = UndoHistory(nowMillis: () => 0);
      h.startSession('k', v('a'));
      h.push(v('ab'), typing: true);

      expect(h.canUndo, isTrue);
      expect(h.canRedo, isFalse);

      final undone = h.undo();
      expect(undone!.text, 'a');
      expect(h.canUndo, isFalse);
      expect(h.canRedo, isTrue);

      final redone = h.redo();
      expect(redone!.text, 'ab');
      expect(h.canRedo, isFalse);
    });

    test('撤销时光标跟着回退（不是只换文本）', () {
      final h = UndoHistory(nowMillis: () => 0);
      h.startSession('k', v('abc', 1));
      h.push(v('abcdef', 6), typing: true);

      final undone = h.undo();
      expect(undone!.text, 'abc');
      expect(undone.selection.baseOffset, 1, reason: '光标要回到当时的位置');
    });

    test('连续输入在合并窗口内合成一步', () {
      var now = 1000;
      final h = UndoHistory(nowMillis: () => now);
      h.startSession('k', v(''));

      h.push(v('今'), typing: true);
      now += 100;
      h.push(v('今天'), typing: true);
      now += 100;
      h.push(v('今天很'), typing: true);

      expect(h.stepCount, 2, reason: '起步 + 合并后的一步');
      expect(h.undo()!.text, '', reason: '一次撤销退掉整段连续输入');

      // 时间往前挪，避免影响后续用例的时间基线
      now += 0;
    });

    test('超过合并窗口的输入另起一步', () {
      var now = 1000;
      final h = UndoHistory(nowMillis: () => now);
      h.startSession('k', v(''));
      h.push(v('a'), typing: true);
      now += UndoHistory.coalesceMs + 1;
      h.push(v('ab'), typing: true);

      expect(h.stepCount, 3);
      h.undo();
      expect(h.undo()!.text, '');
    });

    test('非 typing 的整块操作单独成步（不和前面的输入合并）', () {
      var now = 1000;
      final h = UndoHistory(nowMillis: () => now);
      h.startSession('k', v(''));
      h.push(v('a'), typing: true);
      now += 10; // 还在合并窗口内，但 typing=false 不该合并
      h.push(v('a**粗体**'), typing: false);

      expect(h.stepCount, 3);
      h.undo();
      expect(h.undo()!.text, '');
    });

    test('撤销后再输入：redo 分支作废', () {
      final h = UndoHistory(nowMillis: () => 0);
      h.startSession('k', v('a'));
      h.push(v('ab'));
      h.push(v('abc'));

      h.undo(); // 回到 ab
      expect(h.canRedo, isTrue);

      h.push(v('abX'), typing: false);
      expect(h.canRedo, isFalse, reason: '新分支产生后旧的 redo 不该还在');
      expect(h.undo()!.text, 'ab');
    });

    test('超过上限丢最早的快照，且不会丢当前位置', () {
      var now = 0;
      final h = UndoHistory(nowMillis: () => now);
      h.startSession('k', v('0'));

      for (var i = 1; i <= UndoHistory.maxSteps + 10; i++) {
        now += UndoHistory.coalesceMs + 1; // 强制每条单独成步
        h.push(v('$i'));
      }

      expect(h.stepCount, UndoHistory.maxSteps);
      expect(h.canRedo, isFalse);

      // 一路撤到底，最后停在保留下来的最早一份快照
      var last = '';
      while (h.canUndo) {
        last = h.undo()!.text;
      }
      expect(last, isNotEmpty);
      expect(h.canUndo, isFalse);
    });

    test('空历史里 undo/redo 返回 null，不抛', () {
      final h = UndoHistory();
      expect(h.undo(), isNull);
      expect(h.redo(), isNull);
      expect(h.isEmpty, isTrue);
    });

    test('换会话：历史清空，只剩当前内容', () {
      final h = UndoHistory(nowMillis: () => 0);
      h.startSession('note-1', v('旧内容'));
      h.push(v('旧内容改了'));
      expect(h.canUndo, isTrue);

      h.startSession('note-2', v('新内容'));
      expect(h.sessionKey, 'note-2');
      expect(h.stepCount, 1);
      expect(h.canUndo, isFalse);
    });
  });
}
