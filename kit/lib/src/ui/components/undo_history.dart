import 'package:flutter/services.dart' show TextEditingValue;

/// 编辑器撤销/重做历史。对应 KMP 的 `ui/components/UndoHistory.kt`。
///
/// 存的是「文本 + 光标」快照：撤销一步 = 回到上一份快照，光标也跟着回去。
/// 连续输入在 [coalesceMs] 窗口内合并成一步（否则一次撤销只退一个字）。
///
/// ```dart
/// final history = UndoHistory();
/// history.startSession('note-1', controller.value);
/// // 每次文本变化
/// history.push(controller.value, typing: true);
/// // 撤销
/// final previous = history.undo();
/// if (previous != null) controller.value = previous;
/// ```
///
/// 纯逻辑、不碰 Widget —— 所以能直接单测，也能给非 Flutter 的编辑器用
/// （只要自己造 `TextEditingValue`）。
class UndoHistory {
  /// 连续输入的合并窗口（毫秒）：两次输入间隔超过就另起一步。
  static const int coalesceMs = 800;

  /// 最多保留多少步。
  static const int maxSteps = 50;

  final List<TextEditingValue> _states = [];
  int _index = 0;
  String? _sessionKey;
  int _lastPushAt = 0;
  bool _lastWasTyping = false;
  final int Function() _nowMillis;

  /// [nowMillis] 可注入，测试里用来把时间钉死（否则合并窗口测不稳）。
  UndoHistory({int Function()? nowMillis})
      : _nowMillis =
            nowMillis ?? (() => DateTime.now().millisecondsSinceEpoch);

  /// 当前编辑会话标识：换了记录就变，历史要清空。
  String? get sessionKey => _sessionKey;

  /// 还没有任何快照。
  bool get isEmpty => _states.isEmpty;

  /// 能否撤销。
  bool get canUndo => _index > 0;

  /// 能否重做。
  bool get canRedo => _index < _states.length - 1;

  /// 快照步数（测试/调试用）。
  int get stepCount => _states.length;

  /// 开一个新会话：丢掉旧历史，只留当前内容。
  void startSession(String? key, TextEditingValue value) {
    _sessionKey = key;
    _states
      ..clear()
      ..add(value);
    _index = 0;
    _lastPushAt = 0;
    _lastWasTyping = false;
  }

  /// 记入一步新内容。
  ///
  /// [typing] true = 逐字输入（会和上一步合并）；
  /// false = 整块操作（工具栏插入等），单独成步。
  void push(TextEditingValue value, {bool typing = false}) {
    if (_states.isEmpty) {
      startSession(_sessionKey, value);
      return;
    }
    final now = _nowMillis();
    final merge = typing &&
        _lastWasTyping &&
        now - _lastPushAt < coalesceMs &&
        _index == _states.length - 1;
    if (merge) {
      _states[_index] = value;
    } else {
      // 新的一步：redo 分支作废
      while (_states.length > _index + 1) {
        _states.removeLast();
      }
      _states.add(value);
      _index = _states.length - 1;
      // 超出上限丢最早的，下标跟着往前挪
      while (_states.length > maxSteps) {
        _states.removeAt(0);
        _index--;
      }
    }
    _lastPushAt = now;
    _lastWasTyping = typing;
  }

  /// 撤销一步，返回要回填的快照；没得撤返回 null。
  ///
  /// KMP 版是传 `onApply` 回调，Dart 这里改成返回值 —— 调用方拿它直接
  /// 赋给 `controller.value`，不用为了一个副作用多写一层闭包。
  TextEditingValue? undo() {
    if (!canUndo) return null;
    _index--;
    // 撤销之后紧接着打字，不该和撤销前那一步合并
    _lastWasTyping = false;
    return _states[_index];
  }

  /// 重做一步，返回要回填的快照；没得重做返回 null。
  TextEditingValue? redo() {
    if (!canRedo) return null;
    _index++;
    _lastWasTyping = false;
    return _states[_index];
  }
}
