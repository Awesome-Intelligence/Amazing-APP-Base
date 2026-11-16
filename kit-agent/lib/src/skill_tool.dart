import 'tool_output.dart';

/// skill 的工具基类。工具就是 Dart 类，入参是 Map（由 engine 转成 JSON Schema）。
///
/// 对应 KMP 的 `SkillTool`（继承 Koog `ToolBase`，`@Serializable` 入参 → 自动 schema）。
/// 这里手写 [jsonSchema]（等价于 KMP 的 `@Serializable` 数据类），后续可加代码生成。
abstract class SkillTool {
  final String name;
  final String description;
  const SkillTool(this.name, this.description);

  /// 危险工具（删数据、外发数据）应返回 true，执行前走 [ToolApprover] 闸门。
  bool get requiresApproval => false;

  /// 工具的 JSON Schema（入参描述）。默认空对象；覆盖它以声明参数。
  Map<String, Object?> get jsonSchema => const {
        'type': 'object',
        'properties': <String, Object?>{},
        'required': <String>[],
      };

  /// 执行工具。入参已解析为 Map；返回文本结果。
  Future<ToolOutput> execute(Map<String, Object?> args);
}
