/// 会员状态（本地持久化的那点东西）。
///
/// 权益和额度**不在这里** —— 那些在 [PlanCatalog] 的档位表里；
/// 状态只记「当前是哪个档、到什么时候为止、这笔买没验过签」。
class Membership {
  /// 当前生效的档位 id。
  final String planId;

  /// 到期时间（毫秒时间戳）；null = 不过期（免费档 / 买断）。
  final int? expiresAt;

  /// 购买结果是否通过校验（回执验签 / 跟服务端核对过）。没校验过的购买不给开会员。
  final bool verified;

  const Membership({
    required this.planId,
    this.expiresAt,
    this.verified = false,
  });

  /// 到期前都算有效。
  bool isActive(int now) => expiresAt == null || expiresAt! > now;

  /// 免费档的初始状态。
  static Membership free([String planId = 'free']) =>
      Membership(planId: planId, expiresAt: null, verified: true);

  Map<String, dynamic> toJson() => {
        'planId': planId,
        'expiresAt': expiresAt,
        'verified': verified,
      };

  factory Membership.fromJson(Map<String, dynamic> json) => Membership(
        planId: json['planId'] as String,
        expiresAt: json['expiresAt'] as int?,
        verified: json['verified'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      other is Membership &&
      other.planId == planId &&
      other.expiresAt == expiresAt &&
      other.verified == verified;

  @override
  int get hashCode => planId.hashCode ^ expiresAt.hashCode ^ verified.hashCode;
}
