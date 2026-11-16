import 'package:material_ui/material_ui.dart';

import '../../theme/kit_theme.dart';
import 'cards.dart';
import 'tag_text.dart';

/// 列表条目 —— M3 ListItem 等价物。
///
/// 规格（对应 KMP 的 `AppListItem`）：
/// - leading：40 圆形色块（编号/头像），或 9 色点（[leadingBadgeIsDot]）
/// - headline：titleSmall、单行省略
/// - supporting：bodySmall、onSurfaceVariant、单行
/// - trailing：文字或自定义 widget
/// - tags：最多 3 个，用 [TagText] 渲染（和详情页一致，不用胶囊底）
/// - 触控目标 ≥ 48
class AppListItem extends StatelessWidget {
  const AppListItem({
    super.key,
    required this.headlineText,
    this.supportingText,
    this.leadingBadge,
    this.leadingBadgeColor,
    this.leadingBadgeLabel,
    this.leadingBadgeIsDot = false,
    this.avatarUri,
    this.trailingText,
    this.trailingContent,
    this.progress,
    this.tags = const [],
    this.tagColors = const {},
    this.onTap,
  });

  final String headlineText;
  final String? supportingText;

  /// 数字徽章（优先级编号等）。有 [leadingBadgeLabel] 时以 label 为准。
  final int? leadingBadge;
  final Color? leadingBadgeColor;
  final String? leadingBadgeLabel;

  /// true 时 leading 变成 9 的小圆点（不占 40 的位置，挤在标题前面）。
  final bool leadingBadgeIsDot;

  /// 头像 URL（给了就优先于色块）。
  final String? avatarUri;

  final String? trailingText;

  /// 自定义尾部内容，优先于 [trailingText]。
  final Widget? trailingContent;

  /// 0..1 的进度；给了就在 supporting 下面画一条 4 高圆头进度条。
  final double? progress;

  final List<String> tags;

  /// 标签名 → 色名（`tagColor()` 的键）。缺省按 primary。
  final Map<String, String> tagColors;

  /// 外层已用 AppCard 承载点击时传 null，避免嵌套两层水波纹。
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    final scheme = tokens.colorScheme;

    final leading = _buildLeading(context);
    final trailing = trailingContent ??
        (trailingText == null
            ? null
            : Text(
                trailingText!,
                style: tokens.textTheme.labelLarge
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ));

    Widget body = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (leading != null) ...[
          leading,
          const SizedBox(width: 16),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (leadingBadgeIsDot &&
                      leadingBadgeColor != null &&
                      leadingBadgeLabel != null) ...[
                    Semantics(
                      label: leadingBadgeLabel,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: leadingBadgeColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      headlineText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tokens.textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
              if (supportingText != null) ...[
                const SizedBox(height: 2),
                Text(
                  supportingText!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tokens.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
              if (progress != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress!.clamp(0.0, 1.0).toDouble(),
                    minHeight: 4,
                    color: scheme.primary,
                    backgroundColor: tokens.extras.surfaceVariant,
                  ),
                ),
              ],
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final tag in tags.take(3))
                      TagText(
                        text: tag,
                        color: tagColor(context, tagColors[tag] ?? 'primary'),
                        showSelectedIcon: false,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing,
        ],
      ],
    );

    // 触控目标 ≥ 48：单行条目也要保证这个下限。
    body = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: body,
      ),
    );

    if (onTap == null) return body;
    return InkWell(onTap: onTap, child: body);
  }

  Widget? _buildLeading(BuildContext context) {
    final scheme = KitTheme.of(context).colorScheme;

    if (avatarUri != null) {
      return Container(
        width: 40,
        height: 40,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: leadingBadgeColor ?? scheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: Image.network(
          avatarUri!,
          fit: BoxFit.cover,
          // 头像加载失败不能把整行撑炸，退回空白（底色还在）。
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      );
    }

    if (leadingBadge != null || leadingBadgeLabel != null) {
      final color = leadingBadgeColor ?? scheme.primary;
      final label = leadingBadgeLabel ?? leadingBadge?.toString() ?? '';
      return Semantics(
        label: label,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(
            label,
            style: KitTheme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: scheme.surface),
          ),
        ),
      );
    }

    return null;
  }
}

/// 列表底部的添加入口。
///
/// 与列表条目同风格（[AppCard]），leading 是 40 的 primary 淡底加号，文字 primary 色。
class AddListItem extends StatelessWidget {
  const AddListItem({super.key, required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    final scheme = tokens.colorScheme;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              // 深色下 10%、浅色下 5%：同一个视觉强度，深色背景需要更多不透明度。
              color: scheme.primary.withValues(alpha: tokens.isDark ? 0.10 : 0.05),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.add, size: 20, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: tokens.textTheme.bodyLarge?.copyWith(color: scheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}
