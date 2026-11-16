import 'skill_definition.dart';

/// skill 的静态体检。对应 KMP 的 `SkillContract.violations()`。
///
/// skill 化没有编译期保障，这是它的"类型检查"之一。app 单测里
/// `assertTrue(violations(skill).isEmpty())`。
List<String> violations(SkillDefinition skill) {
  final out = <String>[];

  if (skill.id.isEmpty) out.add('skill.id 为空');
  if (skill.name.isEmpty) out.add('skill.name 为空');
  if (skill.description.isEmpty) out.add('skill.description 为空');
  if (skill.maxTurns <= 0) out.add('skill.maxTurns 非正: ${skill.maxTurns}');

  final seen = <String>{};
  for (final tool in skill.tools) {
    if (!_isSnakeCase(tool.name)) {
      out.add('工具名不是 snake_case: ${tool.name}');
    }
    if (!seen.add(tool.name)) {
      out.add('工具重名: ${tool.name}');
    }
  }
  return out;
}

bool _isSnakeCase(String s) {
  if (s.isEmpty) return false;
  return RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(s);
}
