#!/usr/bin/env python3
"""从 scripts/templates/miniprogram 生成一个微信小程序端。

用法：
    python scripts/new_miniprogram.py myapp
    python scripts/new_miniprogram.py myapp --app-name "我的应用"

生成到 **apps/<name>/miniprogram/**（小程序本体）+ **apps/<name>/contract/actions.json**
（各端共享的契约）。

小程序端是**另一个客户端**，不是 Flutter 的新 target —— 小程序没有 Dart VM，
Flutter 引擎也跑不进去。它**不含 agent 底座**：要 AI 就走服务端。详见 rules/MULTI-CLIENT.md。

它不碰底座文件，也不改根 pubspec.yaml（app 的包清单在 apps/<name>/pubspec.yaml）。
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _template import NAME_RE, escape_json, fail, render  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
TEMPLATE_DIR = Path(__file__).resolve().parent / "templates" / "miniprogram"
APPS_DIR = ROOT / "apps"


def main() -> None:
    parser = argparse.ArgumentParser(description="生成一个微信小程序端")
    parser.add_argument("name", help="app 名（apps/ 下的目录名，小写字母/数字/下划线）")
    parser.add_argument("--app-name", help="显示名，默认跟 app 名一样")
    args = parser.parse_args()

    name = args.name
    if not NAME_RE.match(name):
        fail(f"名字不合法：{name}（要 ^[a-z][a-z0-9_]*$）")
    if not TEMPLATE_DIR.is_dir():
        fail(f"模板目录不存在：{TEMPLATE_DIR}")
    if not APPS_DIR.is_dir():
        fail(f"apps/ 目录不存在：{APPS_DIR}（请在仓库根目录执行）")

    target = APPS_DIR / name
    for sub in ("miniprogram", "contract"):
        if (target / sub).exists():
            fail(f"{target.relative_to(ROOT)}/{sub} 已存在，换个名字或先删掉")

    app_name = (args.app_name or name).strip()
    if not app_name:
        fail("--app-name 不能为空")

    mapping = {
        "__APP_NAME__": escape_json(app_name),
        "__APP_DIR__": name,
    }

    written = render(TEMPLATE_DIR, target, mapping)

    print(f"✓ 已生成 apps/{name}/miniprogram/（display_name={app_name}）")
    for path in written:
        print(f"  - {path.relative_to(ROOT)}")
    print()
    print("下一步：")
    print(f'  node --test "apps/{name}/miniprogram/test/*.test.js"   # 契约样例（零依赖）')
    print(f"  bash scripts/ci.sh contract               # 全仓库一起跑")
    print("  改 logic/store.js 里的示例业务 → 同步改 contract/actions.json。")
    print("  微信开发者工具导入 apps/<name>/miniprogram/ 目录（游客模式即可预览）。")
    print("  多端分层的规矩见 rules/MULTI-CLIENT.md。")


if __name__ == "__main__":
    main()
