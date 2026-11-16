/// **跨端契约** —— 一份 JSON，两端各实现一遍，行为不许分叉。
///
/// 背景：同一个业务要跑在几个界面上（Android / iOS / Desktop / 微信小程序）。
/// 界面各写各的，只有「业务动作 + 结果文案」是共享的 —— 那部分写成一份契约文件，
/// 各端各写一份动作表，然后**跑同一批黄金样例**：谁的行为和文案变了，红的就是谁。
///
/// 和 skill 的 `SkillSample` 是同一套思路，但**不依赖 agent** ——
/// 没有 agent 的端（微信小程序）也能用。
class ActionSample {
  /// 动作名 —— 各端动作表里的 key，必须一模一样。
  final String action;

  /// 入参（JSON 对象）。
  final Map<String, dynamic> input;

  /// 期望结果文案里包含的片段。
  final String expect;

  const ActionSample({
    required this.action,
    this.input = const {},
    required this.expect,
  });

  Map<String, dynamic> toJson() =>
      {'action': action, 'input': input, 'expect': expect};

  factory ActionSample.fromJson(Map<String, dynamic> json) => ActionSample(
        action: json['action'] as String,
        input: Map<String, dynamic>.from(json['input'] as Map? ?? const {}),
        expect: json['expect'] as String,
      );
}

/// 一份契约文件。
class ActionContract {
  /// 格式版本 —— 以后要改结构就 +1。
  final int version;

  /// 样例表。
  final List<ActionSample> actions;

  const ActionContract({this.version = 1, this.actions = const []});

  Map<String, dynamic> toJson() => {
        'version': version,
        'actions': actions.map((e) => e.toJson()).toList(),
      };

  factory ActionContract.fromJson(Map<String, dynamic> json) => ActionContract(
        version: json['version'] as int? ?? 1,
        actions: [
          for (final e in (json['actions'] as List? ?? const []))
            ActionSample.fromJson(Map<String, dynamic>.from(e as Map)),
        ],
      );
}

/// 一条样例没过。
class ActionFailure {
  /// 没过的样例。
  final ActionSample sample;

  /// 说清楚哪儿不对。
  final String reason;

  const ActionFailure(this.sample, this.reason);

  @override
  String toString() => 'ActionFailure(${sample.action}: $reason)';
}

/// 动作表：action 名 → (入参) → 结果文案。
typedef ActionMap = Map<String, String Function(Map<String, dynamic> input)>;

/// 跑一批契约样例，返回失败项（空列表 = 全过）。
///
/// 动作表没有这个动作、执行抛异常、结果文案对不上 —— 三种都算失败。
///
/// [contract] 契约（一般从 `contract/actions.json` 读出来）。
/// [newActions] 动作表工厂 —— **每条样例都重新调一次**，保证每条样例从干净状态开始，
///             样例之间互不影响（否则加一条样例就得重排后面的）。
List<ActionFailure> runActionSamples(
  ActionContract contract,
  ActionMap Function() newActions,
) {
  final failures = <ActionFailure>[];
  for (final sample in contract.actions) {
    final action = newActions()[sample.action];
    if (action == null) {
      failures.add(ActionFailure(sample, '动作表里没有动作 "${sample.action}"'));
      continue;
    }
    final String result;
    try {
      result = action(sample.input);
    } catch (e) {
      failures.add(ActionFailure(sample, '执行失败：$e'));
      continue;
    }
    if (!result.contains(sample.expect)) {
      failures.add(
          ActionFailure(sample, '返回里没有 "${sample.expect}"，实际是：$result'));
    }
  }
  return failures;
}

/// 异步动作表：action 名 → (入参) → 结果文案（Future）。
typedef AsyncActionMap = Map<String, Future<String> Function(Map<String, dynamic> input)>;

/// [runActionSamples] 的异步版 —— 动作背后要碰存储/网络时用。
///
/// 为什么单独一个函数而不是把同步版改成 `FutureOr`：
/// 小程序端（`logic/actions.js`）和纯内存逻辑本来就是同步的，
/// 强行让它们 `await` 只会让样例代码更难读；而 Flutter 的业务层
/// （`TodoStore` → `EntityStore`）是真的 async，同步版接不上。
/// 两套各留一个，调用方按自己的动作表选。
///
/// 语义与同步版逐条对齐：每条样例重新取一次动作表（干净状态）、
/// 缺动作 / 抛异常 / 文案不符都记一条失败。
Future<List<ActionFailure>> runAsyncActionSamples(
  ActionContract contract,
  AsyncActionMap Function() newActions,
) async {
  final failures = <ActionFailure>[];
  for (final sample in contract.actions) {
    final action = newActions()[sample.action];
    if (action == null) {
      failures.add(ActionFailure(sample, '动作表里没有动作 "${sample.action}"'));
      continue;
    }
    final String result;
    try {
      result = await action(sample.input);
    } catch (e) {
      failures.add(ActionFailure(sample, '执行失败：$e'));
      continue;
    }
    if (!result.contains(sample.expect)) {
      failures.add(
          ActionFailure(sample, '返回里没有 "${sample.expect}"，实际是：$result'));
    }
  }
  return failures;
}
