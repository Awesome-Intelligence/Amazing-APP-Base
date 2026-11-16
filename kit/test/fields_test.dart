import 'package:flutter_test/flutter_test.dart';
import 'package:kit/kit.dart';

void main() {
  group('Fields', () {
    test('宽松类型转换', () {
      final m = <String, dynamic>{
        'n': '42',
        'd': '0.5',
        'b': 'true',
        'zero': '0',
        'list': 'a,b',
        'arr': '["x","y"]',
        'isDeleted': 'true',
      };

      expect(m.intOr('n', -1), 42);
      expect(m.doubleOr('d', 0), 0.5);
      expect(m.boolOr('b', false), true);
      expect(m.boolOr('zero', true), false);
      expect(m.listOrEmpty('list'), ['a', 'b']);
      expect(m.listOrEmpty('arr'), ['x', 'y']);
      expect(m.archivedFlagOr(false), true);
    });

    test('缺字段回默认', () {
      final m = <String, dynamic>{};

      expect(m.intOr('x', 7), 7);
      expect(m.str('x'), isNull);
      expect(m.strOrEmpty('x'), '');
      expect(m.listOrEmpty('x'), isEmpty);
    });
  });
}
