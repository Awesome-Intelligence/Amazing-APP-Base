import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../agent_event.dart';
import '../agent_runtime.dart';
import '../skill_definition.dart';
import '../tool_approval.dart';

/// 后端网关运行时：agent loop 跑在 `backend/` 网关（TypeScript），客户端只收事件流。
/// UI 用法与 local 完全一致（`createAgentRuntime(AgentMode.gateway, ...)`）。
///
/// 网关协议：按 `skill.id` 调 `/v1/skills/<id>/invoke`，
/// 按 `sessionId` 续接；网关手拆 SSE。
class GatewayAgentRuntime implements AgentRuntime {
  final String baseUrl;
  final String gatewayToken;

  const GatewayAgentRuntime({
    required this.baseUrl,
    required this.gatewayToken,
  });

  @override
  AgentSession session(SkillDefinition skill, {ToolApprover? approver}) {
    return _GatewayAgentSession(
      skill: skill,
      baseUrl: baseUrl,
      gatewayToken: gatewayToken,
      approver: approver,
    );
  }
}

class _GatewayAgentSession implements AgentSession {
  final SkillDefinition skill;
  final String baseUrl;
  final String gatewayToken;
  final ToolApprover? approver;
  String? _sessionId;

  _GatewayAgentSession({
    required this.skill,
    required this.baseUrl,
    required this.gatewayToken,
    this.approver,
  });

  @override
  Stream<AgentEvent> send(String input) async* {
    final uri = Uri.parse('$baseUrl/v1/skills/${skill.id}/invoke');
    final request = http.Request('POST', uri)
      ..headers['Authorization'] = 'Bearer $gatewayToken'
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({
        'input': input,
        if (_sessionId != null) 'sessionId': _sessionId,
      });

    final response = await http.Client().send(request);
    if (response.statusCode != 200) {
      yield AgentEventError('网关返回 ${response.statusCode}');
      return;
    }

    // 手拆 SSE（data: 行）。
    await for (final r in parseGatewaySse(
      response.stream.transform(utf8.decoder).transform(const LineSplitter()),
    )) {
      if (r.sessionId != null) _sessionId = r.sessionId;
      final ev = r.event;
      if (ev != null) yield ev;
    }
  }

  @override
  void dispose() {
    _sessionId = null;
  }
}

/// 网关事件 → (AgentEvent?, sessionId?)。
///
/// `start` 只带 sessionId（网关用来续接会话），没有对应的 AgentEvent；
/// 其余事件跟 kit 的 AgentEvent 一一对应。顶层函数是为了能直接喂假 SSE 测
/// （`test/gateway_protocol_test.dart`）。
///
/// 协议另一头是 `backend/src/agent.ts` 的 `GatewayEvent` ——
/// `scripts/verify_gateway.py` 盯着两边的事件名和字段对不对得上。
({AgentEvent? event, String? sessionId}) mapGatewayEvent(Map<String, Object?> data) {
  final type = data['type'] as String?;
  switch (type) {
    case 'start':
      return (event: null, sessionId: data['sessionId'] as String?);
    case 'text':
      return (event: AgentEventText(data['text'] as String? ?? ''), sessionId: null);
    case 'tool_use':
      return (
        event: AgentEventToolUse(
          data['name'] as String? ?? '',
          (data['args'] as Map?)?.cast<String, Object?>() ?? const <String, Object?>{},
        ),
        sessionId: null,
      );
    case 'tool_done':
      return (
        event: AgentEventToolDone(data['name'] as String? ?? '', data['result'] as String? ?? ''),
        sessionId: null,
      );
    case 'tool_failed':
      return (
        event: AgentEventToolFailed(data['name'] as String? ?? '', data['message'] as String? ?? ''),
        sessionId: null,
      );
    case 'result':
      return (event: AgentEventResult(data['text'] as String? ?? ''), sessionId: null);
    case 'error':
      return (event: AgentEventError(data['message'] as String? ?? 'unknown'), sessionId: null);
    default:
      return (event: null, sessionId: null);
  }
}

/// SSE 行流 → 网关事件。真实运行时喂 response.stream，假 SSE 字符串直接喂这个。
Stream<({AgentEvent? event, String? sessionId})> parseGatewaySse(Stream<String> lines) async* {
  await for (final line in lines) {
    if (!line.startsWith('data:')) continue;
    final payload = line.substring(5).trim();
    if (payload.isEmpty) continue;
    yield mapGatewayEvent(jsonDecode(payload) as Map<String, Object?>);
  }
}
