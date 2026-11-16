import 'package:kit_agent/kit_agent.dart';

/// 演示工具：让模型能问当前时间，顺带验证工具调用链路。
class NowTool extends SkillTool {
  NowTool() : super('now', '获取当前时间');

  @override
  Map<String, Object?> get jsonSchema => {
        'type': 'object',
        'properties': {
          'note': {'type': 'string'},
        },
        'required': <String>[],
      };

  @override
  Future<ToolOutput> execute(Map<String, Object?> args) async =>
      ToolOutput.text(DateTime.now().toString());
}
