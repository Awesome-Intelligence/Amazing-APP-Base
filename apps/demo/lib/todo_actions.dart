import 'package:kit/kit.dart';

import 'todo_store.dart';

/// 契约动作表 —— `apps/demo/contract/actions.json` 里每个 action 的 Flutter 端实现。
///
/// 动作名必须和契约文件一模一样，返回的文案必须包含契约里 `expect` 的片段 ——
/// 由 `test/todo_contract_test.dart` 盯着。改了一边忘了改另一边，那道单测就红。
///
/// 小程序端同一份契约的实现见 `miniprogram/logic/actions.js`。
/// 两边跑的是同一个 `contract/actions.json`，所以行为和文案不会分叉。
///
/// 为什么是 `AsyncActionMap`：这里的动作全都落到 `TodoStore`，而 TodoStore 背后是
/// `EntityStore`（async）。
AsyncActionMap todoActions(TodoStore store) => <String, Future<String> Function(Map<String, dynamic>)>{
      'list_todos': (_) => store.summary(),
      'add_todo': (input) => store.add(_str(input['title'])),
      'delete_todo': (input) => store.remove(_str(input['id'])),
    };

/// 取一个字符串字段；缺了或者不是字符串就当空串（业务层会自己报「内容是空的」）。
String _str(Object? value) => value is String ? value : '';
