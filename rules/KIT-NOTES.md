# Kit 说明 —— 边界在哪、为什么这么取舍

这份文档给**接手 kit 的人**看：知道边界在哪，比知道里面有什么更重要。

---

## 〇、形状：pub workspace，五个包

```
pubspec.yaml（workspace 根）
├── kit/              UI 组件 + 数据层（存储 / 设置 / 契约 / 版本检查 / 多语言）
├── kit-agent/        agent 契约 + dart_agent_core 封装 + 网关客户端
├── kit-membership/   会员 / 额度框架（纯 Dart，零依赖）
├── chat-demo/        桌面对话 demo（验证 kit + agent 链路）
└── apps/demo/        示例 app（fork 后你的 app 放 apps/<name>/）
```

依赖方向严格单向：`apps/* → kit / kit-agent / kit-membership`。
`scripts/verify_layers.py` 盯着这条线 —— 底座反向依赖 app 会直接失败。

**为什么用 pub workspace 而不是 melos**：Dart 3.6+ 原生支持 workspace，一次 `flutter pub get`
解析全部包，不额外引一个工具链。melos 的价值在跑脚本，而门禁脚本已经集中在 `scripts/ci.sh`，
再叠一层只会让「谁跳过哪个包」说不清。

## 〇.a 入口分层：`kit.dart` / `kit_io.dart` / `kit_ui.dart`

Dart 没有 source set，用**分入口导出**做编译期隔离：

| 入口 | 依赖 | 谁能用 |
|---|---|---|
| `package:kit/kit.dart` | 纯 Dart（dart:core / convert） | Web、小程序工具链、CLI、单元测试 |
| `package:kit/kit_io.dart` | `dart:io`（文件实现） | 移动 / 桌面 / CLI |
| `package:kit/kit_ui.dart` | Flutter（主题 + 组件 + 文案） | Flutter app |

`kit.dart` 一旦 import 了 `dart:io`，Web 构建直接挂 —— 所以文件实现（`FileEntityStore` /
`FileUpdateStateStore`）永远只在 `kit_io.dart` 里。app 侧需要「Web 退化成内存」时
用条件导出（见 demo 的 `update_state_store_factory.dart`）。

## 〇.b 主题：token 驱动，一套组件

「每种风格各写一组组件」这条路**刻意不走**（同一件事要写四遍，越维护越歪）：

- 只有一套组件，从 `KitTheme.of(context)` 取当前 tokens（颜色 / 扩展色 / 排版 / 圆角 / 标签色板）
- 加一种风格 = 加一套 tokens（`theme_tokens.dart` 里一个工厂），不写新组件
- 5 套预设：Mono / Swiss / Notion / EInk / macOS

**代价**：风格专属的视觉细节（毛玻璃的 vibrancy 层、E-Ink 的网点底纹）只能靠 tokens
表达，表达不了的就退化。要恢复某个风格的真·专属组件时，把它作为可选组件放到 `ui/components/`，
由 app 自己挑 —— 别塞回底座把所有风格都拖上。

主题色值/排版/ColorScheme **不手抄**：整套值是一次性脚本换算过来的，改的时候
照着现有值核对。注意 Flutter 的 `TextStyle.height` 是**字号倍数**，不是绝对行高。

## 〇.c 存储：引擎 + codec 两层

`EntityStore`（引擎：内存 / 文件 / 未来数据库）+ `StoreCodec`（格式：`.json` / `.md` / 自定义）。
字段是 `Map<String, Object?>`，`Fields` extension 做宽松转换（`intOr` / `boolOr` / `listOrEmpty`）。

**规矩**：格式不锁死 markdown；旧文件读不坏（解码失败回默认值，不抛）；
需要关系型查询再上 drift/sqlite，别一开始就上。

## 〇.d agent：契约在 kit-agent，引擎可换

| 文件 | 内容 |
|---|---|
| `agent_runtime.dart` | 契约：`session(skill, {approver})` → `send(input)` 返回 `Stream<AgentEvent>` |
| `skill_definition.dart` | skill = systemPrompt + 工具集 + 模型/maxTurns |
| `skill_tool.dart` | 工具基类：名字 + 描述 + JSON Schema + `execute(args)` + `requiresApproval` |
| `tool_approval.dart` | `Allow` / `AllowAlways`（本任务免确认）/ `Deny`（理由回给模型）+ `AllowAllApprover` |
| `agent_event.dart` | `Text`（**流式增量块**）/ `ToolUse` / `ToolDone` / `ToolFailed` / `Result` / `Error` |
| `chat_log.dart` | 事件 → 消息列表（UI 只认消息，不认事件） |
| `fake_agent_runtime.dart` | 假运行时：不联网、不花钱、不需要 key |
| `engine/dart_agent_runtime.dart` | 本机实现（`dart_agent_core`） |
| `engine/gateway_agent_runtime.dart` | 后端实现（HTTP + SSE） |

**为什么引擎放在单独的 `engine/`**：框架耦合集中在一个目录，换框架只动这两三个文件。
`dart_agent_core` 的 API 踩坑（都已在文件注释里写明）：

- 审批闸门接 `AgentHook.beforeToolCall`，返回 `ToolCallHookResult.proceed()` / `deny(reason:)` ——
  不是 `AgentController`（旧文档里写的那个是猜的）
- `functionCallRequest` 事件的 `data` 是 **`List<FunctionCall>`**，不是单个
- `functionCallResult` 事件的 `data` 是 **`FunctionExecutionResultMessage`**（含 `results` 列表）

后两条踩错会在**首次调用工具时**崩溃，而纯契约单测发现不了 —— 所以有
`integration_dart_agent_runtime_test.dart` 用脚本化假 LLM 跑真实 loop。

## 〇.e 审批闸门：执行前拦截，不是 UI 提示

`requiresApproval = true` 的工具，执行前一定先问 `ToolApprover`：不放行就**根本不执行**，
拒绝理由作为工具结果回到模型，模型自己改道。闸门接在 `dart_agent_core` 的工具执行钩子上，
不是 UI 上弹个提示 —— 提示可以被绕过，执行前拦截不行。

「本任务免确认」的范围是**一轮对话**（存在 session 的 `_allowAlways` 集合里）：
换 skill、重启 app 都得重新问。

## 〇.f 逻辑 api 化

UI 的按钮和 agent 的工具必须调**同一个** data 层函数，连结果文案都是同一句。
规范原文见 `rules/CLAUDE.template.md`；落地例子见 `apps/demo/lib/todo_store.dart` +
`todo_skill.dart` + `todo_chat_page.dart`。

## 〇.g 检查更新

`kit/lib/src/update/`：`AppVersion`（semver 比较）+ `UpdateChecker`（节流 → 拉清单 → 比版本）
+ `HttpUpdateSource` / `GitHubReleaseSource` + `UpdateStateStore`。

**为什么拆这么细**：版本号来自网络，一条脏数据不能把 app 打崩 ——
`AppVersion.parseOrNull` 解析不出来就返 null；`UpdateChecker` 把所有异常兜成 `FailedResult`；
失败也记检查时间，否则离线用户每次冷启动都要白等一次超时。

UI 侧 `UpdateDialog` 的强制更新**不可关闭**（`PopScope(canPop: false)` +
`barrierDismissible: false`），点「立即更新」后**继续挡着**；没有下载地址时降级成可关闭 ——
不留死胡同。

## 〇.h 多语言

`KitStrings`（抽象类 + `_ZhStrings` / `_EnStrings` 两个 const 子类）+ `KitStringsScope`。
**不引 intl/ARB**：底座文案只有几十条，走代码生成会让下游改一句话都得跑 build。
加一门语言 = 加一个子类；加一条文案 = 两个子类各加一行（漏一边就是英文界面里冒中文）。

`KitAppShell` 把 `AppSettings.language` 落到 `MaterialApp.locale`，
同时 `flutter_localizations` 让 Material 内置控件（日期选择器、复制菜单）也跟着切。

## 〇.i 会员 / 付费

`kit-membership/` 纯 Dart、零依赖：`PlanCatalog` + `MembershipManager` + `MembershipStore` +
`UsageTracker`。付费墙/升级页 UI 在 `kit/lib/src/ui/membership/`（依赖方向反过来）。

| 规矩 | 为什么 |
|---|---|
| 档位表写在代码里，不从服务器下发 | 下发的话额度上限能被随便改 |
| 会员资格只认**已验过签**的购买 | 没验签的购买等于送会员 |
| 过期 / 没验签 / 找不到档位 → 按免费档算 | 一个分支就够，不用到处判 |
| 额度用 `consume()` 扣，不自己加 | 扣了才知道超没超，扣超了不动计数 |
| 平台 SDK 不进这个模块 | 公共层不留计费 |

## 〇.j 跨端契约

小程序端**不是** Flutter 的 target —— 它没有 VM，跑不了 agent。所以它**不含 agent**，
跨端共享的是**契约**（`apps/<name>/contract/actions.json`）而不是代码。
各端各实现一份动作表，跑同一批黄金样例：谁改了行为或文案，红的就是谁。
见 `rules/MULTI-CLIENT.md`。

## 〇.k 平台能力归 app 层

底座不写平台接口（跳转商店、桌面快捷方式、通知、传感器）。理由：底座要给所有 app 用，
一旦有平台代码就得为每个平台维护一份，且 fork 下游想换实现得改底座。

例外只有一个，且不碰任何系统 API：**站内消息**（`AppNotification` / `NotificationStore` /
`AppNotificationList`）——它只是 app 内部的数据模型和列表，真发系统通知（FCM / 本地通知）
照样归 app 层。

推送的**传输层**可以在底座（`NtfyClient` —— 纯 HTTP，不碰任何系统 API，和
`HttpUpdateSource` / `GitHubReleaseSource` 一个性质）；**平台层**（`flutter_local_notifications`
弹系统通知、`firebase_messaging` 收后台推送）留在 `apps/*`。分界线还是「有没有系统 API」。

## 〇.l Flutter 踩坑记录（改这块前先看）

| 坑 | 现象 | 处理 |
|---|---|---|
| redirecting factory 构造器不能带默认值 | `default_value_in_redirecting_factory_constructor` | 默认值放目标构造器 |
| `AssistChip` 在 3.50 不存在 | 编译报 undefined | 用 `ActionChip` |
| `Radio.groupValue/onChanged` 已弃用 | analyze 报警 | 用 `RadioGroup` 包住子树 |
| `FilterChip` 默认画勾 | 和设计不符 | `showCheckmark: false` |
| 横向滚动里的 chip 不能用 `Flexible` | 无界宽度断言 | label 直接 `Text` |
| `double.clamp()` 返回 `num` | 类型不匹配 | `.toDouble()` |
| `showModalBottomSheet` 没有 `surfaceTintColor` | 参数不存在 | `elevation: 0` |
| 无限动画让 `pumpAndSettle` 永远等不到静止 | 测试超时 | 用 `TickerMode(enabled:)` 停 ticker |
| `IndexedStack` 一次构建所有页 | 骨架屏动画让测试挂 | 换 `StatefulShellRoute.indexedStack`：没访问过的分支不构建，切走的分支 `Offstage` + ticker 停 |
| Dart 的 `Duration` 是绝对时长 | 夏令时切换那天日期偏移 | 日期加减用 `DateTime(y, m, d + n)` |
| `dart fix --apply` 会乱改 import | 一次性搞坏 5 个文件 | 别对全仓无脑跑 |
| `node --test test/` 不认目录 | 0 个测试 | 用 glob：`node --test "test/*.test.js"` |

## 〇.m 明确不做的

- **不做 expect/actual 式的平台接口层**（用户拍板）—— 平台能力归 app
- **搬业务架构**（Repository / DI 容器 / 路由框架）—— 这个规模用不上
- **9 个可选展示组件**（MarkdownEditor / FilterBottomSheet / AIComponents /
  NotificationsButton / CollapsingHeader / CheckinHeatmapCard / HorizontalDateBar /
  TagPickerBottomSheet / AvatarHero）—— 真用到再补；每个为什么没迁、搬回来要做什么，
  见 [`FLUTTER_MIGRATION.md`](../FLUTTER_MIGRATION.md)
