/// 额度的周期。
///
/// - [daily]：每天重置（"今天最多问 20 次 AI"）
/// - [total]：永不过期（"最多保存 100 个目标"）
enum QuotaPeriod { daily, total }

/// 一项额度的上限。
class QuotaLimit {
  final int limit;
  final QuotaPeriod period;

  const QuotaLimit(this.limit, this.period);

  Map<String, dynamic> toJson() => {'limit': limit, 'period': period.name};

  factory QuotaLimit.fromJson(Map<String, dynamic> json) => QuotaLimit(
        json['limit'] as int,
        QuotaPeriod.values.byName(json['period'] as String),
      );

  @override
  bool operator ==(Object other) =>
      other is QuotaLimit && other.limit == limit && other.period == period;

  @override
  int get hashCode => limit.hashCode ^ period.hashCode;
}

/// 一个档位（也对应商店里的一个商品）。
///
/// 档位表是**业务侧的一张表**，写在代码里（编译期可查），不从服务器下发 ——
/// 下发的话额度上限能被随便改。
class Plan {
  /// 商品 id，和商店里的商品 id 对齐（"premium_monthly"）
  final String id;

  /// 档位等级，数字越大权益越高；0 = 免费档
  final int tier;

  /// 权益点（功能开关），key 由业务定义（"export"、"priority_support"）
  final Set<String> entitlements;

  /// 额度上限表：额度 key -> 上限。key 不在表里 = 不限
  final Map<String, QuotaLimit> limits;

  const Plan({
    required this.id,
    required this.tier,
    this.entitlements = const {},
    this.limits = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'tier': tier,
        'entitlements': entitlements.toList(),
        'limits': limits.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory Plan.fromJson(Map<String, dynamic> json) => Plan(
        id: json['id'] as String,
        tier: json['tier'] as int,
        entitlements: {...(json['entitlements'] as List?)?.cast<String>() ?? <String>[]},
        limits: {
          for (final e in (json['limits'] as Map?)?.entries ?? <MapEntry>[])
            e.key as String: QuotaLimit.fromJson(e.value as Map<String, dynamic>)
        },
      );

  @override
  bool operator ==(Object other) =>
      other is Plan &&
      other.id == id &&
      other.tier == tier &&
      other.entitlements == entitlements &&
      other.limits == limits;

  @override
  int get hashCode =>
      id.hashCode ^ tier ^ entitlements.hashCode ^ limits.hashCode;
}

/// 档位表 —— 业务侧一张表配出来，框架只认这张表。
class PlanCatalog {
  /// 所有档位，按等级从低到高。
  final List<Plan> all;

  /// 付费档，按等级从低到高。
  final List<Plan> paid;

  final Map<String, Plan> _index;

  PlanCatalog(List<Plan> plans)
      : all = [...plans]..sort((a, b) => a.tier.compareTo(b.tier)),
        paid = plans.where((p) => p.tier > 0).toList(),
        _index = {for (final p in plans) p.id: p} {
    if (!all.any((p) => p.tier == 0)) {
      throw StateError('PlanCatalog 里必须有一个 tier = 0 的免费档');
    }
  }

  /// 免费档。会员过期就回退到它。
  Plan get free => all.firstWhere((p) => p.tier == 0);

  /// 按 id 找档位；找不到返回 null。
  Plan? byId(String id) => _index[id];
}
