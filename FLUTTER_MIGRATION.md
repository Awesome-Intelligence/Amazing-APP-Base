# Flutter 迁移清单（KMP → Flutter，2026-11-16）

原 KMP（Kotlin + Compose Multiplatform）实现在仓库外 `E:/Awesome Intelligence/kmp-legacy-backup/`，
**不再演进**。这份文档记两件事：迁了什么、**没迁什么**。

没迁的组件不是「忘了」，是**判断过不值得**。真要用，从备份里挑实现搬进
`kit/lib/src/ui/components/`，别把整个 KMP 树拉回来。

---

## 一、底座包对照

| KMP 模块 | Flutter 包 | 状态 |
|---|---|---|
| `:kit` | `kit/`（`kit.dart` / `kit_io.dart` / `kit_ui.dart` 三入口） | ✅ 迁完 |
| `:kit-agent-koog` | `kit-agent/`（契约不变，运行时换成 `dart_agent_core`） | ✅ 迁完 |
| `:kit-membership` | `kit-membership/` | ✅ 迁完 |
| `chat-demo` | `chat-demo/` | ✅ 迁完（`--fake` 假运行时） |
| `apps-demo` | `apps/demo/` | ✅ 迁完 |
| 组件目录页（`ComponentGallery` / `ShowcaseCatalog`） | `apps/demo/lib/gallery_page.dart` | ✅ 迁完 |

依赖方向（`scripts/verify_layers.py` 盯着）：
`apps/* → kit → kit-agent / kit-membership`，底座不许反依赖 app。

---

## 二、**没迁**的组件（9 组）

按「要不要」排序。A 组是真有价值的业务组件，B 组是风格专属（已被 token 体系取代），
C 组是平台相关，D 组是部分被替代。

### A 组：业务组件（想要就搬）

| 组件 | KMP 行数 | 里面有什么 | 现状 |
|---|---|---|---|
| `AIComponents.kt` | 615 | `AIActionButton` / `AIInsightCard` / `AILoadingSkeleton` / `AISuggestionBadge` / `AISuggestionChip` / `AISuggestionItem` / `BreathingIcon` / `GoalAIButton` | 未迁。AI 相关的视觉件，自带插画与呼吸动效，**依赖旧插画资源**，整组搬过来要重做素材 |
| `FilterBottomSheet.kt` | 524 | `FilterBottomSheet` / `DateRangeFilter` / `MoodFilterChips` / `ImportanceFilterChips` / `MultiSelectFilterChips` / `SingleSelectFilterChips` / `TagFilterChips` / `FilterSection` | 未迁。筛选**芯片**组件已迁（`chips.dart` 的 `KitFilterChip`），只差底部弹窗壳 + 业务维度 |
| `NotificationsButton.kt` | 412 | `NotificationsButton` + 通知面板（空态 / 行） | 未迁。纯业务列表壳，底座没有通知数据模型，app 自己写更合适 |
| `MarkdownEditor.kt` | 420 | `MarkdownEditor` / `MarkdownPreview` | 未迁。Flutter 侧已有富文本/编辑器依赖可选，底座不绑第三方 Markdown 方案 |
| `CollapsingHeader.kt` | 371 | `CollapsingHeader` / `HeaderTitlePreview` | 未迁。**部分能力有**：`kit/lib/src/ui/components/motion.dart` 的 `CollapsibleSection`（折叠） + `header.dart` 的 `Header`，但没有「滚动时收缩标题」那种联动 |
| `CheckinHeatmapCard.kt` | 363 | `CheckinHeatmapCard` + 热力格 + 统计 chip | 未迁。纯业务（打卡）组件，`kit` 不该知道「打卡」是什么 |
| `HorizontalDateBar.kt` | 294 | `HorizontalDateBar` + 日期格 | 未迁。已有 `calendar.dart`（月视图日历），横向条是另一种交互，真要用再写 |
| `MarkdownToolbar.kt` | 278 | `MarkdownToolbar` + 分隔 + 图标按钮 | 未迁。同上，跟编辑器一起走 |
| `TagPickerBottomSheet.kt` | 265 | `TagPickerBottomSheet` | 未迁。**标签芯片已迁**（`chips.dart` 的 `AddTagChip` / `SelectableTag`），只差弹窗壳 |

> 这 9 组加一起约 **3500 行 Kotlin**。共同点：要么绑死业务语义（打卡 / 通知），
> 要么绑死旧素材（插画），要么有现成的 Flutter 第三方方案。
> **判断标准**：只有「app 一上来就要用」才值得现在搬。

### B 组：风格专属组件（token 体系已取代，**故意不迁**）

| 文件 | 行数 |
|---|---|
| `EInkComponents.kt` | 439 |
| `MacOSComponents.kt` | 412 |
| `NotionComponents.kt` | 285 |
| `SwissComponents.kt` | 269 |
| `SwissLayout.kt` | 136 |

KMP 版是「每种风格一组组件」（同一件事写 4 遍）。Flutter 版改成 **token 驱动**：
一套组件 + 5 套 `ThemeTokens`（Mono / Swiss / Notion / EInk / macOS），
`KitTheme.of(context)` 取当前 tokens。加风格 = 加一套 tokens，不用再写一遍组件。

**不要把这几个文件搬回来** —— 搬回来就等于退回「每套风格一组组件」的老路。

### C 组：平台相关

| 组件 | 行数 | 说明 |
|---|---|---|
| `SpeechInput.kt`（Android only） | 86 | 系统语音输入。Flutter 端 `ComposerField` 的麦克风按钮留了接口，demo 里点它提示「语音输入暂未接入」—— 真接的时候用 `speech_to_text` 之类的插件，**不要**把 Android 专属实现硬搬 |
| `SafStorageEngine.kt`（Android only） | 231 | Storage Access Framework 存储。Flutter 侧 `kit_io.dart` 的 `FileEntityStore` 走普通文件路径；需要 SAF 就走插件 |

### D 组：部分被替代

| 组件 | 行数 | Flutter 侧对应 |
|---|---|---|
| `AvatarHero.kt` | 122 | `kit/lib/src/ui/components/avatar.dart` 的 `UserAvatar` / `AvatarStack` / `ExpandedAvatarRow` 覆盖了绝大部分；「大图 hero」那种展示没搬 |
| `ContactAvatarItem.kt` | 94 | 同文件的 `ContactItem` |
| `DateExt.kt` / `DateFormatting.kt` | — | `kit/lib/src/ui/format/date_display.dart` |
| `NavTransitions.kt` | — | `kit/lib/src/ui/components/motion.dart` 的 `AnimatedContentSwitch` |

---

## 三、迁了但**改名/换形态**的（找代码时看这里）

| KMP | Flutter | 备注 |
|---|---|---|
| `FilterChip` | `KitFilterChip` | 加 `Kit` 前缀避开 Material 同名 |
| `AppIconButton` | `FilledIconButton` | Material 图标按钮，Flutter 版用 `IconData` 而不是内容 lambda |
| `Tag` | `TagText` | 另有 `SelectableTag` / `AddTagChip` |
| `MenuItem` / `MenuButton` | `SimpleMenuItem` / `SimpleMenuButton` | 另有 `ActionMenuRow` |
| `Card` / `SmallCard` | `AppCard` / `SmallCard` | `Card` 跟 Flutter 内置类撞名 |
| `RecordCard` | — | 未迁，见 A 组 |
| `AppTheme` | `AppTheme`（`kit/lib/src/theme/app_theme.dart`） | 现在带 `ThemeStyle` + `tokens`，5 套风格走同一入口 |

组件规范见 `rules/COMPONENT_SPEC.md`（里面的代码示例已全部换成 Flutter 实现的真签名）。

---

## 四、搬一个组件回来要做什么

1. 从 `kmp-legacy-backup/` 的 `.kt` 里读懂**行为**（不是抄代码），
2. 在 `kit/lib/src/ui/components/` 写 Dart widget，样式全部走 `KitTheme.of(context)` 取 tokens，
3. 导出到 `kit/lib/kit_ui.dart`，
4. 补一个 widget 测试（`kit/test/`），
5. `bash scripts/ci.sh all`。

改到底座（`kit/`）会触发 `base-guard` —— fork 的 app 只能新增、不能改底座，
所以**组件要放底座就得往上游提 PR**。
