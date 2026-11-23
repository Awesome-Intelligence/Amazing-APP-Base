import 'dart:convert';

import 'package:http/http.dart' as http;

import 'update_manifest.dart';
import 'update_source.dart';

/// 从静态 JSON 清单读版本信息（字段说明见 [UpdateManifest]）。
/// [client] 由 App 提供，为什么不在 kit 里 new 一个：
/// 超时策略、代理、UA 归 App 管。
/// 需要自定义就看 `http` 包的 `IOClient` / `BrowserClient`。
///
/// 注意：清单地址必须是 HTTPS。更新通道本身是攻击面 ——
/// 清单被篡改就能把用户引到恶意包。
class HttpUpdateSource implements UpdateSource {
  final http.Client client;
  final String manifestUrl;

  const HttpUpdateSource(this.client, this.manifestUrl);

  static const String _userAgent = 'Flutter-Kit-UpdateChecker';

  @override
  Future<UpdateManifest> fetch() async {
    final response = await client.get(
      Uri.parse(manifestUrl),
      headers: const <String, String>{
        'Accept': 'application/json',
        'User-Agent': _userAgent,
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('版本清单请求失败：HTTP ${response.statusCode}');
    }
    // 用 bodyBytes 自己解 utf8：response.body 按 header 猜编码，
    // 清单里写了中文更新说明、服务器又没声明 charset 时会乱码
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('版本清单不是 JSON 对象');
    }
    // 以后清单加字段，旧版 App 照样能读 —— 没认识的键直接忽略
    return UpdateManifest.fromJson(decoded);
  }
}
