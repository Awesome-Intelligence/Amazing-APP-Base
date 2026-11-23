import 'package:material_ui/material_ui.dart';

import '../../i18n/kit_strings.dart';
import '../../theme/kit_theme.dart';
import 'buttons.dart';
import 'dialogs.dart';

/// 用户在更新弹窗上的选择。
enum UpdateChoice {
  /// 点了「立即更新」。
  update,

  /// 点了「稍后」/ 点外部 / 返回键。
  later,

  /// 点了「跳过此版本」—— 调用方应把版本号落盘（`UpdateChecker.skip`）。
  skip,
}

/// 新版本提示弹窗 —— 只负责展示和回传用户的选择，不联网、不下载。
/// 数据来自 `AvailableResult`：
/// - `mandatory = true`：强制更新。弹窗不可关闭（返回键/点外部都无效）、
///   没有“稍后/跳过”，只留一个更新按钮
/// - `mandatory = false`：可以“稍后”或“跳过此版本”；[allowSkip] 为 false 就不显示跳过
/// - [updateEnabled]：下载地址没配时置 false（按钮灰掉，而不是点了没反应）
///
/// “立即更新”做什么由 App 决定：Android 跳商店/浏览器、iOS 跳 App Store、
/// Desktop 跳下载页、Web 开新标签。kit 不碰平台跳转 ——
/// ```dart
/// final choice = await UpdateDialog.show(
///   context,
///   latestVersion: available.manifest.latestVersion,
///   currentVersion: currentVersion,
///   releaseNotes: available.manifest.releaseNotes,
///   mandatory: available.mandatory,
/// );
/// if (choice == UpdateChoice.update) openStore();
/// ```
class UpdateDialog extends StatelessWidget {
  const UpdateDialog({
    super.key,
    required this.latestVersion,
    required this.currentVersion,
    required this.releaseNotes,
    required this.onUpdate,
    required this.onLater,
    this.mandatory = false,
    this.onSkipVersion,
    this.updateEnabled = true,
  });

  final String latestVersion;
  final String currentVersion;
  final String releaseNotes;
  final VoidCallback onUpdate;
  final VoidCallback onLater;

  /// 强制更新：不可关闭、只有更新按钮。
  final bool mandatory;

  /// 传 null 就不显示“跳过此版本”。
  final VoidCallback? onSkipVersion;

  final bool updateEnabled;

  /// 直接弹窗并等结果。强制更新时返回值只可能是 [UpdateChoice.update]
  /// 或 null（用户什么都没选就没了路由，理论上不会发生）。
  static Future<UpdateChoice?> show(
    BuildContext context, {
    required String latestVersion,
    required String currentVersion,
    required String releaseNotes,
    bool mandatory = false,
    bool updateEnabled = true,
    bool allowSkip = true,
  }) {
    return showDialog<UpdateChoice>(
      context: context,
      // 强制更新时点外部、点返回都不关 —— 否则用户滑一下就把闸门绕过去了
      barrierDismissible: !mandatory,
      builder: (dialogContext) => PopScope(
        canPop: !mandatory,
        child: UpdateDialog(
          latestVersion: latestVersion,
          currentVersion: currentVersion,
          releaseNotes: releaseNotes,
          mandatory: mandatory,
          updateEnabled: updateEnabled,
          onUpdate: () => Navigator.of(dialogContext).pop(UpdateChoice.update),
          onLater: () => Navigator.of(dialogContext).pop(UpdateChoice.later),
          onSkipVersion: allowSkip && !mandatory
              ? () => Navigator.of(dialogContext).pop(UpdateChoice.skip)
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = KitTheme.of(context);
    final strings = KitStringsScope.of(context);
    final title =
        mandatory ? strings.updateRequiredTitle : strings.updateAvailableTitle;
    final notes = releaseNotes.trim();

    return kitDialogShell(
      context,
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: themedCrossAxisAlignment(
          context,
          CrossAxisAlignment.center,
        ),
        children: [
          // 顶部图标块：和删除确认同一套形制，只是换成下载语义
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: tokens.colorScheme.primaryContainer,
              borderRadius: tokens.shapes.large,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.download_outlined,
              size: 30,
              color: tokens.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: themedTextAlign(context, TextAlign.center),
            style: tokens.textTheme.titleMedium?.copyWith(
              color: tokens.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            strings.updateVersionLine(currentVersion, latestVersion),
            textAlign: themedTextAlign(context, TextAlign.center),
            style: tokens.textTheme.bodySmall?.copyWith(
              color: tokens.colorScheme.onSurfaceVariant,
            ),
          ),
          if (mandatory) ...[
            const SizedBox(height: 12),
            Text(
              strings.updateRequiredHint,
              textAlign: themedTextAlign(context, TextAlign.center),
              style: tokens.textTheme.bodyMedium?.copyWith(
                color: tokens.colorScheme.error,
              ),
            ),
          ],
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                strings.updateNotesTitle,
                style: tokens.textTheme.labelLarge?.copyWith(
                  color: tokens.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // 更新说明是不可信文本：只当纯文本渲染，不当 Markdown/HTML 执行。
            // 高度封顶 + 可滚：说明写一千字也不该把按钮挤出屏幕。
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: SingleChildScrollView(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    notes,
                    style: tokens.textTheme.bodySmall?.copyWith(
                      color: tokens.colorScheme.onSurface,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          PrimaryButton(
            text: strings.updateNow,
            onPressed: onUpdate,
            enabled: updateEnabled,
            expand: true,
          ),
          if (!mandatory) ...[
            const SizedBox(height: 8),
            TextActionButton(
              text: strings.updateLater,
              onPressed: onLater,
            ),
            if (onSkipVersion != null)
              TextActionButton(
                text: strings.updateSkipVersion,
                onPressed: onSkipVersion,
              ),
          ],
        ],
      ),
    );
  }
}
