# 多端规则 —— 一个业务跑在几个界面上

> 这份是**底座规则**，不是建议。fork 想加微信小程序端（或者别的端），
> 照着这份搭，行为和文案就不会分叉。
>
> 相关：[KIT-NOTES.md](KIT-NOTES.md)（底座边界）· [CLAUDE.template.md](CLAUDE.template.md)（逻辑 api 化）

## 1. 哪些端，各端能干什么

| 端 | 目录 | UI | 业务逻辑 | agent 底座 |
|---|---|---|---|---|
| Android / iOS / Desktop / Web | `apps/<name>/`（Flutter） | Flutter Widget | Dart | 有（`kit-agent`） |
| 微信小程序 | `apps/<name>/miniprogram/` | WXML/WXSS | JavaScript | **没有** |

小程序端不是「多一个 Flutter target」，是**另一个客户端**。原因很硬：

- 小程序没有浏览器环境，Flutter Web 的 CanvasKit / html 渲染器进不去；
  小程序的 wasm 也跑不了 Flutter 引擎 —— `WXWebAssembly` 没有 `import()`、没有 `fetch`，
  不能 JIT，wasm 内存约 1MB，而且算进 2MB 包体限制。
- 小程序没有 Dart VM，`kit-agent`（dart_agent_core）跑不起来 —— **agent 只能留在服务端**。

所以小程序端：**保留主要逻辑和界面，不要 agent 底座**。
它和 Flutter 端共享的不是代码，是**契约**（见第 3 节）。

## 2. 分层：共享什么，各端自己什么

| 层 | 归谁 | 说明 |
|---|---|---|
| 业务动作 + 结果文案 | **共享** | 写成契约文件 `apps/<name>/contract/actions.json`，各端各实现一遍 |
| 界面 | 各端自己 | Flutter 组件 / WXML 组件，两套，不强行统一 |
| 存储、网络 | 各端自己 | Flutter 端用 kit 的 `EntityStore` / `SettingsStore`；小程序用 `wx.getStorageSync` |
| 文案资源 | 各端自己 | Flutter 走 `KitStrings`（`_ZhStrings` / `_EnStrings`）；小程序走 `miniprogram/i18n/`。Flutter 端的**运行时语言切换**由 `AppSettings.language` + `KitAppShell` 统一管，各端 app 别自己重造一套 locale 机制 |
| agent 底座 | **只有 Flutter 端** | 小程序端不许引入 `kit-agent` |

> 界面装饰文案（按钮上写什么）各端各管；**业务结果文案**（"已添加待办 t1：买牛奶"）
> 属于契约，必须各端一致 —— 这是最容易分叉、也最该被钉死的那部分。

## 3. 契约：一个 JSON，两端各跑一遍

### 3.1 契约文件长这样

`apps/<name>/contract/actions.json`：

```json
{
  "version": 1,
  "actions": [
    { "action": "list_todos", "input": {}, "expect": "（还没有待办）" },
    { "action": "add_todo", "input": { "title": "买牛奶" }, "expect": "已添加待办 t1：买牛奶" },
    { "action": "delete_todo", "input": { "id": "t999" }, "expect": "没找到待办 t999" }
  ]
}
```

- `action` —— 动作名，**各端动作表里的 key，必须一模一样**
- `input` —— 入参（JSON 对象）
- `expect` —— 结果文案里**必须包含**的片段

### 3.2 各端实现一份动作表

Flutter 端（Dart，`kit` 提供了跑样例的函数）：

```dart
// apps/<name>/lib/<name>_actions.dart
Map<String, Future<String> Function(Map<String, Object?> input)> todoActions(
  TodoStore store,
) => {
      'list_todos': (_) => store.summary(),
      'add_todo': (input) => store.add(input['title'] as String),
      'delete_todo': (input) => store.remove(input['id'] as String),
    };
```

小程序端（JavaScript）：

```javascript
// apps/<name>/miniprogram/logic/actions.js
function createActions(storage) {
  const store = createStore(storage)
  return {
    list_todos: () => store.summary(),
    add_todo: (input) => store.add(input.title),
    delete_todo: (input) => store.remove(input.id),
  }
}
```

动作表**每条样例重新建一份** —— 样例之间互不影响，加样例不用重排。

### 3.3 各端跑同一批样例

```dart
// Flutter 端：一条单测就够
final contract = ActionContract.fromJson(await loadContract());
final failures = await runAsyncActionSamples(
  contract,
  () => todoActions(TodoStore(MemoryEntityStore(const JsonCodec()))),
);
expect(failures, isEmpty);
```

```javascript
// 小程序端：node --test，零依赖、零构建
test('契约样例全部通过', () => { /* 逐条跑，assert */ })
```

**谁改了行为或文案，红的就是谁** —— 这就是多端不分叉的全部机制。

### 3.4 跑起来

```bash
bash scripts/ci.sh contract    # 跑所有 apps/*/miniprogram 的契约样例
```

小程序端的样例用 `node --test` 跑，**不需要装任何依赖**（小程序本体也不用构建）。

## 4. 业务逻辑放哪 —— 三个选项

底座**不替这个决定拍板**，但把选择隔离在一个地方：契约文件的边界。
换句话说，**逻辑放哪都不影响契约格式、不影响样例怎么跑**。

| 选项 | 逻辑放哪 | 好处 | 代价 |
|---|---|---|---|
| **A. 服务端** | backend 出 HTTP API，小程序只调接口 | 一份逻辑，天然不分叉；换端不用重写 | 要养服务；离线不可用；小程序要配域名白名单 |
| **B. 各端一份** | 小程序自己写 JS，Flutter 端写 Dart | 离线可用；没有服务成本 | 两份实现，靠契约样例盯着别分叉 |
| **C. 共享一份** | Dart → JS 编译共用同一份逻辑 | 真·一份实现 | 要加 dart2js 构建链；小程序包体吃紧；收益和 B 差不多 |

**怎么选**：要离线 / 不想养服务 → B；要强一致 / 逻辑复杂 → A。
默认按 **B** 起步（契约机制就是为 B 准备的），等逻辑长复杂了再把实现挪到 A ——
契约不变，只换动作表里的实现。

> ponytail: 契约只钉「动作名 + 入参 + 结果文案」。
> 多步交互、动画、错误码、离线同步这些暂时不在契约里，各端自己测。
> 真出现第二个端共享文案的需求，再补一个导出脚本（`kit_strings.dart` → 小程序 i18n）。

## 5. fork 怎么加一个微信小程序端

```bash
python scripts/new_miniprogram.py <你的app>   # 生成 apps/<app>/miniprogram/ + contract/actions.json
```

然后：

1. 把 `miniprogram/logic/store.js` 换成你自己的业务逻辑（纯逻辑，不认识 `wx`）
2. 在 `miniprogram/logic/actions.js` 里注册动作表 —— 名字跟契约文件对上
3. 改 `contract/actions.json` —— 换成你自己的样例
4. `bash scripts/ci.sh contract` —— 绿了再往下走
5. Flutter 端也有一份实现的话，加一条单测跑同一份契约（见 3.3）
6. 微信开发者工具打开 `apps/<app>/miniprogram/` 目录（游客模式即可预览）

生成的骨架里 `miniprogram/test/` 已经在 `project.config.json` 的 `packOptions.ignore` 里，
**不会被打进小程序包**。

## 6. 明确的简化

- 小程序端**没有 agent**：不引入 `kit-agent`，要 AI 就走服务端（A 选项）。
- 小程序端**不复用 Flutter 组件**：几十个组件要手写成 WXML，别想着复用。
- **视觉 token 不自动导出**：`theme.wxss` 自己维护，改品牌色记得两边都改。
- **界面文案各端各管**：只有业务结果文案进契约。
