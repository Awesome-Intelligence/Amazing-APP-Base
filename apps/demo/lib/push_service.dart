import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:kit/kit.dart';

/// 推送配置 —— 全部来自 `--dart-define`，代码里不写死。
///
/// ```
/// flutter run \
///   --dart-define=NTFY_SERVER=https://ntfy.sh \
///   --dart-define=NTFY_TOPIC=my-app \
///   --dart-define=GATEWAY_URL=http://127.0.0.1:8787 \
///   --dart-define=GATEWAY_TOKEN=xxx
/// ```
class PushConfig {
  const PushConfig({
    this.ntfyServer = '',
    this.ntfyTopic = '',
    this.ntfyToken = '',
    this.gatewayUrl = '',
    this.gatewayToken = '',
    this.firebaseApiKey = '',
    this.firebaseAppId = '',
    this.firebaseSenderId = '',
    this.firebaseProjectId = '',
  });

  final String ntfyServer;
  final String ntfyTopic;
  final String ntfyToken;
  final String gatewayUrl;
  final String gatewayToken;
  final String firebaseApiKey;
  final String firebaseAppId;
  final String firebaseSenderId;
  final String firebaseProjectId;

  /// 从编译期常量读配置。
  static const PushConfig fromEnv = PushConfig(
    ntfyServer: String.fromEnvironment('NTFY_SERVER'),
    ntfyTopic: String.fromEnvironment('NTFY_TOPIC'),
    ntfyToken: String.fromEnvironment('NTFY_TOKEN'),
    gatewayUrl: String.fromEnvironment('GATEWAY_URL'),
    gatewayToken: String.fromEnvironment('GATEWAY_TOKEN'),
    firebaseApiKey: String.fromEnvironment('FIREBASE_API_KEY'),
    firebaseAppId: String.fromEnvironment('FIREBASE_APP_ID'),
    firebaseSenderId: String.fromEnvironment('FIREBASE_SENDER_ID'),
    firebaseProjectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
  );

  /// 配了 ntfy 就能收（纯 HTTP，任何平台都行）。
  bool get hasNtfy => ntfyServer.isNotEmpty && ntfyTopic.isNotEmpty;

  /// 配了 Firebase 就能收后台推送（应用被杀也能到）。
  bool get hasFirebase =>
      firebaseApiKey.isNotEmpty &&
      firebaseAppId.isNotEmpty &&
      firebaseSenderId.isNotEmpty;

  /// 网关地址 —— 用来登记 FCM token。
  bool get hasGateway => gatewayUrl.isNotEmpty;
}

/// 推送接入（**app 层** —— 平台能力归 app，见 `rules/KIT-NOTES.md` 〇.k）。
///
/// 两条通道进来，最后都落到同一份站内消息：
/// - **ntfy**：轮询拉取。纯 HTTP、零凭据，web / 桌面 / 移动端都能用；
///   代价是应用被杀时收不到（没有系统级唤醒）。
/// - **FCM**：系统级推送。应用被杀也能到；没配 Firebase 就整条路是哑的。
///
/// 收到之后：写 [NotificationStore]（角标 + 消息中心）+ 弹一条系统通知。
class PushService {
  PushService({
    required this.store,
    required this.onChanged,
    this.config = PushConfig.fromEnv,
  });

  /// 站内消息仓库（底座的数据层）。
  final NotificationStore store;

  /// 写完消息之后通知外面 —— 底栏角标要跟着变。
  final VoidCallback onChanged;

  final PushConfig config;

  final _plugin = FlutterLocalNotificationsPlugin();

  /// 已经收过的消息 id —— 重发不重复弹通知。
  final _seen = <String>{};

  Timer? _pollTimer;
  String? _since;
  int _nextSystemId = 0;

  /// 启动。什么都没配就什么都不做（demo 默认状态）。
  Future<void> start() async {
    // 启动时先把已有的 id 记下来：重启后重拉到同一条，不该再弹一次。
    for (final n in await store.list()) {
      _seen.add(n.id);
    }
    await _initSystemNotifications();
    await _startFcm();
    _startNtfyPolling();
  }

  /// 停掉轮询。
  void dispose() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /* ── 系统通知 ───────────────────────────────────────────── */

  Future<void> _initSystemNotifications() async {
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
          macOS: DarwinInitializationSettings(),
          linux: LinuxInitializationSettings(defaultActionName: '打开'),
          windows: WindowsInitializationSettings(
            appName: '待办助手',
            appUserModelId: 'com.androidkit.demo',
            guid: '9f8c2a1e-6b3d-4f5a-9c8e-1d2b3a4c5d6e',
          ),
        ),
      );
      // 权限：Android 13+ 要用户点头，iOS/macOS 要系统弹窗，web 要浏览器授权。
      if (kIsWeb) {
        await _plugin
            .resolvePlatformSpecificImplementation<
                WebFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      } else if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        await _plugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      }
    } catch (e) {
      debugPrint('系统通知初始化失败：$e');
    }
  }

  /// 弹一条系统通知。失败只记日志 —— 通知不是主流程，不能让它把接收链路带崩。
  Future<void> showSystem({
    required String title,
    required String body,
  }) async {
    try {
      await _plugin.show(
        id: _nextSystemId++,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'default',
            '默认',
            channelDescription: '助手回复与系统通知',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('系统通知失败：$e');
    }
  }

  /* ── ntfy ──────────────────────────────────────────────── */

  void _startNtfyPolling() {
    if (!config.hasNtfy) return;
    final client = NtfyClient(
      server: config.ntfyServer,
      topic: config.ntfyTopic,
      token: config.ntfyToken.isEmpty ? null : config.ntfyToken,
    );
    // ponytail: 固定 15 秒轮询。量大了就换 ntfy 的长连接 / 上 FCM，
    //         现在这个量级轮询最省事。
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      try {
        final items = await client.fetch(since: _since);
        if (items.isEmpty) return;
        // items 是倒序（新的在前）：since 记最新那条，下次只拉它之后的。
        _since = items.first.id;
        for (final n in items.reversed) {
          await _ingest(
            id: n.id,
            title: n.title.isEmpty ? '新消息' : n.title,
            body: n.body,
            createdAt: n.createdAt,
          );
        }
      } catch (e) {
        debugPrint('ntfy 拉取失败：$e');
      }
    });
  }

  /* ── FCM ───────────────────────────────────────────────── */

  Future<void> _startFcm() async {
    if (!config.hasFirebase) return;
    try {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: config.firebaseApiKey,
          appId: config.firebaseAppId,
          messagingSenderId: config.firebaseSenderId,
          projectId: config.firebaseProjectId,
        ),
      );
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      // 应用在前台：FCM 不会自动弹通知（那是后台的行为），我们自己弹。
      FirebaseMessaging.onMessage.listen((m) {
        _ingest(
          id: m.messageId ?? 'fcm-${DateTime.now().microsecondsSinceEpoch}',
          title: m.notification?.title ?? m.data['title'] ?? '新消息',
          body: m.notification?.body ?? m.data['body'] ?? '',
        );
      });
      // 应用在后台/被杀时收到带 notification 的消息 —— 系统自动弹，不用管。
      // ponytail: v17 把 getToken/onTokenRefresh 标成废弃、推荐 register()/onRegistered，
      //   但 register 给的是 FID（安装 ID），FCM v1 的 messages:send 只认注册 token
      //   —— 这里仍用老的这对 API，等上游把 FID 也能当目标再说。
      // ignore: deprecated_member_use
      final token = await messaging.getToken();
      if (token != null) await _registerDevice(token);
      // ignore: deprecated_member_use
      messaging.onTokenRefresh.listen(_registerDevice);
    } catch (e) {
      debugPrint('FCM 初始化失败（Firebase 没配对？）：$e');
    }
  }

  /// 把 FCM token 登记到网关 —— 网关才知道往哪儿推。
  Future<void> _registerDevice(String token) async {
    if (!config.hasGateway) return;
    try {
      await http.post(
        Uri.parse('${config.gatewayUrl}/v1/devices'),
        headers: {
          'content-type': 'application/json',
          if (config.gatewayToken.isNotEmpty)
            'authorization': 'Bearer ${config.gatewayToken}',
        },
        body: '{"token":"$token"}',
      );
    } catch (e) {
      debugPrint('设备登记失败：$e');
    }
  }

  /* ── 收口 ───────────────────────────────────────────────── */

  /// 收到一条远端消息 → 落库 + 弹系统通知 + 刷新角标。
  Future<void> _ingest({
    required String id,
    required String title,
    required String body,
    DateTime? createdAt,
  }) async {
    if (!_seen.add(id)) return; // 同一条重发，忽略
    await store.add(id: id, title: title, body: body, createdAt: createdAt);
    await showSystem(title: title, body: body);
    onChanged();
  }
}
