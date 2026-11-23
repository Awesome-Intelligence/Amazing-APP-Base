import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:kit/kit.dart' show AppSettings, MemoryStorageBackend, SettingsStore;
import 'package:kit/kit_ui.dart' show KitAppShell;

import 'app_router.dart';
import 'demo_store.dart';
import 'push_service.dart';

/// 当前版本号。
///
/// 真实项目从 `package_info_plus` 读（`PackageInfo.fromPlatform().version`），
/// demo 不想为了一个字符串再引一个平台插件 —— 这个常量就是那个值的替身。
/// 检查更新只拿它和清单里的 `latestVersion` 比，来源不影响逻辑。
const String demoAppVersion = '1.2.0';

void main() => runApp(const DemoApp());

/// demo 根：持有设置和路由，交给 `KitAppShell` 定主题/文案/语言。
///
/// 设置状态必须放在 MaterialApp **之上** —— 换风格要重建整个 ThemeData，
/// 而 MaterialApp 内部的树拿不到「某个 state 变了」这件事。
///
/// 路由也在这里创建（`GoRouter` 是长生命周期的，不能每次 build 都新建），
/// 四个页签各一个分支，见 `app_router.dart`。
///
/// 存储用内存后端：这是演示。真实 app 换成平台后端即可 ——
/// 移动端/桌面用 `FileStorageBackend`，Web 用 localStorage 实现，
/// 都是同一个 [SettingsStore]，本文件只改一行。
class DemoApp extends StatefulWidget {
  const DemoApp({super.key, this.store});

  /// 塞一个自己的 [DemoStore] 进来（测试断言设置变化时用）。
  final DemoStore? store;

  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  final SettingsStore _settingsStore = SettingsStore(MemoryStorageBackend());
  late final DemoStore _store = widget.store ?? DemoStore();
  late final GoRouter _router = createDemoRouter(
    _store,
    appVersion: demoAppVersion,
  );

  /// 上次落盘的值 —— 只有设置变了才写盘（收到一条通知不用写）。
  AppSettings _persisted = const AppSettings();

  /// 推送接入：ntfy / FCM 收到消息 → 站内消息 + 系统通知。
  ///
  /// 平台能力归 app 层（见 `rules/KIT-NOTES.md` 〇.k）——
  /// 底座只提供数据层（`NotificationStore`）和 ntfy 的 HTTP 客户端。
  late final PushService _push = PushService(
    store: _store.notifications,
    onChanged: _store.reloadNotifications,
  );

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStoreChanged);
    _restore();
    unawaited(_push.start());
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    _push.dispose();
    _router.dispose();
    super.dispose();
  }

  /// 读上次的设置。读到之前先按默认值渲染，读到了再刷 —— 不阻塞首帧。
  ///
  /// 没存过就**不动**：默认设置和「上次存的就是默认值」分不开，
  /// 拿默认值盖回去会把当前设置（测试塞进来的、启动后立刻改的）刷没。
  Future<void> _restore() async {
    final raw = await _settingsStore.backend.read();
    if (!mounted || raw == null) return;
    final saved = await _settingsStore.load();
    if (!mounted) return;
    _store.updateSettings(saved);
  }

  void _onStoreChanged() {
    if (!mounted) return;
    // 主题跟着设置走：MaterialApp 在下面，得由根重建。
    setState(() {});
    if (_persisted != _store.settings) {
      _persisted = _store.settings;
      unawaited(_settingsStore.save(_store.settings));
    }
  }

  @override
  Widget build(BuildContext context) {
    return KitAppShell(
      title: '待办助手',
      settings: _store.settings,
      routerConfig: _router,
    );
  }
}
