import 'package:material_ui/material_ui.dart';
import 'package:http/http.dart' as http;
import 'package:kit/kit.dart';
import 'package:kit/kit_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import 'update_state_store_factory.dart';

/// 构建期配置（`--dart-define=UPDATE_GITHUB_REPO=owner/repo`）。
///
/// 两者都空 = 完全不检查更新 —— 内测包常见，避免打扰。
/// 清单 URL 优先：只有它才支持「最低支持版本」（强制更新）。
const String _manifestUrl = String.fromEnvironment('UPDATE_MANIFEST_URL');
const String _githubRepo = String.fromEnvironment('UPDATE_GITHUB_REPO');

/// 「启动时自动发现新版本」的接线示例（app 层，不是 kit 的一部分）。
///
/// 做的事只有三件：
/// 1. 冷启动时调一次 `UpdateChecker.check(currentVersion)` —— 节流在 checker 里，
///    不会每次启动都联网
/// 2. 有新版本就弹 kit 的 [UpdateDialog]
/// 3. 用户选“跳过此版本”时落盘（下次出现更新的版本会重新提示）
///
/// “立即更新”在这里是打开浏览器/应用商店 —— 各端 App 自己换实现
/// （Android 也可以接 in_app_update / Play Core）。
///
/// [checker] 传 null 表示不检查（默认按 `--dart-define` 判断）；
/// 测试传一个假来源就能验证整条交互，不联网。
class UpdateGate extends StatefulWidget {
  const UpdateGate({
    super.key,
    required this.currentVersion,
    required this.child,
    this.checker,
    this.onOpenDownload,
    this.checkOnStart = true,
  });

  /// 当前版本号（`1.2.0`）。真实项目从 package_info_plus / 构建注入读。
  final String currentVersion;

  final Widget child;

  /// 显式注入的检查器；null 时按 `--dart-define` 自动创建（都没配就不检查）。
  final UpdateChecker? checker;

  /// 打开下载地址。默认走 `url_launcher`，测试里可替换。
  final Future<void> Function(String url)? onOpenDownload;

  /// 关掉自动检查（单测里想单独测 UI 时用）。
  final bool checkOnStart;

  @override
  State<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends State<UpdateGate> {
  http.Client? _client;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    if (widget.checkOnStart) {
      // 等首帧：弹窗需要 Navigator / Overlay，initState 里还没有
      WidgetsBinding.instance.addPostFrameCallback((_) => _check());
    }
  }

  @override
  void dispose() {
    _client?.close();
    super.dispose();
  }

  Future<void> _check() async {
    if (_checking) return;
    _checking = true;
    try {
      final checker = widget.checker ?? await _createChecker();
      if (checker == null || !mounted) return;

      // 失败/节流/已最新都静默：更新检查不该打扰正在用 app 的人
      final result = await checker.check(widget.currentVersion);
      if (!mounted) return;
      if (result is AvailableResult) await _prompt(checker, result);
    } finally {
      _checking = false;
    }
  }

  /// 弹窗循环：强制更新时选完“立即更新”仍然继续挡着 ——
  /// 用户从浏览器回来还在旧版本，闸门不该放他过去。
  Future<void> _prompt(UpdateChecker checker, AvailableResult available) async {
    final manifest = available.manifest;
    final url = manifest.downloadUrl ?? '';
    final canUpdate = url.isNotEmpty;

    // 清单要求强制更新、却没给下载地址：别把用户卡死在死胡同里，降级成可关闭
    final mandatory = available.mandatory && canUpdate;

    while (mounted) {
      // 上一轮 await 之后必须重新确认还挂着：用户可能在浏览器/后台页面待了一会儿，
      // 这个 State 已经被 dispose 了（`while (mounted)` 不足以让分析器认账）
      if (!mounted) return;
      final choice = await UpdateDialog.show(
        context,
        latestVersion: manifest.latestVersion,
        currentVersion: widget.currentVersion,
        releaseNotes: manifest.releaseNotes,
        mandatory: mandatory,
        updateEnabled: canUpdate,
        allowSkip: !mandatory,
      );
      if (!mounted) return;

      switch (choice) {
        case UpdateChoice.update:
          await _openDownload(url);
          if (!mandatory) return;
        // 强制更新：不 return，回到 while 顶部再挡一次
        case UpdateChoice.skip:
          await checker.skip(manifest.latestVersion);
          return;
        case UpdateChoice.later:
        case null:
          return;
      }
    }
  }

  Future<void> _openDownload(String url) async {
    final open = widget.onOpenDownload ?? _launchExternally;
    try {
      await open(url);
    } on Exception {
      // 没有能处理的应用 / 用户取消：静默算了 —— 更新提示不该把 app 弄崩
    }
  }

  static Future<void> _launchExternally(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// 按构建配置选版本源；两个都没配就返回 null（内测包常见：完全不检查）。
  Future<UpdateChecker?> _createChecker() async {
    if (_manifestUrl.isEmpty && _githubRepo.isEmpty) return null;

    final store = await createUpdateStateStore();
    final client = _client ??= http.Client();
    final UpdateSource source = _manifestUrl.isNotEmpty
        ? HttpUpdateSource(client, _manifestUrl)
        : GitHubReleaseSource(client, _githubRepo);
    return UpdateChecker(source: source, stateStore: store);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
