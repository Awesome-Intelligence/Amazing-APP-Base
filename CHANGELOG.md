# 更新日志

本项目遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，
版本号用 [语义化版本](https://semver.org/lang/zh-CN/)。

## [未发布]

### 变更（破坏性）
- **提示条统一成 `AppNotice`**（2026-11-19）。`AppSnackbar` / `showAppSnackbar` 删除，
  换成 `AppNotice` / `NoticeSeverity` / `showAppNotice`：
  - 级别 `info` / `success` / `warning` / `error`，图标 + 容器色一起变；
  - 内联形态走级别容器色（`successContainer` / `warningContainer` / `errorContainer` /
    `secondaryContainer`），浮动形态走 M3 SnackBar 的 `inverseSurface`；
  - 圆角一律 `shapes.small`，不再写死 28dp。
  - `ToolApprovalCard` 的配色改从同一套映射取（`warning` 级），
    聊天里的错误消息从裸 `⚠️` 文本换成 `AppNotice(error)`。
- **底座全量重写为 Flutter/Dart（2026-11-16）**。旧实现备份在仓库外
  `E:/Awesome Intelligence/kmp-legacy-backup/`，不再演进。包结构：
  `kit/` / `kit-agent/` / `kit-membership/` / `chat-demo/` / `apps/demo/`。
  依赖管理换成 **pub workspace**（根 `pubspec.yaml` 一次 `flutter pub get` 解析全部包）。
- **agent 运行时换成 `dart_agent_core`**。契约保持不变：
  `AgentRuntime` / `AgentSession` / `SkillDefinition` / `SkillTool` / `AgentEvent` / `ToolApprover` / `ChatLog` /
  `SkillContract` / `SkillSamples`。审批闸门改接 `AgentHook.beforeToolCall`，
  语义仍是「执行前拦截、拒绝理由作为工具结果回给模型」。
- **主题从「每种风格一组组件」改成 token 驱动**：一套组件 + 5 套 `ThemeTokens`（Mono / Swiss / Notion / EInk / macOS）。
  风格专属组件集不再搬 —— 架构上已被 tokens 取代。
- **门禁换套**：`analyze` / `test` / `contract` / `verify` / `base-guard`，全部收在 `scripts/ci.sh`。
  `verify-kit.py` / `verify-i18n.py` / `verify-skills.py` / `merge_strings.py` / `install-kit.sh` /
  `new_app.py` 删除。新增 `verify_contract.py` / `verify_layers.py` / `checks/no-hardcoded-secrets.sh`。
- **平台覆盖扩到四端**：Android / iOS / Desktop / **Web**。

### 新增
- **接入业界现成的推送栈**（2026-11-20）：
  - **ntfy** —— 传输层在底座：`kit` 新增 `NtfyClient`（纯 HTTP、零凭据，
    和 `HttpUpdateSource` 一个性质）。助手回复可以推到 ntfy，app 轮询取回。
  - **flutter_local_notifications**（app 层）—— 收到消息弹真正的系统通知。
    Android 需要 `compileSdk 37` + core library desugaring，已在
    `apps/demo/android/app/build.gradle.kts` 配好。
  - **firebase_messaging / FCM**（app 层）—— 应用被杀也能到的后台推送。
    用 `FirebaseOptions` 从 `--dart-define` 注入，**不需要 google-services.json**；
    客户端 `POST /v1/devices` 登记 token 到网关。
  - **网关**：新增 `POST /v1/notify` 与 `POST /v1/devices`；调用带 `notify: true`
    时，助手回复完成（或出错）会推给该用户（ntfy + FCM 各一条通道）。
  - 凭据全走环境变量 / `--dart-define`，代码里不写死。
- **`KitAppShell` / `KitApp` 支持自带路由**：给 `routerConfig`（`go_router` 的 `RouterConfig` 等）
  就走 `MaterialApp.router`，主题和文案照样注入到路由里的每个页面 —— 底座仍然不内置路由。
- **demo 换成 `go_router` 嵌套导航**：四个页签各占一个分支（`StatefulShellRoute.indexedStack`），
  切页签不重建页面（栈和滚动位置都留着）、深链直达 `/todo` `/notifications` `/gallery` `/templates`、
  web 上 URL 跟着页签走。返回键三段语义：退分支内的页 → 回第一个页签 → 才退出 app。
- **扩展色补 `onSuccessContainer` / `onWarningContainer`**（5 套主题 × 明暗 = 10 个值）。
  之前只有容器底色、没有配套前景色 —— 成功/警告提示条拿强调色当文字色，
  在自己的底上普遍达不到 4.5:1（`theme_tokens_test.dart` 现在会逐套卡这条）。
- **`chat-demo/` 换成 Flutter 桌面应用**：`--fake` 走本地假运行时（不联网、不花钱、不需要 key）。
- **`kit-agent` 补 `FakeAgentRuntime` + `AllowAllApprover`**。
- **`kit/lib/src/update` 版本检查模块**：`AppVersion`（semver，含 `1.10.0 > 1.9.0`、`1.2.3-beta < 1.2.3`）/
  `UpdateChecker`（节流 → 拉清单 → 比版本，失败也记时间）/ `HttpUpdateSource` / `GitHubReleaseSource` /
  `UpdateDialog`（强制更新不可关闭）+ demo 的 `UpdateGate`。
- **跨端契约闭环**：`apps/demo/contract/actions.json` + Dart 动作表 + 小程序端动作表，两端跑同一批黄金样例；
  `runAsyncActionSamples` 适配 async 业务层。
- **会员框架 + 付费墙 UI**：`kit-membership` 纯逻辑（档位表 / 额度 / 落盘 / 验签），UI 在 `kit/lib/src/ui/membership/`
  （`MembershipPaywall` / `QuotaPaywall` / `UpgradeSheet`）。
- **i18n**：`KitStrings`（中文 / English 两个 const 子类）+ `KitStringsScope`，运行时切换，
  Material 内置控件文案跟着切（`flutter_localizations`）。
- **`FLUTTER_MIGRATION.md`**（新）：**未迁组件清单** —— 哪些组件故意没做、为什么，
  以及「想搬一个组件回来要做什么」。
- **`scripts/verify_gateway.py`**（新）：跨语言比对网关协议 —— 抓 `backend/src/agent.ts` 的事件名与字段，
  跟 Dart 端的映射表对齐，不一致直接失败（跑在 `ci.sh verify`）。
- **`ci.sh backend` 子命令**（新）：`npm run check`（类型检查）+ `npm run smoke`（冒烟），
  挂进 `ci.sh all` 和 CI 的 `Backend (gateway)` job。
- **`kit/lib/src/ui/agent/chat_message_mapper.dart`**（新）：运行态消息 → 展示态消息的**唯一**映射。
  之前 `chat-demo` 和 `apps/demo` 各写一份 `_uiMessages()`，早晚会分叉。
- **站内消息（通知）数据层 + 列表**：`kit/lib/src/notification/notification.dart`
  （`AppNotification` / `NotificationStore`，落在 `EntityStore` 上，内存 / 文件通用）+
  `kit/lib/src/ui/components/notification_list.dart`（`AppNotificationList`，含空态与未读点）。
  demo 底栏角标改成真实未读数（原来写死 `badgeCount: 3`），多一个「通知」页签。
  **不含平台推送** —— FCM / 系统通知归 app 层。

### 修复
- **网关事件映射对不上**：后端发 `start` / `text` / `tool` / `result{output}`，
  而 Dart 端认的是 `tool_use` / `tool_done` / `tool_failed` / `result{text}` —— 工具调用和
  结束标记在链路上直接丢了。后端改成发 kit 的 `AgentEvent` 词表（`result` 同时带 `text` 和
  `output`），Dart 端补齐映射；`kit-agent/test/gateway_protocol_test.dart` 用假 SSE 钉住每种事件。
- **`sessionId` 取不到**：续接用的 sessionId 之前从 `result` 里读，而后端从来不发 ——
  现在由 `start` 事件带，Dart 端改从 `start` 取，续接才真正生效。
- **根 `pubspec.yaml` 的 workspace 成员**：从逐个列包改成 `apps/*` 通配，新 app 不用改根 pubspec
  （新 app 的 pubspec 必须写 `resolution: workspace`）；`chat-demo` 移出「底座」名单。
- **`verify_contract.py` 不写死文件名**：动作表改成按约定找（`lib/**/*actions*.dart` /
  `miniprogram/logic/**/*actions*.js`），app 换文件名不用改这个脚本。
- **`verify_layers.py` 漏了 `export`**：只看 `import` 的话，`export 'package:app/...'` 能绕过分层检查。
- **旧构建残留清理**：`kit-membership/api/desktop/kit-membership.api`、`kit-membership/build.gradle.kts`
  删除；`rules/COMPONENT_SPEC.md` 里的旧版代码示例换成 Flutter 实现的真签名。
- **子模块门禁丢了**：文档写着 `ci.sh` 有一道 `submodules` 门禁，脚本里其实没有 —— 补回
  `scripts/checks/submodules.sh`（`verify` 会跑），CI 的 `verify` job checkout 带 `submodules: true`。
- **base-guard 没豁免子模块路径**：文档说挪子模块指针不算「改底座」，脚本里没这条 —— 补上；
  顺带修掉「clone 没带 `--recurse-submodules`」时子模块目录显示成已删除的误报。
- **`install-kit.sh` 的悬空引用**：该脚本在迁移时已删，`skills/README.md` / `rules/SUBMODULES.md`
  里还写着它 —— 改成按 fork 模式说明怎么拷 skill。
- **`ci.yml` 里多出来的一道 `base-guard` job**（迁移时误加）：和 `.github/workflows/base-guard.yml`
  重复，且有两个问题 —— 上游自己改底座的 PR 会在它上面误报红；更要命的是它用 `pull_request` 触发、
  checkout 的是 PR 的代码，fork 改一下 `check-base-unchanged.sh` 就把自己放过去了（正是
  `base-guard.yml` 用 `pull_request_target` 要避开的洞）。删掉，底座保护只留 `base-guard.yml` 一处。
- **`.github/actions/setup-gradle` 删除**：旧时代的 composite action，迁移后没有任何 workflow
  引用它 —— Flutter 用 `subosito/flutter-action`，不需要它。
- **旧实现残留清理**：底座里约 100 处「对应旧版某类」的对照注释、README 的旧版对照表、
  CHANGELOG 的旧实现历史段全部删除；`FLUTTER_MIGRATION.md` 改写为「未迁组件清单」；
  `.github/CODEOWNERS` 里指向已删除目录（`/kit-agent-koog/`）和已不存在的锁文件
  （`/gradle/libs.versions.toml`）的死规则修正。
- **规范里的旧实现 API 清干净**：`rules/GOOGLE_STYLE.md` / `rules/COMPONENT_SPEC.md` 里
  一整套只存在于旧实现的动效 API（`fastSpatial()` / `NavTransitions` / `LocalReducedMotion` /
  `Modifier.animateItem` / `M3Motion.fadeThrough()` 等）与 Kotlin 代码块，按 Dart 侧真实实现
  重写（`M3Motion` 时长 / 曲线令牌、`motionDuration`、`CollapsibleSection`、
  `AnimatedContentSwitch`、`KitTheme.reducedMotionOf`）；`skills/README.md` 里指向旧目录树的
  动效令牌路径改正；`scripts/_template.py` 里没人用的 `escape_kotlin` 删除。
