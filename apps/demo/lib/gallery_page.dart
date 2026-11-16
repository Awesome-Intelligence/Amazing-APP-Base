import 'package:material_ui/material_ui.dart';
import 'package:kit/kit.dart' show AppLanguage;
import 'package:kit/kit_ui.dart';

/// 目录页展示用的档位 —— 真实数据来自 `BillingProvider.planOptions(catalog)`，
/// 价格文案由商店给；这里写死只是为了目录页不用起支付通道。
const _demoPlanOptions = [
  PlanOption(
    plan: Plan(
      id: 'premium',
      tier: 1,
      entitlements: {'export'},
      limits: {'ai': QuotaLimit(100, QuotaPeriod.daily)},
    ),
    title: '高级版',
    price: '¥28 / 月',
    features: [PlanFeature('导出数据'), PlanFeature('每天 AI 次数', '100')],
  ),
  PlanOption(
    plan: Plan(
      id: 'pro',
      tier: 2,
      entitlements: {'export', 'themes'},
      limits: {'ai': QuotaLimit(300, QuotaPeriod.daily)},
    ),
    title: '专业版',
    price: '¥68 / 月',
    features: [PlanFeature('含高级版全部权益'), PlanFeature('主题全部解锁')],
  ),
];

/// 组件目录 —— kit 已迁移组件的可视化清单。
///
/// 存在的意义：单元测试只能证明「点得动」，证明不了「五套风格下都好看」。
/// 这一页把所有组件摆在同一个滚动流里，切风格/切深浅/切语言之后一眼就能看出
/// 哪块没跟上主题（比如某处写死了圆角、某处用了硬编码颜色）。
///
class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key, required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  int _filterIndex = 0;
  bool _checked = true;
  bool _toggle = true;
  String _colorName = 'rose';
  String _field = '';
  String _composer = '';
  String _query = '';
  DateTime _selectedDate = DateTime(2026, 11, 15);
  String _priority = 'medium';
  int _navIndex = 0;
  double _progress = 0.35;
  bool _loading = false;

  /// 联系人列表要能被删 —— 头像堆叠的展开态才会真的收起来。
  final List<ContactItem> _contacts = [
    const ContactItem(id: '1', name: '张三'),
    const ContactItem(id: '2', name: '李四'),
    const ContactItem(id: '3', name: '王五'),
    const ContactItem(id: '4', name: '赵六'),
    const ContactItem(id: '5', name: '孙悟空'),
    const ContactItem(id: '6', name: '周七'),
  ];

  void _removeContact(ContactItem c) {
    setState(() => _contacts.removeWhere((e) => e.id == c.id));
    _toast('移除 ${c.name}');
  }

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);

    return Scaffold(
      backgroundColor: tokens.extras.background,
      body: Column(
        children: [
          Header(
            title: '组件目录',
            maxChars: 12,
            menu: IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: '设置',
              onPressed: widget.onOpenSettings,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _Section(
                  title: '按钮',
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      PrimaryButton(text: '主要操作', onPressed: () {}),
                      SecondaryButton(text: '次要操作', onPressed: () {}),
                      SmallSecondaryButton(text: '小号', onPressed: () {}),
                      FilledIconButton(icon: Icons.add, onPressed: () {}),
                      TextActionButton(text: '文字按钮', onPressed: () {}),
                      PrimaryButton(text: '禁用', onPressed: () {}, enabled: false),
                    ],
                  ),
                ),
                _Section(
                  title: '卡片',
                  child: Column(
                    children: [
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CardTitle(icon: Icons.inbox, title: 'AppCard'),
                            const SizedBox(height: 8),
                            Text('带内边距的通用卡片', style: tokens.textTheme.bodyMedium),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SmallCard(child: Text('SmallCard 更紧凑', style: tokens.textTheme.bodySmall)),
                    ],
                  ),
                ),
                _Section(
                  title: '标签与选择',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (var i = 0; i < 4; i++)
                            KitFilterChip(
                              title: ['全部', '进行中', '已完成', '已归档'][i],
                              isSelected: _filterIndex == i,
                              onTap: () => setState(() => _filterIndex = i),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const AppBadge(text: '高级版'),
                          TagText(text: '标签', color: tokens.tagColor('sage')),
                          SelectableTag(
                            text: '可选中',
                            isSelected: _filterIndex == 0,
                            onTap: () => setState(() => _filterIndex = 0),
                          ),
                          AddTagChip(onTap: () {}),
                          AnswerChip(text: '快捷回答', onTap: () {}),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          KitCheckbox(
                            isChecked: _checked,
                            onCheckedChange: (v) => setState(() => _checked = v),
                          ),
                          const SizedBox(width: 8),
                          Text('复选框', style: tokens.textTheme.bodyMedium),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ColorDotRow(
                        colorNames: const ['neutral', 'rose', 'sage', 'mauve', 'clay'],
                        selectedColorName: _colorName,
                        onColorSelected: (name) => setState(() => _colorName = name),
                      ),
                    ],
                  ),
                ),
                _Section(
                  title: '输入',
                  child: Column(
                    children: [
                      SimpleTextField(
                        value: _field,
                        onValueChange: (v) => setState(() => _field = v),
                        label: '单行输入',
                        hint: '说点什么',
                      ),
                      const SizedBox(height: 12),
                      SimpleTextField(
                        value: '',
                        onValueChange: (_) {},
                        label: '错误态',
                        isError: true,
                        helperText: '这一项必填',
                      ),
                      const SizedBox(height: 12),
                      KitSearchBar(
                        query: _query,
                        onQueryChange: (v) => setState(() => _query = v),
                        onSearch: () => _toast('搜索：$_query'),
                        onFilterClick: () => _toast('打开筛选'),
                        filterActive: _filterIndex != 0,
                      ),
                      const SizedBox(height: 12),
                      ComposerField(
                        value: _composer,
                        onValueChange: (v) => setState(() => _composer = v),
                        placeholder: '对话输入条',
                        onMicTap: () => _toast('语音输入未接入'),
                        micContentDescription: '语音输入',
                        onSubmit: () => _toast('发送：$_composer'),
                      ),
                    ],
                  ),
                ),
                _Section(
                  title: '列表行',
                  child: Column(
                    children: [
                      AppListItem(
                        headlineText: '带序号徽章的条目',
                        supportingText: '副标题说明',
                        leadingBadge: 1,
                        tags: const ['sage', 'clay'],
                        // 值是色名（tagColor 的键），不是 Color —— 组件自己按主题取色，
                        // 页面传 Color 的话换风格时标签就不会跟着变了。
                        tagColors: const {'sage': 'sage', 'clay': 'clay'},
                        progress: 0.6,
                        onTap: () {},
                      ),
                      AppListItem(
                        headlineText: '带尾部文字的条目',
                        trailingText: '今天',
                        onTap: () {},
                      ),
                      AddListItem(text: '添加一条', onTap: () {}),
                      const SizedBox(height: 8),
                      AppSettingsRow(
                        icon: Icons.palette_outlined,
                        title: '设置行（带箭头）',
                        subtitle: '点开去设置页',
                        onClick: widget.onOpenSettings,
                      ),
                      ToggleRow(
                        title: '开关行',
                        subtitle: '整行可点',
                        icon: Icons.animation_outlined,
                        isChecked: _toggle,
                        onCheckedChange: (v) => setState(() => _toggle = v),
                      ),
                      Wrap(
                        children: [
                          AppIconTile(
                            icon: Icons.star_outline,
                            label: '收藏',
                            onClick: () {},
                          ),
                          const SizedBox(width: 24),
                          AppIconTile(
                            icon: Icons.share_outlined,
                            label: '分享',
                            onClick: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _Section(
                  title: '日历',
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 380),
                      child: AppCalendar(
                        selectedDate: _selectedDate,
                        onDateSelected: (d) => setState(() => _selectedDate = d),
                        viewMode: CalendarViewMode.monthWeekHighlight,
                        onViewModeChange: (m) => _toast('切换视图：${m.name}'),
                        onWeekSelected: (d) => _toast('选中整周（周日 ${d.month}/${d.day}）'),
                      ),
                    ),
                  ),
                ),
                const _Section(
                  title: '骨架屏',
                  child: Column(
                    children: [
                      SkeletonTextLine(width: 160),
                      SizedBox(height: 8),
                      SkeletonTextLine(),
                      SizedBox(height: 8),
                      SkeletonTextLine(width: 200, lineHeight: 12),
                      SizedBox(height: 16),
                      SkeletonListItem(),
                      SkeletonListItem(showAvatar: false),
                    ],
                  ),
                ),
                _Section(
                  title: '空状态',
                  child: Column(
                    children: [
                      EmptyStates.goals(),
                      const Divider(),
                      EmptyStates.noSearchResults('关键词'),
                    ],
                  ),
                ),
                _Section(
                  title: '反馈与进度',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppSnackbar(message: '保存成功', isSuccess: true),
                      const SizedBox(height: 8),
                      const AppSnackbar(message: '保存失败', isSuccess: false),
                      const SizedBox(height: 16),
                      LinearProgressBar(progress: _progress),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          SecondaryButton(
                            text: '进度 +0.2',
                            onPressed: () =>
                                setState(() => _progress = (_progress + 0.2).clamp(0.0, 1.0)),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${(_progress * 100).round()}%',
                            style: tokens.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          CircularProgressIndicatorWithText(progress: _progress),
                          const SizedBox(width: 24),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                StatusMark(filled: true),
                                SizedBox(width: 8),
                                Text('已开始'),
                              ]),
                              SizedBox(height: 8),
                              Row(children: [
                                StatusMark(filled: false),
                                SizedBox(width: 8),
                                Text('未开始'),
                              ]),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 120,
                        child: LoadingOverlay(
                          isLoading: _loading,
                          child: Center(
                            child: SecondaryButton(
                              text: _loading ? '加载中…' : '点我看遮罩',
                              onPressed: () {
                                setState(() => _loading = true);
                                Future<void>.delayed(const Duration(milliseconds: 800), () {
                                  if (mounted) setState(() => _loading = false);
                                  _toast('加载完成');
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _Section(
                  title: '菜单与下拉',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('SimpleMenuButton', style: tokens.textTheme.bodyMedium),
                          const Spacer(),
                          SimpleMenuButton(
                            items: const [
                              SimpleMenuItem(title: '重命名', icon: Icons.edit_outlined),
                              SimpleMenuItem(title: '移动到…', icon: Icons.drive_file_move_outline),
                              SimpleMenuItem.divider(),
                              SimpleMenuItem(title: '删除', icon: Icons.delete_outline),
                            ],
                            onItemSelected: (p, s) => _toast('选第 $p 项（子索引 $s）'),
                          ),
                          ActionMenuRow(
                            onEdit: () => _toast('编辑'),
                            onDelete: () => _toast('删除'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SelectDropdown<String>(
                        label: '优先级',
                        options: const [
                          DropdownOption(label: '低', value: 'low'),
                          DropdownOption(label: '中', value: 'medium'),
                          DropdownOption(label: '高', value: 'high'),
                        ],
                        selectedOption: _priority,
                        onOptionSelected: (v) => setState(() => _priority = v),
                      ),
                      const SizedBox(height: 12),
                      SelectDropdown<String>(
                        label: '禁用态',
                        options: const [DropdownOption(label: '不可选', value: 'x')],
                        selectedOption: 'x',
                        onOptionSelected: (_) {},
                        enabled: false,
                      ),
                    ],
                  ),
                ),
                _Section(
                  title: '头像',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          UserAvatar(avatar: null, name: '张三'),
                          SizedBox(width: 12),
                          UserAvatar(avatar: null, name: '李四', size: 32),
                          SizedBox(width: 12),
                          UserAvatar(avatar: null, name: '👍', size: 64),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AvatarStack(
                        contacts: _contacts,
                        onContactClick: (c) => _toast('打开 ${c.name}'),
                        onRemoveContact: _removeContact,
                        maxVisible: 4,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '点击头像堆叠展开 / 收起，展开后点头像露出删除',
                        style: tokens.textTheme.labelSmall
                            ?.copyWith(color: tokens.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 16),
                      ExpandedAvatarRow(
                        contacts: _contacts.take(3).toList(),
                        onContactClick: (c) => _toast('打开 ${c.name}'),
                        onRemoveContact: _removeContact,
                      ),
                    ],
                  ),
                ),
                _Section(
                  title: '统计卡',
                  child: StatsCard(
                    stats: [
                      StatItemData(
                        title: '进行中',
                        value: '3',
                        icon: Icons.timelapse,
                        color: tokens.colorScheme.primary,
                      ),
                      StatItemData(
                        title: '已完成',
                        value: '12',
                        icon: Icons.check_circle_outline,
                        color: tokens.extendedColors.success,
                      ),
                      StatItemData(
                        title: '已归档',
                        value: '48',
                        icon: Icons.inventory_2_outlined,
                        color: tokens.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
                _Section(
                  title: '底部导航 + 分页指示器',
                  child: Column(
                    children: [
                      AppBottomNavigation(
                        items: const [
                          BottomNavItem(
                            label: '首页',
                            icon: Icons.home_outlined,
                            selectedIcon: Icons.home,
                          ),
                          BottomNavItem(
                            label: '消息',
                            icon: Icons.mail_outline,
                            selectedIcon: Icons.mail,
                            badgeCount: 3,
                          ),
                          BottomNavItem(label: '新建', icon: Icons.add, alwaysFilled: true),
                          BottomNavItem(
                            label: '我的',
                            icon: Icons.person_outline,
                            selectedIcon: Icons.person,
                          ),
                        ],
                        selectedIndex: _navIndex,
                        onItemSelected: (i) => setState(() => _navIndex = i),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 80,
                        child: Row(
                          children: [
                            Text('竖排分页点', style: tokens.textTheme.bodyMedium),
                            const Spacer(),
                            PageIndicator(pageCount: 4, currentPage: _navIndex % 4),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _Section(
                  title: '弹窗',
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SecondaryButton(
                        text: '确认框',
                        onPressed: () => ConfirmDialog.show(
                          context,
                          title: '确认操作',
                          message: '这是一段说明文字。',
                        ),
                      ),
                      SecondaryButton(
                        text: '单选',
                        onPressed: () => SelectDialog.show(
                          context,
                          title: '选一个',
                          options: const ['选项一', '选项二', '选项三'],
                          selectedIndex: 0,
                        ),
                      ),
                      SecondaryButton(
                        text: '删除确认',
                        onPressed: () => DeleteConfirmDialog.show(context),
                      ),
                      SecondaryButton(
                        text: '输入框',
                        onPressed: () => InputDialog.show(
                          context,
                          title: '输入名称',
                          hint: '例如：周报',
                        ),
                      ),
                    ],
                  ),
                ),
                _Section(
                  title: '会员',
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SecondaryButton(
                        text: '会员付费墙',
                        onPressed: () => MembershipPaywall.show(
                          context,
                          message: '导出需要会员',
                        ),
                      ),
                      SecondaryButton(
                        text: '额度付费墙',
                        onPressed: () => QuotaPaywall.show(
                          context,
                          reason: QuotaReason.ai,
                          limit: 3,
                        ),
                      ),
                      SecondaryButton(
                        text: '升级面板',
                        onPressed: () => UpgradeSheet.show(
                          context,
                          options: _demoPlanOptions,
                          // 假装已是高级版，这样面板上能同时看到
                          // 「当前方案」和被禁用按钮长什么样。
                          currentPlanId: 'premium',
                          onPurchase: (id) => _toast('购买：$id'),
                          onRestore: () => _toast('恢复购买'),
                        ),
                      ),
                    ],
                  ),
                ),
                const _Section(
                  title: '对话',
                  child: SizedBox(
                    height: 320,
                    child: ChatMessageList(
                      messages: [
                        ChatMessage.user('帮我看看今天有什么安排'),
                        ChatMessage.assistant(
                          text: '你有 3 件待办，其中 1 件今天到期。',
                          steps: [
                            ChatStep(
                              tool: 'list_todos',
                              args: '{}',
                              status: ChatStepStatus.done,
                              result: '共 3 条',
                            ),
                          ],
                        ),
                        ChatMessage.system('已升级到高级版'),
                        ChatMessage.error('网络断了'),
                      ],
                    ),
                  ),
                ),
                _Section(
                  title: '工具审批',
                  child: ToolApprovalCard(
                    tool: 'delete_todo',
                    args: '{"id":"abc"}',
                    risk: '该操作会修改本地数据，确认后无法撤销',
                    onDeny: () => _toast('已拒绝'),
                    onAllowOnce: () => _toast('允许一次'),
                    onAllowAlways: () => _toast('本任务免确认'),
                  ),
                ),
                _Section(
                  title: '语言',
                  child: Wrap(
                    spacing: 8,
                    children: [
                      for (final lang in AppLanguage.values)
                        SecondaryButton(
                          text: lang.name,
                          onPressed: () => _toast('语言示例：${KitStrings.forLanguage(lang).cancel}'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 用 kit 自己的反馈条，顺带验证它在真实页面里能用。
  void _toast(String text) => showAppSnackbar(context, message: text);
}

/// 目录里的一个分组：标题 + 一张卡。
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            child: Text(
              title,
              style: tokens.textTheme.labelLarge
                  ?.copyWith(color: tokens.colorScheme.onSurfaceVariant),
            ),
          ),
          AppCard(
            child: SizedBox(width: double.infinity, child: child),
          ),
        ],
      ),
    );
  }
}
