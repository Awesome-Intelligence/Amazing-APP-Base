/// agent_core —— Flutter 版的 agent 运行时底座。
///
/// 契约与 KMP `kit-agent-koog` 同构：SkillDefinition / SkillTool / AgentRuntime /
/// AgentEvent / ToolApprover / ChatLog / SkillContract / SkillSamples。
/// 底层框架（dart_agent_core）的耦合集中在 `engine/`，便于换版本或换框架。
export 'src/agent_event.dart';
export 'src/tool_output.dart';
export 'src/tool_approval.dart';
export 'src/skill_tool.dart';
export 'src/skill_definition.dart';
export 'src/agent_runtime.dart';
export 'src/chat_log.dart';
export 'src/skill_contract.dart';
export 'src/skill_samples.dart';
export 'src/fake_agent_runtime.dart';
export 'src/engine/dart_agent_runtime.dart';
export 'src/engine/gateway_agent_runtime.dart';
