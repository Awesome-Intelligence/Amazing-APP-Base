import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kit/kit.dart';

void main() {
  group('NtfyClient', () {
    test('发布：POST 到主题，body 是 ntfy 的消息格式', () async {
      late http.Request seen;
      final client = NtfyClient(
        server: 'https://ntfy.sh',
        topic: 'demo-topic',
        token: 'tk_abc',
        client: MockClient((req) async {
          seen = req;
          return http.Response('{"id":"1"}', 200);
        }),
      );

      await client.publish(title: '标题', message: '正文');

      expect(seen.method, 'POST');
      expect(seen.url.toString(), 'https://ntfy.sh/demo-topic');
      expect(seen.headers['authorization'], 'Bearer tk_abc');
      expect(jsonDecode(seen.body), {
        'topic': 'demo-topic',
        'title': '标题',
        'message': '正文',
      });
    });

    test('拉取：只留消息事件，按时间倒序', () async {
      final client = NtfyClient(
        server: 'https://ntfy.sh',
        topic: 'demo-topic',
        client: MockClient((req) async {
          expect(req.url.path, '/demo-topic/json');
          expect(req.url.queryParameters['poll'], '1');
          expect(req.url.queryParameters['since'], 'id-old');
          return http.Response(
            jsonEncode([
              {'event': 'open'},
              {
                'id': 'id-new',
                'event': 'message',
                'time': 1700000200,
                'title': '新的',
                'message': '正文',
              },
              {
                'id': 'id-old',
                'event': 'message',
                'time': 1700000100,
                'title': '旧的',
                'message': '',
              },
            ]),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

      final items = await client.fetch(since: 'id-old');

      expect(items.map((n) => n.id), ['id-new', 'id-old']);
      expect(items.first.title, '新的');
      expect(items.first.body, '正文');
      expect(items.first.createdAt.millisecondsSinceEpoch, 1700000200 * 1000);
      expect(items.first.read, isFalse);
    });

    test('拉取失败要抛出去（不能静默丢消息）', () async {
      final client = NtfyClient(
        server: 'https://ntfy.sh',
        topic: 'demo-topic',
        client: MockClient((_) async => http.Response('nope', 500)),
      );
      expect(() => client.fetch(), throwsStateError);
    });
  });

  group('远端消息落库', () {
    test('同一个 id 写两次只有一条（推送重发不重复入库）', () async {
      final store = NotificationStore(MemoryEntityStore(const JsonCodec()));

      await store.add(id: 'ntfy-1', title: '远端', body: 'a');
      await store.add(id: 'ntfy-1', title: '远端', body: 'a');

      final list = await store.list();
      expect(list.length, 1);
      expect(list.single.id, 'ntfy-1');
      expect(await store.unreadCount(), 1);
    });
  });
}
