#!/usr/bin/env python3
import argparse
import json
import os
import re
import shlex
import sys


DEFAULT_RUNTIME_PATH = os.path.expanduser("~/.local/state/quickshell/runtime.json")
DEFAULT_UI_SCALE = 1.0
MIN_UI_SCALE = 0.75
MAX_UI_SCALE = 2.5
DEFAULT_HYPR_FILES = [
    os.path.expanduser("~/.config/hypr/programs"),
    os.path.expanduser("~/.config/hypr/programs.conf"),
    os.path.expanduser("~/.config/hypr/hyprland.conf"),
]


def strip_comment(line):
    out = []
    in_single = False
    in_double = False
    for ch in line:
        if ch == "'" and not in_double:
            in_single = not in_single
        elif ch == '"' and not in_single:
            in_double = not in_double
        elif ch == "#" and not in_single and not in_double:
            break
        out.append(ch)
    return "".join(out).strip()


def parse_terminal_from_hypr(files):
    pattern = re.compile(r"^\s*\$terminal\s*=\s*(.+?)\s*$")
    for path in files:
        if not os.path.isfile(path):
            continue
        try:
            with open(path, "r", encoding="utf-8") as f:
                for raw in f:
                    line = strip_comment(raw)
                    if not line:
                        continue
                    m = pattern.match(line)
                    if not m:
                        continue
                    value = m.group(1).strip()
                    try:
                        parts = shlex.split(value)
                    except ValueError:
                        parts = value.split()
                    parts = [p for p in parts if p]
                    if parts:
                        return parts
        except OSError:
            continue
    return []


def read_runtime(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
        if not isinstance(data, dict):
            return {}
        return data
    except Exception:
        return {}


def write_runtime(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False)
    os.replace(tmp, path)


def sync_from_hypr(runtime_path, hypr_files):
    terminal = parse_terminal_from_hypr(hypr_files)
    if not terminal:
        return 1

    data = read_runtime(runtime_path)
    data["terminal"] = terminal
    write_runtime(runtime_path, data)
    return 0


def runtime_terminal(runtime_path):
    data = read_runtime(runtime_path)
    terminal = data.get("terminal")

    if isinstance(terminal, str):
        terminal = terminal.strip()
        if terminal:
            try:
                return shlex.split(terminal)
            except ValueError:
                return terminal.split()
        return []

    if isinstance(terminal, list):
        out = []
        for item in terminal:
            if isinstance(item, str) and item.strip():
                out.append(item.strip())
        return out

    return []


def launch_terminal(runtime_path, command):
    terminal = runtime_terminal(runtime_path)
    if not terminal:
        return 2
    if not command:
        return 2
    os.execvp(terminal[0], terminal + command)
    return 0


def clamp_ui_scale(value):
    return max(MIN_UI_SCALE, min(MAX_UI_SCALE, value))


def parse_ui_scale(raw):
    try:
        return clamp_ui_scale(float(raw))
    except Exception:
        return None


def get_ui_scale(runtime_path):
    data = read_runtime(runtime_path)
    raw = data.get("ui_scale", data.get("launcher_scale", DEFAULT_UI_SCALE))
    value = parse_ui_scale(raw)
    if value is None:
        value = DEFAULT_UI_SCALE
    sys.stdout.write(f"{value:.2f}\n")
    return 0


def set_ui_scale(runtime_path, raw_value):
    value = parse_ui_scale(raw_value)
    if value is None:
        return 2
    data = read_runtime(runtime_path)
    data["ui_scale"] = value
    write_runtime(runtime_path, data)
    return 0


def build_parser():
    p = argparse.ArgumentParser()
    p.add_argument("--runtime-file", default=DEFAULT_RUNTIME_PATH)
    p.add_argument("--hypr-file", action="append", default=[])
    p.add_argument("--sync-hypr-terminal", action="store_true")
    p.add_argument("--get-ui-scale", action="store_true")
    p.add_argument("--set-ui-scale")
    p.add_argument("--get-launcher-scale", action="store_true")
    p.add_argument("--set-launcher-scale")
    p.add_argument("--launch-terminal", action="store_true")
    p.add_argument("remainder", nargs=argparse.REMAINDER)
    return p


def main():
    args = build_parser().parse_args()

    if args.sync_hypr_terminal:
        files = args.hypr_file if args.hypr_file else DEFAULT_HYPR_FILES
        return sync_from_hypr(args.runtime_file, files)

    if args.get_ui_scale:
        return get_ui_scale(args.runtime_file)

    if args.set_ui_scale is not None:
        return set_ui_scale(args.runtime_file, args.set_ui_scale)

    if args.get_launcher_scale:
        return get_ui_scale(args.runtime_file)

    if args.set_launcher_scale is not None:
        return set_ui_scale(args.runtime_file, args.set_launcher_scale)

    if args.launch_terminal:
        remainder = list(args.remainder)
        if remainder and remainder[0] == "--":
            remainder = remainder[1:]
        return launch_terminal(args.runtime_file, remainder)

    return 2


if __name__ == "__main__":
    sys.exit(main())
