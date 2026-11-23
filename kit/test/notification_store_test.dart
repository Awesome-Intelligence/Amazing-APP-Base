import 'package:flutter_test/flutter_test.dart';
import 'package:kit/kit.dart';

void main() {
  group('NotificationStore', () {
    test('按时间倒序、统计未读、标记已读', () async {
      final store = NotificationStore(MemoryEntityStore(const JsonCodec()));

      await store.add(
        title: '第一条',
        body: 'a',
        createdAt: DateTime(2026, 11, 19, 10),
      );
      await store.add(
        title: '第二条',
        body: 'b',
        createdAt: DateTime(2026, 11, 19, 12),
      );

      final list = await store.list();
      // 新的在前。
      expect(list.map((n) => n.title), ['第二条', '第一条']);
      expect(await store.unreadCount(), 2);

      await store.markRead(list.last.id);
      expect(await store.unreadCount(), 1);

      await store.markAllRead();
      expect(await store.unreadCount(), 0);
      expect((await store.list()).every((n) => n.read), isTrue);
    });

    test('换个 store 实例也读得回来（说明真的落进存储了）', () async {
      final entities = MemoryEntityStore(const JsonCodec());
      await NotificationStore(entities).add(title: '持久', body: '内容');

      final again = NotificationStore(entities);
      final list = await again.list();
      expect(list.single.title, '持久');
      expect(list.single.body, '内容');
      expect(list.single.read, isFalse);
    });
  });
}
