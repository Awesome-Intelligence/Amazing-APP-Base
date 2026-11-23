/// 危险工具的审批闸门结果。
sealed class ToolApproval {
  const ToolApproval();
}

/// 这一次放行（默认档）。
final class Allow extends ToolApproval {
  const Allow();
}

/// 本任务免确认：这个工具名记进当前 session 的名单，以后不再问。
/// 范围是**一轮对话**（存在 session 里）；换 skill / 重启 app 都得重新问。
final class AllowAlways extends ToolApproval {
  const AllowAlways();
}

/// 拒绝：工具不执行，理由会作为工具结果回给模型，让它自己改道。
final class Deny extends ToolApproval {
  final String reason;
  const Deny(this.reason);
}

/// 工具执行前的闸门。返回 [Deny] 时工具根本没跑（执行前拦截，不是 UI 弹提示）。
///
/// 实现注意：闸门必须接在工具的真正执行前，而不是 UI 层。拒绝理由会作为工具结果
/// 回到模型，模型据此改道。
abstract class ToolApprover {
  /// [toolName] 工具名，[args] 入参。
  Future<ToolApproval> approve(String toolName, Map<String, Object?> args);
}

/// 全放行：只给"工具全是只读、无副作用"的 app 用。
class AllowAllApprover implements ToolApprover {
  const AllowAllApprover();

  @override
  Future<ToolApproval> approve(String toolName, Map<String, Object?> args) async =>
      const Allow();
}
