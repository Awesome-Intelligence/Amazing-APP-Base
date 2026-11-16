# 待办助手 —— 微信小程序端

小程序端是**另一个客户端**，不是 Compose 的新 target（小程序没有 DOM/Skiko，
WASM 也进不去 —— 详见 `rules/MULTI-CLIENT.md`）。它**不含 agent 底座**。

## 目录

```
miniprogram/
  app.js / app.json / app.wxss      小程序壳
  logic/store.js                    业务逻辑（纯逻辑，不认识 wx）
  logic/actions.js                  动作表 = 契约的实现
  logic/storage.js                  存储适配（唯一认识 wx 的文件）
  i18n/                             界面文案
  pages/index/                      界面
  test/contract.test.js             契约样例（不打包进小程序）
contract/actions.json               契约 —— 各端共享的那份 JSON
```

## 跑契约样例

```bash
node --test "apps/<app>/miniprogram/test/*.test.js"     # 零依赖
bash scripts/ci.sh contract                # 全仓库一起跑
```

契约文件不在 `miniprogram/` 里面 —— 它是各端共享的东西，不属于任何一端。

## 要改成自己的业务

1. `logic/store.js` 换成你的逻辑（保持「动作返回一句结果文案」）
2. `logic/actions.js` 里注册动作表，名字跟 `contract/actions.json` 对上
3. 改 `contract/actions.json` 的样例
4. `bash scripts/ci.sh contract` 绿了再走

native 端也有一份实现的话，加一条单测跑同一份契约
（见 `rules/MULTI-CLIENT.md` 第 3.3 节）。

## 预览

微信开发者工具 → 导入项目 → 选这个 `miniprogram/` 目录 → 游客模式即可。
