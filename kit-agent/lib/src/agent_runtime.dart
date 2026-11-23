import 'agent_event.dart';
import 'skill_definition.dart';
import 'tool_approval.dart';
import 'engine/dart_agent_runtime.dart';
import 'engine/gateway_agent_runtime.dart';

/// agent 运行时的两种部署形态。
enum AgentMode {
  /// 本机 loop：dart_agent_core 跑在端上，模型走云端 API，工具默认跑在用户设备上。
  local,

  /// 后端 loop：调 `backend/` 网关，UI 不用改。
  gateway,
}

/// 契约：创建会话并收发事件流。
abstract class AgentRuntime {
  /// 为某个 skill 建一个会话。[approver] 是危险工具的执行前闸门（可空）。
  AgentSession session(SkillDefinition skill, {ToolApprover? approver});
}

/// 一次会话：发送用户输入，得到 [AgentEvent] 流。
abstract class AgentSession {
  /// 发送一句话，返回事件流（文本增量 / 工具调用 / 结果 / 错误）。
  Stream<AgentEvent> send(String input);

  /// 释放资源。
  void dispose();
}

/// 工厂：按形态创建运行时。
///
/// - [apiKey]：云端模型 key（local 模式用；gateway 模式不需要，用 [gatewayToken]）。
/// - [baseUrl]：local 模式可指向自建转发代理；gateway 模式指向 backend 网关。
/// - [gatewayToken]：gateway 模式的鉴权 token。
AgentRuntime createAgentRuntime(
  AgentMode mode, {
  required String apiKey,
  String? baseUrl,
  String? gatewayToken,
}) {
  return switch (mode) {
    AgentMode.local => DartAgentRuntime(apiKey: apiKey, baseUrl: baseUrl),
    AgentMode.gateway => GatewayAgentRuntime(
        baseUrl: baseUrl ?? 'http://localhost:8787',
        gatewayToken: gatewayToken ?? '',
      ),
  };
}
