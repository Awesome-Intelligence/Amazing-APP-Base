import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:kit/kit.dart' show AppSettings, MemoryStorageBackend, SettingsStore;
import 'package:kit/kit_ui.dart' show KitAppShell;

import 'home_shell.dart';
import 'update_gate.dart';

/// 当前版本号。
///
/// 真实项目从 `package_info_plus` 读（`PackageInfo.fromPlatform().version`），
/// demo 不想为了一个字符串再引一个平台插件 —— 这个常量就是那个值的替身。
/// 检查更新只拿它和清单里的 `latestVersion` 比，来源不影响逻辑。
const String demoAppVersion = '1.2.0';

void main() => runApp(const DemoApp());

/// demo 根：持有 [AppSettings]，交给 `KitAppShell` 定主题/文案/语言。
///
/// 设置状态必须放在 MaterialApp **之上** —— 换风格要重建整个 ThemeData，
/// 而 MaterialApp 内部的树拿不到「某个 state 变了」这件事。
///
/// 存储用内存后端：这是演示。真实 app 换成平台后端即可 ——
/// 移动端/桌面用 `FileStorageBackend`，Web 用 localStorage 实现，
/// 都是同一个 [SettingsStore]，本文件只改一行。
class DemoApp extends StatefulWidget {
  const DemoApp({super.key});

  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  final SettingsStore _store = SettingsStore(MemoryStorageBackend());
  AppSettings _settings = const AppSettings();

  @override
  void initState() {
    super.initState();
    _restore();
  }

  /// 读上次的设置。读到之前先按默认值渲染，读到了再刷 —— 不阻塞首帧。
  Future<void> _restore() async {
    final saved = await _store.load();
    if (mounted) setState(() => _settings = saved);
  }

  void _update(AppSettings next) {
    setState(() => _settings = next);
    unawaited(_store.save(next));
  }

  @override
  Widget build(BuildContext context) {
    return KitAppShell(
      title: '待办助手',
      settings: _settings,
      // 更新闸门包在业务页面外面：冷启动先查一次，有新版本就弹窗。
      // 没配 --dart-define=UPDATE_* 时完全静默（内测包的正常状态）。
      home: UpdateGate(
        currentVersion: demoAppVersion,
        child: HomeShell(
          settings: _settings,
          onSettingsChange: _update,
        ),
      ),
    );
  }
}
