import 'dart:convert';
import 'dart:io';

import 'package:demo/todo_actions.dart';
import 'package:demo/todo_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit/kit.dart';

/// 跨端契约的 native 端守门人。
///
/// 读 `contract/actions.json`（和小程序端共用的那一份），拿 `todoActions` 跑一遍。
/// 谁改了行为或文案没同步，这条单测就红 —— 这是「业务逻辑没有编译期保障」
/// 问题的兜底（agent 的 skill 也一样，见 `todo_skill_test`）。
void main() {
  group('跨端契约（contract/actions.json）', () {
    late ActionContract contract;

    setUpAll(() {
      // 测试的工作目录是包根（apps/demo），所以这里是相对路径
      final file = File('contract/actions.json');
      expect(file.existsSync(), isTrue,
          reason: '缺少 contract/actions.json —— 契约文件是各端共享的，不能删');
      contract = ActionContract.fromJson(
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
      );
    });

    test('契约文件本身合法：版本 + 至少一条样例', () {
      expect(contract.version, greaterThanOrEqualTo(1));
      expect(contract.actions, isNotEmpty);
      for (final sample in contract.actions) {
        expect(sample.action.trim(), isNotEmpty);
        expect(sample.expect.trim(), isNotEmpty,
            reason: '样例 ${sample.action} 的 expect 是空的，钉不住任何东西');
      }
    });

    test('Flutter 端动作表全部通过契约', () async {
      // 每条样例都重新建一次 store：样例之间互不影响（加样例不用重排）
      final failures = await runAsyncActionSamples(contract, () {
        final store = TodoStore(MemoryEntityStore(const JsonCodec()));
        return todoActions(store);
      });

      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    test('契约里列出的每个动作，动作表里都有实现', () {
      final actions = todoActions(TodoStore(MemoryEntityStore(const JsonCodec())));
      for (final sample in contract.actions) {
        expect(actions.containsKey(sample.action), isTrue,
            reason: '契约有 ${sample.action}，但 todoActions 没实现');
      }
    });
  });
}
