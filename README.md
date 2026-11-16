# Flutter Skill APP（Android-Kit 底座）

**Flutter 底座** —— agent 应用的最小完整形态：**UI + skill + agent 循环 + 跨端契约**，
一套 Dart 代码跑 Android / iOS / Desktop / Web。

> 这个仓库原来是 Compose Multiplatform（Kotlin + Koog）版本，2026-11-16 全量换成 Flutter。
> Kotlin 源码备份在仓库外 `E:\Awesome Intelligence\kmp-legacy-backup\`，不再演进。

---

## 一句话架构

```
手机 app
┌────────────────────────────────────────────────┐
│  前端 (Widget)  →  skill (systemPrompt+工具)    │
│                        ↕                        │
│                  agent 循环 (dart_agent_core)   │
│                        ↓                        │
│              工具 = 本机能力（读写本地数据…）    │
└───────────────────┬────────────────────────────┘
                    │ 只有模型调用出网
                    ▼
        Anthropic API（或自建转发代理）
```

**数据不离开设备**：出去的只有对话文本和工具返回值；用户数据、工具执行都在端上。
架构细节见 **[`ARCHITECTURE.md`](ARCHITECTURE.md)**。

## 目录

```
KMP Skill APP/
├── pubspec.yaml               pub workspace 根（一次 pub get 解析全部包）
├── kit/                       ← 底座（fork 不许改）UI 组件 + 数据层
├── kit-agent/                 ← 底座：agent 契约 + dart_agent_core 封装 + 网关
├── kit-membership/            ← 底座：会员/额度框架（纯 Dart，零依赖）
├── chat-demo/                 桌面对话 demo（验证 kit + agent 链路）
├── apps/
│   └── demo/                  ← 示例 app（fork 后你的 app 放 apps/<name>/）
│       ├── lib/               业务：TodoStore / TodoSkill / 页面 / UpdateGate
│       ├── contract/          actions.json —— 各端共享的契约
│       └── miniprogram/       微信小程序端（纯 JS，无 agent）
├── backend/                   agent 网关（TypeScript，可选）
├── scripts/ci.sh              所有门禁的唯一出处（CI 与本地同一份）
├── scripts/verify_*.py        契约对齐 / 分层检查 / 网关协议检查
├── FLUTTER_MIGRATION.md       KMP → Flutter 迁移清单（迁了什么、没迁什么）
└── .github/workflows/ci.yml   只声明「在什么环境跑哪道门禁」
```

## 快速开始

```bash
# 1. 装 Flutter（3.50+，Dart 3.14+）
# 2. 解析依赖（workspace 一次搞定）
flutter pub get

# 3. 跑示例 app
cd apps/demo && flutter run -d windows    # 或 chrome / android / ios

# 4. 桌面对话 demo（不联网、不花钱）
cd chat-demo && flutter run -d windows --dart-entrypoint-args --fake

# 5. 提交前跑门禁
bash scripts/ci.sh all
```

flutter 不在 PATH 时，脚本支持 `FLUTTER_BIN=/path/to/flutter`。

接真模型：`ANTHROPIC_API_KEY` 通过环境变量传给 `DartAgentRuntime`；
**别写进仓库**，打进包里也能被提取出来。正式上架把 `baseUrl` 指向自己的转发代理。

## 门禁

```bash
bash scripts/ci.sh all        # bootstrap + analyze + verify + test + contract + backend
bash scripts/ci.sh build      # 构建 demo（Web + Android debug）
bash scripts/ci.sh base-guard # 底座保护（fork 必跑）
```

| 门禁 | 查什么 |
|---|---|
| `bootstrap` | `pub get`（workspace 一次解析） |
| `analyze` | `dart analyze` / `flutter analyze`，**零 issue** 才算过 |
| `test` | 各包的单元测试 + widget 测试 |
| `contract` | 小程序端动作表跑 `contract/actions.json` |
| `verify` | 契约动作名与各端一致、底座不许反依赖 app、网关事件两端对得上、无硬编码密钥 |
| `backend` | 网关类型检查 + 冒烟（`backend/` 不在时自动跳过） |
| `base-guard` | 改动碰到 `kit/` 等底座路径就失败（fork 必跑） |
| `build` | 构建 demo（Web + Android debug） |

**门禁逻辑只写在 `scripts/ci.sh` 里**，workflow 只负责环境 —— fork 想加自己的门禁，
往 `scripts/checks/` 放个 `.sh` 就行，不用改 workflow（改了会跟上游冲突）。

## fork 模式

本仓库是**底座**：各 app fork（或 clone）本仓库，在 `apps/` 里长出自己的壳，
靠 `git pull upstream main` 跟进底座更新。

**唯一规矩：只新增、不改底座**（`kit/`、`kit-agent/`、`kit-membership/`、`chat-demo/`、
`scripts/ci.sh`、`.github/`、根 `pubspec.yaml`）。改了，pull 就冲突，更新链就断。
底座能力不够就回上游提 PR，别在下游打补丁。

加新 app：

```bash
cp -r apps/demo apps/myapp
# 改 apps/myapp/pubspec.yaml 的 name、lib/ 里的业务代码、contract/actions.json
# 改 apps/myapp/pubspec.yaml 加一行 resolution: workspace  ← 必须！
```

`resolution: workspace` 是 pub workspace 的硬要求：不写这行，根 `pubspec.yaml` 的
`apps/*` 不会把这个包纳入解析，`flutter pub get` 直接报错。

包清单**不用注册**：根 `pubspec.yaml` 用的是 `apps/*` 通配，`scripts/ci.sh` 也是扫
`apps/*/` —— 新建目录就完事。（`chat-demo` 单独列在根 `pubspec.yaml` 里，
因为它是桌面 demo，不是 app。）

## 业务只该出现在两个地方

| 位置 | 是什么 |
|---|---|
| `apps/<name>/lib/<X>Store.dart` | 业务数据 + 业务动作（校验、分支、结果文案都在这一层） |
| `apps/<name>/lib/<X>Skill.dart` | 业务 skill：人设（systemPrompt）+ 工具集，工具只单行透传给 Store |

**一份逻辑两处用**：UI 的「删」按钮和 agent 的 `delete_todo` 工具调的是**同一个**
`TodoStore.remove` —— 连结果文案都是同一句。这样 agent 删的和你删的，行为不会分叉。
规范原文见 `rules/CLAUDE.template.md` 的「逻辑 api 化」一节。

## 跨端契约

同一个业务跑在几个界面上（Android / iOS / Desktop / Web / 微信小程序）。
界面各写各的，只有「动作名 + 结果文案」是共享的 —— 那部分写成 `contract/actions.json`，
各端各实现一份动作表，再各跑同一批黄金样例：**谁改了行为或文案，红的就是谁**。

| 端 | 动作表 | 跑样例 |
|---|---|---|
| Flutter | `apps/<name>/lib/todo_actions.dart` | `flutter test`（`test/todo_contract_test.dart`） |
| 小程序 | `apps/<name>/miniprogram/logic/actions.js` | `node --test "apps/<name>/miniprogram/test/*.test.js"` |

完整规矩见 `rules/MULTI-CLIENT.md`。

## 会员 / 付费（`kit-membership/`）

可选模块，**平台无关**：框架只管「谁是会员、能用多少」，不管「钱怎么收」。

```
业务侧一张档位表（PlanCatalog）        各端 app 自己实现的通道（Play Billing / StoreKit）
        ↓                                            ↓
   MembershipManager ←── MembershipStore / UsageTracker（本地落盘）
        ↓
   业务动作：consume("ai") → Allowed / Blocked → 付费墙 → UpgradeSheet → purchase()
```

| 规矩 | 为什么 |
|---|---|
| 档位表写在代码里，不从服务器下发 | 下发的话额度上限能被随便改 |
| 会员资格只认**已验过签**的购买 | 没验签的购买等于送会员 |
| 过期 / 没验签 / 找不到档位 → 按免费档算 | 一个分支就够，不用到处判 |
| 额度用 `consume()` 扣，不自己加 | 扣了才知道超没超，扣超了不动计数 |
| 平台 SDK 不进这个模块 | 公共层不留计费 |

## 主题

token 驱动：`ThemeTokens`（颜色 + 扩展色 + 排版 + 圆角 + 标签色板）5 套预设
（Mono / Swiss / Notion / EInk / macOS），**一套组件**靠 `KitTheme.of(context)` 取当前 tokens。
`KitAppShell` 一步给齐：5 套风格 + 跟随系统深浅 + 中英切换。

## 和旧版（KMP）的对应

| | KMP 版（已备份） | 本仓库 |
|---|---|---|
| UI | Compose Multiplatform | Flutter Widget |
| agent 底座 | Koog（Kotlin 原生） | `dart_agent_core` |
| 多包管理 | Gradle multi-module | **pub workspace** |
| 平台 | Android / iOS / Desktop | Android / iOS / Desktop / **Web** |
| 主题 | 每套风格一组组件 | **token 驱动**（一套组件） |
| 门禁 | detekt / apiCheck / gradle test | analyze / test / contract / verify / base-guard |

`backend/`（TypeScript 网关）与小程序端（JS）两边都直接复用，行为不变。

**哪些组件没迁、为什么** 见 [`FLUTTER_MIGRATION.md`](FLUTTER_MIGRATION.md)。

## 许可

见 [LICENSE](LICENSE)。
