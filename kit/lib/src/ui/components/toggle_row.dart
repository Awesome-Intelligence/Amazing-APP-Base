import 'package:material_ui/material_ui.dart';

import '../../theme/kit_theme.dart';

/// M3 开关行：整行可点，开关只负责显示状态。
///
/// [icon] / [subtitle] 可选 —— 传了就是「图标 + 标题 + 说明」的整行，
/// 不传就是纯标题 + 开关。
///
/// 与 KMP 版的一点差异：Compose 里 `Switch(onCheckedChange = null)` 会画成禁用色，
/// Flutter 同理，所以这里把开关自己的 onChanged 也接上同一个回调 ——
/// 视觉上仍是「整行一个开关」，点开关本体和点行尾之外的地方效果一致。
class ToggleRow extends StatelessWidget {
  const ToggleRow({
    super.key,
    required this.title,
    required this.isChecked,
    required this.onCheckedChange,
    this.icon,
    this.subtitle,
  });

  final String title;
  final bool isChecked;
  final ValueChanged<bool> onCheckedChange;
  final IconData? icon;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);

    return InkWell(
      onTap: () => onCheckedChange(!isChecked),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 24, color: tokens.colorScheme.onSurfaceVariant),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: tokens.textTheme.bodyLarge?.copyWith(
                        color: tokens.colorScheme.onSurface,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: tokens.textTheme.bodySmall?.copyWith(
                          color: tokens.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Switch(
                value: isChecked,
                onChanged: onCheckedChange,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
