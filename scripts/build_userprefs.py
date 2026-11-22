#!/usr/bin/env python3
"""Generate a private build-only C header from the firmware's userPrefs.jsonc."""

import argparse
import json
import re
from pathlib import Path


CHANNEL_FIELD_DEFAULTS = {
    "PSK": "{ 0x01 }",
    "NAME": "",
    "PRECISION": "0",
    "IS_MUTED": "false",
    "UPLINK_ENABLED": "false",
    "DOWNLINK_ENABLED": "false",
}


def strip_jsonc_comments(source: str) -> str:
    """Remove comments without touching comment-like string data."""
    out = []
    i = 0
    in_string = False
    escaped = False
    while i < len(source):
        char = source[i]
        nxt = source[i + 1] if i + 1 < len(source) else ""
        if in_string:
            out.append(char)
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                in_string = False
            i += 1
        elif char == '"':
            in_string = True
            out.append(char)
            i += 1
        elif char == "/" and nxt == "/":
            i += 2
            while i < len(source) and source[i] not in "\r\n":
                i += 1
        elif char == "/" and nxt == "*":
            i += 2
            while i + 1 < len(source) and source[i : i + 2] != "*/":
                if source[i] in "\r\n":
                    out.append(source[i])
                i += 1
            i = min(i + 2, len(source))
        else:
            out.append(char)
            i += 1
    return "".join(out)


def macro_value(value: str) -> str:
    if value.startswith("{"):
        return value
    if value.lstrip("-").replace(".", "").isdigit():
        return value
    if re.fullmatch(r"0[xX][0-9a-fA-F]+", value):
        return value
    if value in ("true", "false") or value.startswith("meshtastic_"):
        return value
    return json.dumps(value, ensure_ascii=True)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    prefs = json.loads(strip_jsonc_comments(args.input.read_text()))
    if not all(isinstance(key, str) and isinstance(value, str) for key, value in prefs.items()):
        raise SystemExit("userPrefs.jsonc must contain string keys and values")

    channels_to_write = prefs.get("USERPREFS_CHANNELS_TO_WRITE", "1")
    channel_count = int(channels_to_write, 16 if channels_to_write.lower().startswith("0x") else 10)
    if channel_count > 8:
        raise SystemExit("userPrefs.jsonc: USERPREFS_CHANNELS_TO_WRITE exceeds the 8-channel table")

    for channel in range(8):
        prefix = f"USERPREFS_CHANNEL_{channel}_"
        if any(key.startswith(prefix) for key in prefs):
            for field, default in CHANNEL_FIELD_DEFAULTS.items():
                prefs.setdefault(prefix + field, default)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    lines = ["// Generated from userPrefs.jsonc; contains private device settings.", "#pragma once"]
    lines.extend(f"#define {key} {macro_value(value)}" for key, value in prefs.items())
    args.output.write_text("\n".join(lines) + "\n")


if __name__ == "__main__":
    main()
