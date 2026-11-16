#!/usr/bin/env python3
"""网关协议检查 —— backend 发的 SSE 事件和 kit-agent 认的事件必须对得上。

为什么需要它：协议写在两个语言里（`backend/src/agent.ts` 的 `GatewayEvent`、
`kit-agent/.../gateway_agent_runtime.dart` 的 `mapGatewayEvent`），编译器管不到
对方。历史上就错过一次：后端发 `tool` / `result{output}`，Dart 认的是
`tool_use` / `tool_done` / `result{text}` —— 事件直接被丢掉，聊天界面全程没反应。

这个脚本从两边源码里把「事件名 + 字段」抠出来对：
1. 事件名集合必须完全一样（少一个 = 客户端静默丢事件，多一个 = 客户端不认）；
2. Dart 读的每个字段，后端必须真的发（后端多发字段没关系 —— 客户端可以不看）。

用法：python scripts/verify_gateway.py
退出码：0 通过，1 对不上。
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BACKEND = ROOT / "backend" / "src" / "agent.ts"
DART = ROOT / "kit-agent" / "lib" / "src" / "engine" / "gateway_agent_runtime.dart"

# TS 联合类型的一个成员：{ type: "text"; text: string }
TS_MEMBER = re.compile(r'\{\s*type:\s*"([a-z_]+)"\s*;\s*([^}]*)\}')
# Dart switch 的一个分支：case 'text': ...
DART_CASE = re.compile(r"case '([a-z_]+)':(.*?)(?=case '|default:)", re.S)


def fail(msg: str) -> None:
    print(f"  ✗ {msg}")


def backend_events() -> dict[str, set[str]]:
    """后端事件名 → 它发的字段。"""
    text = BACKEND.read_text(encoding="utf-8")
    out: dict[str, set[str]] = {}
    for name, rest in TS_MEMBER.findall(text):
        fields = set(re.findall(r"(\w+)\s*:", rest))
        fields.discard("type")
        out[name] = fields
    return out


def dart_events() -> dict[str, set[str]]:
    """Dart 事件名 → 它读的字段。"""
    text = DART.read_text(encoding="utf-8")
    out: dict[str, set[str]] = {}
    for name, block in DART_CASE.findall(text):
        out[name] = set(re.findall(r"data\['([a-z_]+)'\]", block))
    return out


def main() -> int:
    if not BACKEND.exists() or not DART.exists():
        print("  · 没有 backend/ 或 kit-agent/，跳过")
        return 0

    be = backend_events()
    da = dart_events()
    if not be or not da:
        fail("没能从源码里抠出事件定义（backend 或 Dart 那边结构变了？）")
        return 1

    problems = 0

    missing_in_dart = sorted(set(be) - set(da))
    missing_in_backend = sorted(set(da) - set(be))
    if missing_in_dart:
        fail(f"Dart 不认这些后端事件（会被静默丢掉）：{missing_in_dart}")
        problems += 1
    if missing_in_backend:
        fail(f"后端不发这些 Dart 认的事件（永远收不到）：{missing_in_backend}")
        problems += 1

    for name in sorted(set(be) & set(da)):
        unknown = sorted(da[name] - be[name])
        if unknown:
            fail(f"{name}：Dart 读的字段后端不发：{unknown}")
            problems += 1

    if problems == 0:
        print(f"  · 网关协议两边对得上（{len(be)} 个事件）")
        return 0
    return 1


if __name__ == "__main__":
    sys.exit(main())
