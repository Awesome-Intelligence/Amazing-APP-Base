import 'package:flutter_test/flutter_test.dart';
import 'package:kit/kit.dart';

void main() {
  const codec = MarkdownCodec();

  group('MarkdownCodec', () {
    test('encode/decode 往返保真各类型', () {
      final e = StoredEntity(
        id: 'goal-1',
        fields: {
          'progress': 0.65,
          'done': true,
          'count': 3,
          'note': 'hello "world"\nline2',
          'tags': ['跑步', '健身'],
        },
        body: 'Markdown body.',
      );
      final raw = codec.encode(e);
      final decoded = codec.decode('goal-1', raw)!;

      expect(decoded.id, 'goal-1');
      expect(decoded.body, 'Markdown body.');
      expect(decoded.fields['progress'], 0.65);
      expect(decoded.fields['done'], true);
      expect(decoded.fields['count'], 3);
      expect(decoded.fields['note'], 'hello "world"\nline2');
      expect(decoded.fields['tags'], ['跑步', '健身']);
    });

    test('旧数据：带引号的字符串仍宽松可读', () {
      const raw = '---\n'
          'progress: "0.65"\n'
          'done: "true"\n'
          'tags: "a,b"\n'
          '---\n'
          'body';
      final e = codec.decode('x', raw)!;

      expect(e.fields['progress'], '0.65'); // 原样是字符串
      expect(e.fields.doubleOr('progress', 0), 0.65); // 宽松转数字
      expect(e.fields.boolOr('done', false), true);
      expect(e.fields.listOrEmpty('tags'), ['a', 'b']);
      expect(e.body, 'body');
    });

    test('无 frontmatter 返回 null', () {
      expect(codec.decode('x', 'hello, no frontmatter'), isNull);
    });

    test('BOM 前缀可容忍', () {
      const raw = '\uFEFF---\nid: a\n---\nbody';
      final e = codec.decode('a', raw);
      expect(e, isNotNull);
    });
  });
}
