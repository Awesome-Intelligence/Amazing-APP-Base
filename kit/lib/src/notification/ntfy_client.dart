import 'dart:convert';

import 'package:http/http.dart' as http;

import 'notification.dart';

/// ntfy 客户端 —— 推送服务 [ntfy](https://ntfy.sh) 的 HTTP 接口。
///
/// ntfy 是自托管的推送服务，协议就是普通 HTTP，没有账号体系、没有厂商锁定：
/// - 发布：`POST {server}/{topic}`，body 是 `{"topic","title","message"}`
/// - 拉取：`GET {server}/{topic}/json?poll=1&since=<消息id>`
///
/// 用它换来的好处：底座不背任何平台 SDK，web / 桌面 / 移动端同一份代码；
/// 代价是**应用被杀时收不到**（没有 FCM / APNs 那种系统级唤醒）——
/// 真要后台到达，还得在 app 层再接一层系统推送（见 `rules/KIT-NOTES.md` 〇.k）。
///
/// 为什么放底座：纯 HTTP，不碰任何平台 API（和 `HttpUpdateSource` 一个路子）。
class NtfyClient {
  NtfyClient({
    required this.server,
    required this.topic,
    this.token,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// 服务地址，例如 `https://ntfy.sh`（自托管就是自己的域名）。
  final String server;

  /// 主题名。收发双方约定同一个主题就算一条通道。
  final String topic;

  /// 访问令牌（ntfy 的 access token，`tk_` 开头）。公开主题可以不给。
  final String? token;

  final http.Client _client;

  Map<String, String> get _headers => {
        'content-type': 'application/json',
        if (token != null && token!.isNotEmpty) 'authorization': 'Bearer $token',
      };

  /// 发布一条消息。
  Future<void> publish({required String title, required String message}) async {
    final res = await _client.post(
      Uri.parse('$server/$topic'),
      headers: _headers,
      body: jsonEncode({'topic': topic, 'title': title, 'message': message}),
    );
    if (res.statusCode >= 300) {
      throw StateError('ntfy 发布失败: ${res.statusCode} ${res.body}');
    }
  }

  /// 拉一次消息（poll 模式：返回后连接就关了）。
  ///
  /// [since] 传上一次收到的消息 id —— ntfy 只返回它之后的消息。
  /// 返回值按时间倒序（新的在前）；非消息事件（心跳、poll_request）被丢掉。
  Future<List<AppNotification>> fetch({String? since}) async {
    final uri = Uri.parse('$server/$topic/json').replace(queryParameters: {
      'poll': '1',
      if (since != null && since.isNotEmpty) 'since': since,
    });
    final res = await _client.get(uri, headers: _headers);
    if (res.statusCode != 200) {
      throw StateError('ntfy 拉取失败: ${res.statusCode} ${res.body}');
    }
    final decoded = jsonDecode(res.body);
    if (decoded is! List) return const [];
    final items = <AppNotification>[];
    for (final m in decoded) {
      if (m is! Map) continue;
      if (m['event'] != 'message') continue;
      final id = m['id'];
      if (id is! String || id.isEmpty) continue;
      items.add(
        AppNotification(
          // 用 ntfy 的消息 id 当通知 id —— 同一个 id 重复收到只入库一次。
          id: id,
          title: (m['title'] as String?) ?? '',
          body: (m['message'] as String?) ?? '',
          createdAt: DateTime.fromMillisecondsSinceEpoch(
            ((m['time'] as num?)?.toInt() ?? 0) * 1000,
          ),
        ),
      );
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }
}
