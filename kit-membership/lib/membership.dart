/// membership —— 平台无关的会员/付费框架。
///
/// 只管「谁是会员、能用多少」，不管「钱怎么收」。平台 SDK（Play Billing / StoreKit）
/// 不进此模块，各端 app 自己实现 [BillingProvider]。对应 KMP 的 `kit-membership/`。
library membership;

export 'src/plan.dart';
export 'src/membership_state.dart';
export 'src/access.dart';
export 'src/billing.dart';
export 'src/storage.dart';
export 'src/membership_store.dart';
export 'src/usage_tracker.dart';
export 'src/membership_manager.dart';
export 'src/plan_option.dart';
