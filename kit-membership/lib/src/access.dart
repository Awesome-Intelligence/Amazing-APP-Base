/// 能不能用：放行 / 被挡住。
sealed class Access {
  const Access();
}

/// 放行。
final class AccessAllowed extends Access {
  const AccessAllowed();
}

/// 被挡住。
///
/// [key] 被挡的权益点或额度 key；[limit] 这一档的上限（无上限的权益点为 -1）；
/// [reason] 挡住的原因。
final class AccessBlocked extends Access {
  final String key;
  final int limit;
  final BlockReason reason;

  const AccessBlocked(this.key, this.limit, this.reason);
}

/// 挡住的原因。
enum BlockReason {
  /// 没有这个权益点。
  noEntitlement,

  /// 额度超了。
  quotaExceeded,
}
