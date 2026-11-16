import 'dart:convert';

import 'package:http/http.dart' as http;

import 'update_manifest.dart';
import 'update_source.dart';

/// 直接读 GitHub Releases，适合开源项目：不用另建清单，发 Release 就等于发版本。
/// 对应 KMP 的 `data/update/GitHubReleaseSource.kt`。
///
/// 用的是 `/repos/{owner}/{repo}/releases/latest` —— GitHub 的这个端点
/// **只返回已发布、非预发布**的最新 Release。所以 release workflow 里的
/// `draft: true` 草稿在手动发布前查不到，这是对的：草稿还没对外。
///
/// [token] 可选：不填也能用（未登录限 60 次/小时/IP，配合 [UpdateCheckPolicy]
/// 的节流足够）；私有仓库或高频检查再填 GitHub token。
///
/// GitHub Release 没有“最低支持版本”这个概念，所以
/// [UpdateManifest.minSupportedVersion] 恒为 null（不强制更新）。
/// 要强制更新就改用 [HttpUpdateSource] 的静态清单。
class GitHubReleaseSource implements UpdateSource {
  final http.Client client;

  /// `owner/repo`。
  final String repository;
  final String? token;

  const GitHubReleaseSource(
    this.client,
    this.repository, {
    this.token,
  });

  static const String _apiBase = 'https://api.github.com';
  static const String _accept = 'application/vnd.github+json';
  static const String _apiVersion = '2022-11-28';
  static const String _userAgent = 'Flutter-Kit-UpdateChecker';

  @override
  Future<UpdateManifest> fetch() async {
    final response = await client.get(
      Uri.parse('$_apiBase/repos/$repository/releases/latest'),
      headers: <String, String>{
        'Accept': _accept,
        'User-Agent': _userAgent,
        'X-GitHub-Api-Version': _apiVersion,
        if (token != null && token!.isNotEmpty)
          'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('GitHub Releases 请求失败：HTTP ${response.statusCode}');
    }
    return parseGitHubRelease(utf8.decode(response.bodyBytes));
  }
}

/// GitHub Release JSON → [UpdateManifest]。
///
/// 单独拆出来是为了不联网也能测（见 `test/update/github_release_test.dart`）。
UpdateManifest parseGitHubRelease(String json) {
  final decoded = jsonDecode(json);
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('GitHub Release 不是 JSON 对象');
  }
  final tag = decoded['tag_name'];
  if (tag is! String || tag.trim().isEmpty) {
    throw const FormatException('GitHub Release 缺少 tag_name');
  }
  final htmlUrl = decoded['html_url'];
  final body = decoded['body'];
  final publishedAt = decoded['published_at'];
  return UpdateManifest(
    latestVersion: tag,
    // latest 端点不会返回 draft / prerelease，这里不重复判断
    downloadUrl: htmlUrl is String && htmlUrl.isNotEmpty ? htmlUrl : null,
    releaseNotes: body is String ? body : '',
    publishedAt:
        publishedAt is String && publishedAt.isNotEmpty ? publishedAt : null,
  );
}
