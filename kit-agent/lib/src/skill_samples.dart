import 'skill_definition.dart';

/// 黄金样例：工具名 + 入参 JSON + 期望返回里的一段话。不调模型就能跑。
/// 样例表跑的是**工具这一层**（工具名、入参、返回值），不调模型 —— 不花钱、不连网、结果稳定。
class SkillSample {
  final String toolName;
  final Map<String, Object?> args;
  final String expects; // 期望结果里包含的片段

  const SkillSample(this.toolName, this.args, this.expects);
}

/// 一条失败记录。
final class SampleFailure {
  final String toolName;
  final String reason;
  const SampleFailure(this.toolName, this.reason);
}

/// 跑黄金样例，返回所有失败。
Future<List<SampleFailure>> runSamples(
  SkillDefinition skill,
  List<SkillSample> samples,
) async {
  final failures = <SampleFailure>[];
  final toolByName = {for (final t in skill.tools) t.name: t};

  for (final sample in samples) {
    final tool = toolByName[sample.toolName];
    if (tool == null) {
      failures.add(SampleFailure(sample.toolName, '找不到工具: ${sample.toolName}'));
      continue;
    }
    try {
      final out = await tool.execute(sample.args);
      if (!out.text.contains(sample.expects)) {
        failures.add(SampleFailure(
          sample.toolName,
          '期望包含 "${sample.expects}"，实际: "${out.text}"',
        ));
      }
    } on Object catch (e) {
      failures.add(SampleFailure(sample.toolName, '执行抛异常: $e'));
    }
  }
  return failures;
}
