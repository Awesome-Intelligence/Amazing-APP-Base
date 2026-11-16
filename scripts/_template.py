#!/usr/bin/env python3
"""模板渲染 —— new_app.py / new_miniprogram.py 共用。

模板目录里所有 `*.tmpl` 文件都会渲染到目标目录（去掉 `.tmpl` 后缀），
文件里的 `__占位符__` 和**文件名里**的占位符都会被替换。

替换完还剩占位符 = 模板写错了，直接失败 —— 别生成一个半成品出来。
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

NAME_RE = re.compile(r"^[a-z][a-z0-9_]*$")
LEFTOVER_RE = re.compile(r"__[A-Z][A-Z0-9_]*__")


def fail(message: str) -> None:
    print(f"✗ {message}", file=sys.stderr)
    raise SystemExit(1)


def escape_xml(value: str) -> str:
    return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def escape_kotlin(value: str) -> str:
    return value.replace("\\", "\\\\").replace('"', '\\"').replace("$", "\\$")


def escape_json(value: str) -> str:
    """JSON / JS 字符串里能用。"""
    return value.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")


def render(
    template_dir: Path,
    target: Path,
    mapping: dict[str, str],
) -> list[Path]:
    """渲染模板目录到 target，返回写出去的文件列表（相对 target）。"""
    written: list[Path] = []
    for template in sorted(template_dir.rglob("*.tmpl")):
        relative = str(template.relative_to(template_dir))[: -len(".tmpl")]
        for key, value in mapping.items():
            relative = relative.replace(key, value)

        output = target / relative
        output.parent.mkdir(parents=True, exist_ok=True)

        text = template.read_text(encoding="utf-8")
        for key, value in mapping.items():
            text = text.replace(key, value)

        leftovers = LEFTOVER_RE.findall(text)
        if leftovers:
            fail(f"{template.name} 里有没替换的占位符：{sorted(set(leftovers))}")

        output.write_text(text, encoding="utf-8")
        written.append(output)
    return written
