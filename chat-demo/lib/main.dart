import 'package:kit/kit.dart' show AppSettings;
import 'package:kit/kit_ui.dart' as ui;
import 'package:kit_agent/kit_agent.dart';
import 'package:material_ui/material_ui.dart';

import 'session.dart';

/// 桌面对话 demo：验证「前端 + skill + agent」这条链路能不能跑通。
///
/// 配置全走环境变量：ANTHROPIC_API_KEY（或 ANTHROPIC_AUTH_TOKEN）、ANTHROPIC_BASE_URL、ANTHROPIC_MODEL。
/// 加 `--fake` 走本地假运行时：不联网、不花钱、不需要 key，用来验证 UI 和事件流。
///
/// 对应 KMP `chat-demo/src/main/kotlin/com/androidkit/app/chat/Main.kt`。
/// 入口。加 `--fake` 走本地假运行时：不联网、不花钱、不需要 key。
void main(List<String> args) {
  final fake = args.contains('--fake');
  runApp(ChatDemoApp(fake: fake));
}

class ChatDemoApp extends StatefulWidget {
  const ChatDemoApp({super.key, required this.fake});

  final bool fake;

  @override
  State<ChatDemoApp> createState() => _ChatDemoAppState();
}

class _ChatDemoAppState extends State<ChatDemoApp> {
  final log = ChatLog();
  final inputC = TextEditingController();
  AgentSession? _session;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _session = createSession(widget.fake);
  }

  @override
  void dispose() {
    _session?.dispose();
    log.dispose();
    inputC.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final session = _session;
    if (session == null || _busy) return;
    final text = inputC.text.trim();
    if (text.isEmpty) return;
    inputC.clear();
    log.user(text);
    setState(() => _busy = true);
    try {
      await for (final ev in session.send(text)) {
        log.onEvent(ev);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ui.KitAppShell(
      settings: const AppSettings(),
      home: Scaffold(
        body: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Chat demo'),
            ),
            Expanded(child: ui.ChatMessageList(messages: ui.mapChatMessages(log.messages))),
            if (_session == null)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '没找到 API key：设置 ANTHROPIC_API_KEY（或 ANTHROPIC_AUTH_TOKEN）后重启窗口，'
                  '或加 --fake 走假运行时',
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: inputC,
                      enabled: !_busy,
                      maxLines: 4,
                      decoration: const InputDecoration(hintText: '说点什么…'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ui.PrimaryButton(
                    text: '发送',
                    enabled: !_busy && _session != null,
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
