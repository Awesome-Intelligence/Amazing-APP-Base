import 'package:material_ui/material_ui.dart';

import '../components/buttons.dart';
import '../../i18n/kit_strings.dart';
import '../../theme/kit_theme.dart';

/// 工具审批卡 —— agent 想干危险的事时弹给用户看的那张卡。
///
/// 为什么是「卡」不是系统对话框：卡能显示**参数**（用户要看得见 agent 到底要动什么），
/// 而且能挂在聊天流里，不打断上下文。对话框只能塞一段字。
///
/// 三个动作对应 agent 层的三种结果：允许一次 / 本任务免确认（以后这个工具不再问）/ 拒绝。
///
/// 这是纯展示组件：谁来弹、点了之后做什么，是 app 的事 —— 所以回调都是必填。
class ToolApprovalCard extends StatelessWidget {
  const ToolApprovalCard({
    super.key,
    required this.tool,
    required this.onAllowOnce,
    required this.onAllowAlways,
    required this.onDeny,
    this.args = '',
    this.title,
    this.risk,
  });

  /// 工具名（和模型看到的一致）。
  final String tool;

  /// 入参摘要（JSON 字符串）；空则不显示。
  final String args;

  final VoidCallback onAllowOnce;
  final VoidCallback onAllowAlways;
  final VoidCallback onDeny;

  /// 标题，默认「需要你确认」。
  final String? title;

  /// 风险说明（「删除后无法恢复」这类）。
  final String? risk;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    final strings = KitStringsScope.of(context);
    final fg = tokens.colorScheme.onErrorContainer;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.colorScheme.errorContainer,
        borderRadius: tokens.shapes.medium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 20, color: fg),
              const SizedBox(width: 8),
              Text(
                title ?? strings.chatApprovalTitle,
                style: tokens.textTheme.titleSmall?.copyWith(color: fg),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(tool, style: tokens.textTheme.bodyMedium?.copyWith(color: fg)),
          if (args.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              args,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: tokens.textTheme.bodySmall?.copyWith(color: fg),
            ),
          ],
          if ((risk ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(risk!, style: tokens.textTheme.bodySmall?.copyWith(color: fg)),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SmallSecondaryButton(
                text: strings.chatApprovalDeny,
                onPressed: onDeny,
              ),
              const SizedBox(width: 8),
              SmallSecondaryButton(
                text: strings.chatApprovalAllowAlways,
                onPressed: onAllowAlways,
              ),
              const SizedBox(width: 8),
              SmallSecondaryButton(
                text: strings.chatApprovalAllowOnce,
                onPressed: onAllowOnce,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
