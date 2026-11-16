import 'package:flutter_test/flutter_test.dart';
import 'package:kit/kit.dart';

void main() {
  group('ActionContract', () {
    test('契约样例全过（每条样例从干净状态开始）', () {
      final contract = ActionContract(actions: [
        const ActionSample(
          action: 'add_todo',
          input: {'title': 'milk'},
          expect: 'milk',
        ),
        const ActionSample(action: 'count_todos', expect: '0'),
      ]);

      final failures = runActionSamples(contract, () {
        final todos = <String>[];
        return {
          'add_todo': (input) {
            todos.add(input['title'] as String);
            return 'added ${input['title']}';
          },
          'count_todos': (_) => 'count=${todos.length}',
        };
      });

      expect(failures, isEmpty);
    });

    test('缺动作 / 文案不符都算失败', () {
      final contract = ActionContract(actions: [
        const ActionSample(action: 'missing', expect: 'x'),
        const ActionSample(action: 'add', input: {'t': 'a'}, expect: 'zzz'),
      ]);

      final failures = runActionSamples(contract, () => {
            'add': (input) => 'added ${input['t']}',
          });

      expect(failures.length, 2);
      expect(failures.any((f) => f.reason.contains('没有动作')), isTrue);
      expect(failures.any((f) => f.reason.contains('没有 "zzz"')), isTrue);
    });
  });
}
