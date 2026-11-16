import 'package:flutter_test/flutter_test.dart';
import 'package:kit/src/update/github_release_source.dart';

void main() {
  group('parseGitHubRelease', () {
    test('正常 Release → UpdateManifest', () {
      const json = '''
{
  "tag_name": "v1.4.0",
  "html_url": "https://github.com/o/r/releases/tag/v1.4.0",
  "body": "- 修复登录闪退\\n- 新增深色模式",
  "published_at": "2026-11-10T12:00:00Z"
}
''';
      final manifest = parseGitHubRelease(json);
      expect(manifest.latestVersion, 'v1.4.0');
      expect(manifest.downloadUrl,
          'https://github.com/o/r/releases/tag/v1.4.0');
      expect(manifest.releaseNotes, contains('深色模式'));
      expect(manifest.publishedAt, '2026-11-10T12:00:00Z');
      // GitHub 没有“最低支持版本”概念，恒为 null（不强制更新）
      expect(manifest.minSupportedVersion, isNull);
    });

    test('可选字段缺失不炸', () {
      final manifest = parseGitHubRelease('{"tag_name":"1.0.0"}');
      expect(manifest.latestVersion, '1.0.0');
      expect(manifest.downloadUrl, isNull);
      expect(manifest.releaseNotes, isEmpty);
      expect(manifest.publishedAt, isNull);
    });

    test('缺 tag_name → 抛 FormatException', () {
      expect(
        () => parseGitHubRelease('{"html_url":"x"}'),
        throwsA(isA<FormatException>()),
      );
    });

    test('tag_name 是空串 → 抛 FormatException', () {
      expect(
        () => parseGitHubRelease('{"tag_name":"  "}'),
        throwsA(isA<FormatException>()),
      );
    });

    test('不是 JSON 对象 → 抛 FormatException', () {
      expect(
        () => parseGitHubRelease('[]'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
