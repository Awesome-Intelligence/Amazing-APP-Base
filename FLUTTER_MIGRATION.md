# 未迁组件清单 —— 哪些组件故意没做、为什么

底座是一套 **通用**的 Flutter 组件库。清单里这些组件**不是忘了做，是判断过不值得做**。
真要用，从旧实现备份（仓库外 `E:/Awesome Intelligence/kmp-legacy-backup/`）里挑实现，
按本文最后一节的步骤搬进 `kit/lib/src/ui/components/` —— 别把旧工程整个拉回来。

分组：**A 组**是业务组件（有价值但绑业务/素材），**B 组**是风格专属（已被 token 体系取代，
**不要**搬），**C 组**是平台相关，**D 组**是部分被取代。

---

## A 组：业务组件（想要就搬）

| 组件 | 里面有什么 | 为什么没做 |
|---|---|---|
| AI 视觉组件 | 动作按钮 / 洞察卡 / 加载骨架 / 建议徽章与卡片 / 呼吸图标 / 目标 AI 按钮 | AI 相关的视觉件，自带插画与呼吸动效，**依赖旧插画资源**，整组搬过来要重做素材 |
| 筛选底部弹窗 | 底部弹窗壳 + 日期区间 / 心情 / 重要度 / 多选 / 单选 / 标签等维度 | 筛选**芯片**已迁（`chips.dart` 的 `KitFilterChip`），只差弹窗壳 + 业务维度 |
| 通知面板 | 通知按钮 + 面板（空态 / 行） | **底座已有一半**：`notification.dart`（`AppNotification` / `NotificationStore`）+ `AppNotificationList`（站内消息，无平台推送）。**系统通知按钮与推送仍归 app 层**（FCM / 本地通知是平台接口，见 `rules/KIT-NOTES.md` 〇.k）—— 已在 `apps/demo` 接 `flutter_local_notifications`（弹系统通知）+ `firebase_messaging`（后台推送）+ ntfy（纯 HTTP 传输，客户端在 `kit`） |
| Markdown 编辑器 | 编辑器 + 预览 | Flutter 侧有富文本/编辑器依赖可选，底座不绑第三方 Markdown 方案 |
| 滚动收缩页头 | 滚动时收缩的标题 + 标题预览 | **部分能力已有**：`components/motion.dart` 的 `CollapsibleSection`（折叠）+ `header.dart` 的 `Header`，但没有「滚动时收缩标题」那种联动 |
| 打卡热力卡 | 热力格 + 统计 chip | 纯业务（打卡）组件，`kit` 不该知道「打卡」是什么 |
| 横向日期条 | 一行日期格 | 已有 `calendar.dart`（月视图日历），横向条是另一种交互，真要用再写 |
| Markdown 工具条 | 加粗/斜体等按钮 + 分隔 | 跟编辑器一起走 |
| 标签选择弹窗 | 标签选择底部弹窗 | **标签芯片已迁**（`chips.dart` 的 `AddTagChip` / `SelectableTag`），只差弹窗壳 |

> 判断标准：只有「app 一上来就要用」才值得现在搬。

---

## B 组：风格专属组件（token 体系已取代，**故意不做**）

早期是「每种风格一组组件」（同一件事写 4 遍）。现在是 **token 驱动**：
一套组件 + 5 套 `ThemeTokens`（Mono / Swiss / Notion / EInk / macOS），
`KitTheme.of(context)` 取当前 tokens。加风格 = 加一套 tokens，不用再写一遍组件。

**不要把这些搬回来** —— 搬回来就等于退回「每套风格一组组件」的老路。

---

## C 组：平台相关

| 组件 | 说明 |
|---|---|
| 系统语音输入 | Flutter 侧 `ComposerField` 的麦克风按钮留了接口，demo 里点它提示「语音输入暂未接入」—— 真接的时候用 `speech_to_text` 之类的插件，**不要**把平台专属实现硬搬 |
| 系统文件选择器（SAF） | Flutter 侧 `kit_io.dart` 的 `FileEntityStore` 走普通文件路径；需要 SAF 就走插件 |

---

## D 组：部分被取代

| 旧组件 | 现在的对应物 |
|---|---|
| 大图头像 | `components/avatar.dart` 的 `UserAvatar` / `AvatarStack` / `ExpandedAvatarRow` 覆盖了绝大部分；「大图 hero」那种展示没搬 |
| 联系人头像条目 | 同文件的 `ContactItem` |
| 日期扩展 / 日期格式化 | `ui/format/date_display.dart` |
| 页面转场 | `components/motion.dart` 的 `AnimatedContentSwitch` |

---

## 搬一个组件回来要做什么

1. 从旧实现备份里读懂**行为**（不是抄代码），
2. 在 `kit/lib/src/ui/components/` 写 Dart widget，样式全部走 `KitTheme.of(context)` 取 tokens，
3. 导出到 `kit/lib/kit_ui.dart`，
4. 补一个 widget 测试（`kit/test/`），
5. `bash scripts/ci.sh all`。

改到底座（`kit/`）会触发 `base-guard` —— fork 的 app 只能新增、不能改底座，
所以**组件要放底座就得往上游提 PR**。
