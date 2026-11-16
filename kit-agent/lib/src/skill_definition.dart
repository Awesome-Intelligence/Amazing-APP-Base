import 'skill_tool.dart';

/// skill = systemPrompt + 工具集 + 模型 / maxTurns 配置（代码定义，编译期可查）。
/// 对应 KMP 的 `SkillDefinition`。
///
/// 注意：skill 是运行期东西（人设 + 工具集），没有编译期保障；底座给了两道可跑的
/// 检查：[SkillContract.violations]（静态体检）+ [SkillSamples.runSamples]（黄金样例）。
class SkillDefinition {
  final String id;
  final String name;
  final String description;
  final String systemPrompt;
  final List<SkillTool> tools;
  final String model;
  final int maxTurns;

  const SkillDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.systemPrompt,
    required this.tools,
    this.model = 'claude-sonnet-4-5',
    this.maxTurns = 20,
  });
}
