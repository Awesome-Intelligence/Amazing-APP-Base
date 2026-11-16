import 'package:flutter_test/flutter_test.dart';
import 'package:kit/kit.dart';

void main() {
  group('MemoryEntityStore', () {
    test('CRUD', () async {
      final store = MemoryEntityStore(const JsonCodec());

      await store.write(
        'goals',
        const StoredEntity(id: 'g1', fields: {'p': 0.5}, body: 'b'),
      );
      final read = await store.read('goals', 'g1');
      expect(read!.fields['p'], 0.5);
      expect(read.body, 'b');

      expect(await store.listIds('goals'), ['g1']);
      expect(await store.loadAll('goals'), hasLength(1));

      expect(await store.delete('goals', 'g1'), isTrue);
      expect(await store.read('goals', 'g1'), isNull);
      expect(await store.delete('goals', 'g1'), isFalse);
    });

    test('二进制附件读写', () async {
      final store = MemoryEntityStore(const MarkdownCodec());
      await store.writeBinary(
          'att', 'a.bin', [1, 2, 3], 'application/octet-stream');

      expect(await store.readBinary('att', 'a.bin'), [1, 2, 3]);
      expect(await store.listBinaryFilenames('att'), ['a.bin']);
      expect(store.imageUri('att', 'a.bin'), isNotNull);
    });
  });
}
