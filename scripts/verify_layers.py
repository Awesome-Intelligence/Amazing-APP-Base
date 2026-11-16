#!/usr/bin/env python3
"""分层检查 —— 底座（`kit/`、`kit-agent/`、`kit-membership/`）不许反过来依赖 app（`apps/`）。

（`chat-demo/` 不在底座名单里 —— 它是个示例程序，不是底座。）

为什么需要它：`kit/`、`kit-agent/`、`kit-membership/` 是各 app 共用的底座，一旦它 import 了某个 app 的代码，
这个包就只对那一个 app 成立，其它 app fork 出去会编不过 —— 而且报错点离肇事处很远。
Dart 的包依赖是单向声明，这条规矩没有编译器保障，只能靠脚本盯。

用法：python scripts/verify_layers.py
退出码：0 通过，1 有反向依赖。
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BASE_DIRS = [ROOT / "kit", ROOT / "kit-agent", ROOT / "kit-membership"]
APPS = ROOT / "apps"


def app_package_names() -> set[str]:
    """apps/ 下每个 pubspec 的 name。"""
    names: set[str] = set()
    for pubspec in APPS.glob("*/pubspec.yaml"):
        m = re.search(r"^name:\s*([A-Za-z0-9_]+)", pubspec.read_text(encoding="utf-8"), re.MULTILINE)
        if m:
            names.add(m.group(1))
    return names


def main() -> int:
    base = [d for d in BASE_DIRS if d.is_dir()]
    if not base:
        print("  · 没有底座目录，跳过")
        return 0

    app_names = app_package_names()
    problems = 0

    for pkg in base:

        # 1) pubspec 里的 path 依赖不许指向 apps/
        pubspec = pkg / "pubspec.yaml"
        if pubspec.exists():
            text = pubspec.read_text(encoding="utf-8")
            for m in re.finditer(r"path:\s*(\S+)", text):
                target = m.group(1).strip("'\"")
                if "apps/" in target.replace("\\", "/"):
                    print(f"  ✗ {pkg.name}/pubspec.yaml 依赖了 app：{target}")
                    problems += 1

        # 2) lib 里的 import / export 不许指向 app 包
        for dart in (pkg / "lib").rglob("*.dart"):
            text = dart.read_text(encoding="utf-8")
            for m in re.finditer(r"(?:import|export)\s+'package:([a-z0-9_]+)/", text):
                imported = m.group(1)
                if imported in app_names:
                    rel = dart.relative_to(ROOT)
                    print(f"  ✗ {rel} 反向依赖了 app 包 {imported}")
                    problems += 1

    if problems == 0:
        print("  · 底座没有反向依赖 app")
        return 0
    return 1


if __name__ == "__main__":
    sys.exit(main())
