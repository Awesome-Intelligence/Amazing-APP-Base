import 'package:flutter_test/flutter_test.dart';
import 'package:kit/kit.dart';

void main() {
  group('AppVersion 解析', () {
    test('标准三段', () {
      final v = AppVersion.parseOrNull('1.2.3')!;
      expect(v.numbers, [1, 2, 3]);
      expect(v.preRelease, isEmpty);
      expect(v.buildMetadata, isNull);
    });

    test('带 v 前缀', () {
      expect(AppVersion.parseOrNull('v1.2.3')!.numbers, [1, 2, 3]);
      expect(AppVersion.parseOrNull('V1.2.3')!.numbers, [1, 2, 3]);
    });

    test('两段（缺的位补 0）', () {
      final v = AppVersion.parseOrNull('1.2')!;
      expect(v.numbers, [1, 2]);
      expect(v.compareTo(AppVersion.parseOrNull('1.2.0')!), 0);
    });

    test('pre-release 与 build metadata', () {
      final v = AppVersion.parseOrNull('1.2.3-beta.1+build.7')!;
      expect(v.preRelease, ['beta', '1']);
      expect(v.buildMetadata, 'build.7');
      expect(v.toString(), '1.2.3-beta.1+build.7');
    });

    test('非法输入返回 null，不抛异常', () {
      expect(AppVersion.parseOrNull(''), isNull);
      expect(AppVersion.parseOrNull('abc'), isNull);
      expect(AppVersion.parseOrNull('1.x.3'), isNull);
      expect(AppVersion.parseOrNull('1.2.3-'), isNull);
      expect(AppVersion.parseOrNull('1.2.3-alpha..2'), isNull);
      expect(AppVersion.parseOrNull('1.2.3+'), isNull);
    });

    test('两边空白自动去掉', () {
      expect(AppVersion.parseOrNull('  1.2.3  ')!.numbers, [1, 2, 3]);
    });
  });

  group('AppVersion 比较', () {
    int cmp(String a, String b) => AppVersion.parseOrNull(a)!
        .compareTo(AppVersion.parseOrNull(b)!);

    test('字典序会错的场景：1.10.0 大于 1.9.0', () {
      expect(cmp('1.10.0', '1.9.0'), greaterThan(0));
      expect(cmp('1.9.0', '1.10.0'), lessThan(0));
    });

    test('位数不同按补 0 比', () {
      expect(cmp('1.2', '1.2.0'), 0);
      expect(cmp('1.2.1', '1.2'), greaterThan(0));
    });

    test('正式版大于同号 pre-release', () {
      expect(cmp('1.2.3', '1.2.3-beta'), greaterThan(0));
      expect(cmp('1.2.3-beta', '1.2.3'), lessThan(0));
    });

    test('pre-release 数字段按数值比，不按字典序', () {
      expect(cmp('1.2.3-beta.10', '1.2.3-beta.2'), greaterThan(0));
    });

    test('数字标识符小于字母标识符', () {
      expect(cmp('1.2.3-1', '1.2.3-alpha'), lessThan(0));
    });

    test('字母标识符按字典序', () {
      expect(cmp('1.2.3-alpha', '1.2.3-beta'), lessThan(0));
    });

    test('build metadata 不参与比较', () {
      expect(cmp('1.2.3+a', '1.2.3+b'), 0);
    });

    test('运算符可用', () {
      final newer = AppVersion.parseOrNull('2.0.0')!;
      final older = AppVersion.parseOrNull('1.0.0')!;
      expect(newer > older, isTrue);
      expect(older < newer, isTrue);
      expect(newer >= older, isTrue);
      expect(older <= newer, isTrue);
    });
  });
}
