import 'dart:async';
import 'dart:convert' show jsonEncode;

import 'package:kit_agent/kit_agent.dart';
import 'package:material_ui/material_ui.dart';
import 'package:kit/kit.dart' hide MemoryStorageBackend;
import 'package:kit/kit_ui.dart' as ui;
import 'package:kit_membership/membership.dart';

import 'demo_billing.dart';
import 'todo_skill.dart';
import 'todo_store.dart';

/// demo 的档位表：免费档每天 3 次 AI；高级 / 专业档解锁更多次数与权益。
///
/// 档位表写在代码里而不是从服务器下发 —— 下发的话额度上限能被随便改。
final _catalog = PlanCatalog([
  const Plan(
    id: 'free',
    tier: 0,
    limits: {'ai': QuotaLimit(3, QuotaPeriod.daily)},
  ),
  const Plan(
    id: 'premium',
    tier: 1,
    entitlements: {'export'},
    limits: {'ai': QuotaLimit(100, QuotaPeriod.daily)},
  ),
  const Plan(
    id: 'pro',
    tier: 2,
    entitlements: {'export', 'themes'},
    limits: {'ai': QuotaLimit(300, QuotaPeriod.daily)},
  ),
]);

/// 业务页面：待办列表 + 对话。
///
/// 演示五件事：
/// 1. 流式打字机（AgentEventText 增量追加 → kit 的 ChatMessageList 实时刷新）。
/// 2. 工具审批卡（delete_todo 危险工具，执行前用 kit 的 ToolApprovalCard 确认）。
/// 3. 「删最后一个」按钮和 agent 的 delete_todo 工具调同一个 `TodoStore.remove`。
/// 4. 数据落 `kit` 的 `EntityStore`，AI 请求受 `membership` 额度闸门控制。
/// 5. 五套主题风格 + 中英文实时切换 —— 入口在页头「设置」，状态由根传下来。
class TodoChatPage extends StatefulWidget {
  const TodoChatPage({super.key, required this.onOpenSettings});

  /// 打开设置页。由外壳提供 —— 设置状态在 MaterialApp 之上，
  /// 页面自己 push 会拿不到最新值。
  final VoidCallback onOpenSettings;

  @override
  State<TodoChatPage> createState() => _TodoChatPageState();
}

class _TodoChatPageState extends State<TodoChatPage> {
  // 待办走 kit 的数据层（内存实现，可换 FileEntityStore）。
  final store = TodoStore(MemoryEntityStore(const JsonCodec()));
  late final MembershipManager membership;

  /// 假商店。真机上是 Play Billing / StoreKit 的实现。
  final billing = DemoBilling();
  late final SkillDefinition skill;
  late final AgentSession session;
  final log = ChatLog();
  final inputC = TextEditingController();
  bool _busy = false;
  int? _remaining; // null = 不限
  List<Todo> _todos = const [];
  late final StreamSubscription<Membership> _membershipSub;
  late final StreamSubscription<List<ChatMessage>> _logSub;

  @override
  void initState() {
    super.initState();
    membership = MembershipManager(
      catalog: _catalog,
      store: MembershipStore(MemoryStorageBackend()),
      usage: UsageTracker(MemoryStorageBackend()),
    );
    _membershipSub = membership.membership.listen((_) {
      if (mounted) setState(() {});
    });
    _loadRemaining();
    _reloadTodos();

    skill = todoSkill(store);
    final runtime = createAgentRuntime(
      AgentMode.local,
      apiKey: const String.fromEnvironment(
        'ANTHROPIC_API_KEY',
        defaultValue: '',
      ),
    );
    session = runtime.session(skill, approver: _UiApprover(this));
    // 关键：每次消息变化都重建 —— 少了这一句，流式增量不会刷到屏幕上（只有结尾一次性出现）。
    _logSub = log.stream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  String get _planLabel => switch (membership.plan.id) {
        'premium' => '高级版',
        'pro' => '专业版',
        _ => '免费版',
      };

  Future<void> _loadRemaining() async {
    final r = await membership.remaining('ai');
    if (mounted) setState(() => _remaining = r);
  }

  /// 待办列表跟着 store 走 —— agent 的 add_todo / delete_todo 改完，这里也要重新读，
  /// 否则「agent 改了但列表不动」会让人以为工具没生效。
  Future<void> _reloadTodos() async {
    final list = await store.list();
    if (mounted) setState(() => _todos = list);
  }

  /// 打开升级面板。
  ///
  /// 档位列表从**商店**取（`planOptions`），不是从 catalog 直接拼 ——
  /// 只有商店里真的买得到的档位才会出现，价格文案也用商店给的。
  Future<void> _openUpgrade() async {
    final options = await billing.planOptions(_catalog);
    if (!mounted) return;
    if (options.isEmpty) {
      _toast('商店里没有可购买的档位');
      return;
    }

    await ui.UpgradeSheet.show(
      context,
      options: options,
      currentPlanId: membership.plan.id,
      onPurchase: (id) async {
        final result = await membership.purchase(billing, id);
        if (!mounted) return;
        // 面板本身是一个路由，pop 一次就关掉它（下面的页面不受影响）。
        Navigator.of(context).pop();
        await _loadRemaining();
        if (!mounted) return;
        setState(() {});
        log.system(switch (result) {
          PurchaseSuccess() => '已开通 $_planLabel：AI 额度提升到每天 '
              '${membership.plan.limits['ai']?.limit} 次'
              '${membership.has('export') ? '，已解锁导出' : ''}',
          PurchaseCancelled() => '已取消购买',
          PurchasePending() => '购买处理中，稍后会到账',
          PurchaseFailed(:final reason) => '购买失败：$reason',
        });
      },
      onRestore: () async {
        final result = await membership.restore(billing);
        if (!mounted) return;
        Navigator.of(context).pop();
        await _loadRemaining();
        if (!mounted) return;
        setState(() {});
        log.system(switch (result) {
          PurchaseSuccess() => '已恢复购买：$_planLabel',
          PurchaseCancelled() => '已取消恢复',
          PurchasePending() => '恢复处理中',
          PurchaseFailed(:final reason) => '恢复失败：$reason',
        });
      },
    );
  }

  /// 额度用完 → 先说明原因，愿意升级再打开升级面板。
  ///
  /// 两段分开是刻意的：付费墙只回答「为什么被挡住」，
  /// 档位对比属于升级面板，混在一起会让人还没看懂就被价格推着走。
  Future<void> _showQuotaPaywall(AccessBlocked blocked) async {
    final wantsUpgrade = await ui.QuotaPaywall.show(
      context,
      reason: ui.QuotaReason.ai,
      limit: blocked.limit,
    );
    if (wantsUpgrade && mounted) await _openUpgrade();
  }

  Future<void> _send() async {
    final text = inputC.text.trim();
    if (text.isEmpty || _busy) return;

    // 额度闸门：免费档每天 3 次，超了拦住（不改计数）。
    final access = await membership.consume('ai');
    if (access is AccessBlocked) {
      log.system('今日 AI 请求额度已用尽（$_planLabel）');
      await _loadRemaining();
      if (mounted) setState(() {});
      if (mounted) await _showQuotaPaywall(access);
      return;
    }

    inputC.clear();
    setState(() => _busy = true);
    log.user(text);
    await for (final ev in session.send(text)) {
      log.onEvent(ev);
    }
    await _loadRemaining();
    // agent 可能刚加了/删了待办 —— 列表也得刷。
    await _reloadTodos();
    if (mounted) setState(() => _busy = false);
  }

  /// UI 的「添加待办」：和 agent 的 add_todo 工具调同一个 `store.add`。
  Future<void> _addTodo() async {
    final title = await ui.InputDialog.show(
      context,
      title: '添加待办',
      hint: '例如：周五交周报',
    );
    if (title == null) return;
    final r = await store.add(title);
    log.system(r);
    await _reloadTodos();
  }

  /// UI 的「删单条」：和 agent 的 delete_todo 工具调同一个 `store.remove`。
  Future<void> _deleteTodo(Todo todo) async {
    final ok = await ui.DeleteConfirmDialog.show(
      context,
      message: '「${todo.title}」删除后无法恢复，确定吗？',
    );
    if (!ok) return;
    final r = await store.remove(todo.id);
    log.system(r);
    await _reloadTodos();
  }

  /// UI 按钮：和 agent 的 delete_todo 工具调同一个函数。
  Future<void> _deleteLast() async {
    final items = await store.list();
    if (items.isEmpty) {
      log.system('没有可删除的待办');
      if (mounted) setState(() {});
      return;
    }
    final r = await store.remove(items.last.id);
    log.system(r);
    await _reloadTodos();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _membershipSub.cancel();
    _logSub.cancel();
    inputC.dispose();
    log.dispose();
    membership.dispose();
    super.dispose();
  }

  /// 待办面板 —— 列表条目、添加入口、单条删除都走 kit 的通用组件。
  ///
  /// 这份列表和 agent 用的是同一个 `TodoStore`：agent 调 `add_todo` 之后，
  /// 这里也会出现那一条（[`_reloadTodos`] 负责重读）。
  Widget _todoPanel(BuildContext context) {
    final tokens = ui.KitTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: ui.AppCard(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
        child: SizedBox(
          height: 172,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Text('待办', style: tokens.textTheme.titleSmall),
                    const SizedBox(width: 8),
                    Text(
                      '${_todos.length} 条',
                      style: tokens.textTheme.bodySmall
                          ?.copyWith(color: tokens.colorScheme.onSurfaceVariant),
                    ),
                    const Spacer(),
                    ui.TextActionButton(
                      text: '删最后一个',
                      onPressed: _deleteLast,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    for (var i = 0; i < _todos.length; i++)
                      ui.AppListItem(
                        headlineText: _todos[i].title,
                        leadingBadge: i + 1,
                        trailingContent: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          tooltip: '删除',
                          onPressed: () => _deleteTodo(_todos[i]),
                        ),
                      ),
                    ui.AddListItem(text: '添加待办', onTap: _addTodo),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final isFree = membership.plan.id == 'free';
    return Scaffold(
      body: Column(
        children: [
          ui.Header(
            title: '待办助手',
            action1: ui.AppBadge(
              text: '$_planLabel · ${_remaining == null ? '∞' : '剩 $_remaining 次'}',
            ),
            action2: TextButton(
              // 已付费时也能点开 —— 升级面板会把当前档位标成「当前方案」，
              // 顺手成了「我的订阅」页。
              onPressed: _openUpgrade,
              child: Text(isFree ? '升级' : '档位'),
            ),
            menu: IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: '设置',
              onPressed: widget.onOpenSettings,
            ),
          ),
          _todoPanel(context),
          Expanded(
            child: ui.ChatMessageList(
              messages: ui.mapChatMessages(log.messages),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: ui.ComposerField(
                    // 外部托管 controller：发送后 `inputC.clear()` 能立刻清空输入条。
                    value: inputC.text,
                    controller: inputC,
                    onValueChange: (_) {}, // 内容由 controller 托管，无需额外状态
                    placeholder: '说点什么…',
                    onMicTap: () => _toast('语音输入暂未接入'),
                    micContentDescription: '语音输入',
                    onSubmit: _send,
                  ),
                ),
                const SizedBox(width: 8),
                ui.FilledIconButton(
                  icon: Icons.send,
                  tooltip: '发送',
                  enabled: !_busy,
                  onPressed: _send,
                ),
                if (_busy) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 把 ToolApprover 接到 UI：危险工具执行前弹确认卡。
///
/// 用的是 kit 的 `ToolApprovalCard` 而不是系统 AlertDialog —— 卡能显示参数与风险说明，
/// 而且样式跟主题联动（换 Swiss 就变成直角黑白，不用改这里一行）。
class _UiApprover implements ToolApprover {
  final _TodoChatPageState state;
  _UiApprover(this.state);

  @override
  Future<ToolApproval> approve(
    String toolName,
    Map<String, Object?> args,
  ) async {
    final ctx = state.context;
    final result = await showDialog<ToolApproval>(
      context: ctx,
      builder: (c) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: ui.ToolApprovalCard(
            tool: toolName,
            args: jsonEncode(args),
            risk: '该操作会修改本地数据，确认后无法撤销',
            onDeny: () => Navigator.pop(c, const Deny('用户拒绝')),
            onAllowOnce: () => Navigator.pop(c, const Allow()),
            onAllowAlways: () => Navigator.pop(c, const AllowAlways()),
          ),
        ),
      ),
    );
    return result ?? const Deny('用户关闭弹窗');
  }
}
