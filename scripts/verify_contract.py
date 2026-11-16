#!/usr/bin/env python3
"""契约完整性检查 —— 契约文件里的动作，各端动作表都必须实现。

为什么需要它：`contract/actions.json` 是跨端唯一共享的东西，但它是个 JSON，
没人「引用」它 —— 加了动作忘了写实现，或者改了动作名，编译器一声不吭。
各端的契约测试（`apps/demo/test/todo_contract_test.dart`、
`miniprogram/test/contract.test.js`）跑样例时能发现，但它们只在测试阶段跑；
这个脚本更早、更快地指出「谁缺了哪个动作」。

动作表按约定找，不写死文件名：Flutter 端 `lib/**/*actions*.dart`，
小程序端 `miniprogram/logic/**/*actions*.js`（app 换自己的文件名不用改这个脚本）。

用法：python scripts/verify_contract.py
退出码：0 通过，1 有问题。
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CONTRACT_GLOB = "apps/*/contract/actions.json"


def fail(msg: str) -> None:
    print(f"  ✗ {msg}")


def collect_dart_actions(path: Path) -> set[str]:
    """从 Dart 动作表里抠出 map 的 key：`'list_todos': (...) => ...`。"""
    if not path.exists():
        return set()
    text = path.read_text(encoding="utf-8")
    return set(re.findall(r"['\"]([a-z][a-z0-9_]*)['\"]\s*:", text))


def collect_js_actions(path: Path) -> set[str]:
    """从 JS 动作表里抠出对象 key：`list_todos: () => ...`。"""
    if not path.exists():
        return set()
    text = path.read_text(encoding="utf-8")
    return set(re.findall(r"^\s*([a-z][a-z0-9_]*)\s*:", text, re.MULTILINE))


def main() -> int:
    contracts = sorted(ROOT.glob(CONTRACT_GLOB))
    if not contracts:
        print("  · 没有找到 apps/*/contract/actions.json，跳过")
        return 0

    problems = 0
    for contract_path in contracts:
        app_dir = contract_path.parent.parent
        app_name = app_dir.name

        try:
            contract = json.loads(contract_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as e:
            fail(f"{contract_path.relative_to(ROOT)} 不是合法 JSON：{e}")
            problems += 1
            continue

        samples = contract.get("actions") or []
        if not samples:
            fail(f"{contract_path.relative_to(ROOT)} 里没有任何样例")
            problems += 1
            continue

        names = [s.get("action", "") for s in samples]
        dupes = {n for n in names if names.count(n) > 1}
        if dupes:
            fail(f"{app_name} 契约里有重复动作：{sorted(dupes)}")
            problems += 1

        empty_expect = [s.get("action", "?") for s in samples if not (s.get("expect") or "").strip()]
        if empty_expect:
            fail(f"{app_name} 契约里这些样例的 expect 是空的，钉不住任何东西：{empty_expect}")
            problems += 1

        expected = {n for n in names if n}

        # native（Flutter）端：动作表按约定找（lib 下文件名带 actions）
        dart_actions: set[str] = set()
        for dart_path in sorted(app_dir.glob("lib/**/*actions*.dart")):
            dart_actions |= collect_dart_actions(dart_path)
        if not dart_actions:
            fail(f"{app_name} 有契约文件但没有 Dart 动作表（lib/**/*actions*.dart）")
            problems += 1
        else:
            missing = expected - dart_actions
            if missing:
                fail(f"{app_name} 的 Dart 动作表缺少动作：{sorted(missing)}")
                problems += 1

        # 小程序端：同样是约定（miniprogram/logic 下文件名带 actions）
        js_actions: set[str] = set()
        for js_path in sorted(app_dir.glob("miniprogram/logic/**/*actions*.js")):
            js_actions |= collect_js_actions(js_path)
        if not js_actions:
            fail(f"{app_name} 有契约文件但没有小程序端动作表（miniprogram/logic/**/*actions*.js）")
            problems += 1
        else:
            missing = expected - js_actions
            if missing:
                fail(f"{app_name} 的小程序端动作表缺少动作：{sorted(missing)}")
                problems += 1

    if problems == 0:
        print(f"  · 检查了 {len(contracts)} 份契约，动作名与各端一致")
        return 0
    return 1


if __name__ == "__main__":
    sys.exit(main())
