#!/usr/bin/env python3
import configparser
import ctypes
import errno
import glob
import hashlib
import json
import os
import select
import struct
import sys
import time
import re


def build_app_dirs():
    dirs = [
        os.path.expanduser("~/.local/share/applications"),
        os.path.expanduser("~/.local/share/flatpak/exports/share/applications"),
        "/usr/local/share/applications",
        "/usr/share/applications",
        "/var/lib/flatpak/exports/share/applications",
        "/var/lib/snapd/desktop/applications",
    ]

    xdg_data_dirs = os.environ.get("XDG_DATA_DIRS", "")
    for d in xdg_data_dirs.split(":"):
        d = d.strip()
        if not d:
            continue
        dirs.append(os.path.join(d, "applications"))

    # Deduplicate while preserving order.
    out = []
    seen = set()
    for d in dirs:
        if d not in seen:
            seen.add(d)
            out.append(d)
    return out


def build_icon_dirs():
    dirs = [
        os.path.expanduser("~/.local/share/icons"),
        os.path.expanduser("~/.icons"),
        os.path.expanduser("~/.local/share/flatpak/exports/share/icons"),
        "/usr/local/share/icons",
        "/usr/share/icons",
        "/var/lib/flatpak/exports/share/icons",
    ]

    xdg_data_dirs = os.environ.get("XDG_DATA_DIRS", "")
    for d in xdg_data_dirs.split(":"):
        d = d.strip()
        if not d:
            continue
        dirs.append(os.path.join(d, "icons"))

    out = []
    seen = set()
    for d in dirs:
        if d not in seen:
            seen.add(d)
            out.append(d)
    return out


APP_DIRS = build_app_dirs()
ICON_DIRS = build_icon_dirs()

PIXMAP_DIRS = [
    "/usr/share/pixmaps",
    os.path.expanduser("~/.local/share/pixmaps"),
]

CACHE_PATH = os.path.expanduser("~/.cache/quickshell/apps-cache.json")
CACHE_VERSION = 5
USAGE_PATH = os.path.expanduser("~/.local/state/quickshell/launcher-usage.json")
FALLBACK_POLL_SECONDS = 2.0
EVENT_DEBOUNCE_SECONDS = 0.25

ICON_INDEX = None

IN_ACCESS = 0x00000001
IN_MODIFY = 0x00000002
IN_ATTRIB = 0x00000004
IN_CLOSE_WRITE = 0x00000008
IN_MOVED_FROM = 0x00000040
IN_MOVED_TO = 0x00000080
IN_CREATE = 0x00000100
IN_DELETE = 0x00000200
IN_DELETE_SELF = 0x00000400
IN_MOVE_SELF = 0x00000800
IN_IGNORED = 0x00008000

WATCH_MASK = (
    IN_MODIFY
    | IN_ATTRIB
    | IN_CLOSE_WRITE
    | IN_MOVED_FROM
    | IN_MOVED_TO
    | IN_CREATE
    | IN_DELETE
    | IN_DELETE_SELF
    | IN_MOVE_SELF
)

LIBC = ctypes.CDLL("libc.so.6", use_errno=True)
LIBC.inotify_init1.argtypes = [ctypes.c_int]
LIBC.inotify_init1.restype = ctypes.c_int
LIBC.inotify_add_watch.argtypes = [ctypes.c_int, ctypes.c_char_p, ctypes.c_uint32]
LIBC.inotify_add_watch.restype = ctypes.c_int


SIZE_RE = re.compile(r"/(\d+)x(\d+)/")


def icon_size_hint(path):
    m = SIZE_RE.search(path)
    if not m:
        return 0
    w = int(m.group(1))
    h = int(m.group(2))
    return min(w, h)


def icon_rank(path):
    lower = path.lower()
    ext = os.path.splitext(lower)[1]
    symbolic = "symbolic" in lower
    size = icon_size_hint(path)

    # Prefer non-symbolic icons, then larger raster sizes.
    # Keep PNG ahead of SVG/XPM to avoid renderer issues with some SVG assets.
    ext_prio = {".png": 0, ".svg": 1, ".xpm": 2}.get(ext, 3)
    return (1 if symbolic else 0, ext_prio, -size, len(path))


def add_icon(index, key, path):
    if not key:
        return
    cur = index.get(key)
    if cur is None or icon_rank(path) < icon_rank(cur):
        index[key] = path


def build_icon_index():
    index = {}

    for root in ICON_DIRS:
        if not os.path.isdir(root):
            continue
        for base, _, files in os.walk(root):
            for name in files:
                stem, ext = os.path.splitext(name)
                if ext.lower() not in (".png", ".svg", ".xpm"):
                    continue
                path = os.path.join(base, name)
                add_icon(index, name, path)
                add_icon(index, stem, path)
                if stem.endswith("-symbolic"):
                    add_icon(index, stem[:-9], path)

    for root in PIXMAP_DIRS:
        if not os.path.isdir(root):
            continue
        for path in glob.glob(os.path.join(root, "*.*")):
            if not os.path.isfile(path):
                continue
            name = os.path.basename(path)
            stem, ext = os.path.splitext(name)
            if ext.lower() not in (".png", ".svg", ".xpm"):
                continue
            add_icon(index, name, path)
            add_icon(index, stem, path)

    return index


def resolve_icon(icon_name):
    global ICON_INDEX

    icon_name = (icon_name or "").strip()
    if not icon_name:
        return ""

    if os.path.isabs(icon_name) and os.path.exists(icon_name):
        return icon_name

    if ICON_INDEX is None:
        ICON_INDEX = build_icon_index()

    base = os.path.basename(icon_name)
    stem, _ = os.path.splitext(base)

    for key in (icon_name, base, stem):
        if key in ICON_INDEX:
            return ICON_INDEX[key]

    return icon_name


def compute_sources_signature():
    hasher = hashlib.sha256()

    for d in APP_DIRS:
        hasher.update(d.encode("utf-8"))
        if not os.path.isdir(d):
            hasher.update(b"missing")
            continue

        try:
            d_stat = os.stat(d)
            hasher.update(str(d_stat.st_mtime_ns).encode("utf-8"))
        except OSError:
            hasher.update(b"err")

        for path in sorted(glob.glob(os.path.join(d, "*.desktop"))):
            try:
                stat = os.stat(path)
                hasher.update(path.encode("utf-8"))
                hasher.update(str(stat.st_size).encode("utf-8"))
                hasher.update(str(stat.st_mtime_ns).encode("utf-8"))
            except OSError:
                continue

    return hasher.hexdigest()


def build_apps():
    apps = []
    seen = set()
    usage = load_usage()

    for d in APP_DIRS:
        if not os.path.isdir(d):
            continue
        for path in sorted(glob.glob(os.path.join(d, "*.desktop"))):
            try:
                cp = configparser.ConfigParser(strict=False, interpolation=None)
                cp.read(path, encoding="utf-8")
                if "Desktop Entry" not in cp:
                    continue
                entry = cp["Desktop Entry"]
                if entry.get("Type") != "Application":
                    continue
                if entry.get("NoDisplay", "false").strip().lower() == "true":
                    continue

                name = entry.get("Name", "").strip()
                desktop_id = os.path.splitext(os.path.basename(path))[0]
                if not name or not desktop_id or name in seen:
                    continue

                usage_item = usage.get(desktop_id, {})
                if isinstance(usage_item, dict):
                    launch_count = int(usage_item.get("count", 0))
                    launch_last = int(usage_item.get("last", 0))
                else:
                    # Backward compatibility for older usage formats.
                    launch_count = int(usage_item or 0)
                    launch_last = 0

                seen.add(name)
                apps.append(
                    {
                        "id": desktop_id,
                        "name": name,
                        "icon_name": entry.get("Icon", ""),
                        "icon": resolve_icon(entry.get("Icon", "")),
                        "exec": entry.get("Exec", ""),
                        "description": entry.get("Comment", ""),
                        "launch_count": launch_count,
                        "launch_last": launch_last,
                    }
                )
            except Exception:
                continue

    apps.sort(key=lambda x: x["name"].lower())
    return apps


def load_cache():
    try:
        with open(CACHE_PATH, "r", encoding="utf-8") as f:
            data = json.load(f)
        if data.get("version") != CACHE_VERSION:
            return None
        if not isinstance(data.get("apps"), list):
            return None
        return data
    except Exception:
        return None


def save_cache(sig, apps):
    try:
        os.makedirs(os.path.dirname(CACHE_PATH), exist_ok=True)
        tmp = CACHE_PATH + ".tmp"
        payload = {
            "version": CACHE_VERSION,
            "signature": sig,
            "updated_at": int(time.time()),
            "apps": apps,
        }
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(payload, f, ensure_ascii=False)
        os.replace(tmp, CACHE_PATH)
    except Exception:
        pass


def emit_apps(apps):
    print(json.dumps(apps, ensure_ascii=False), flush=True)


def load_usage():
    try:
        with open(USAGE_PATH, "r", encoding="utf-8") as f:
            data = json.load(f)
        if not isinstance(data, dict):
            return {}
        return data
    except Exception:
        return {}


def save_usage(usage):
    try:
        os.makedirs(os.path.dirname(USAGE_PATH), exist_ok=True)
        tmp = USAGE_PATH + ".tmp"
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(usage, f, ensure_ascii=False)
        os.replace(tmp, USAGE_PATH)
    except Exception:
        pass


def record_launch(app_id):
    app_id = (app_id or "").strip()
    if not app_id:
        return

    usage = load_usage()
    item = usage.get(app_id, {})
    if isinstance(item, dict):
        count = int(item.get("count", 0)) + 1
    else:
        count = int(item or 0) + 1
    usage[app_id] = {"count": count, "last": int(time.time())}

    # Avoid unbounded growth if stale IDs accumulate.
    if len(usage) > 4000:
        trimmed = sorted(
            usage.items(),
            key=lambda kv: (
                int(kv[1].get("last", 0)) if isinstance(kv[1], dict) else 0,
                int(kv[1].get("count", 0)) if isinstance(kv[1], dict) else int(kv[1] or 0),
            ),
            reverse=True,
        )[:2500]
        usage = dict(trimmed)

    save_usage(usage)


def refresh_and_emit():
    global ICON_INDEX
    ICON_INDEX = None
    sig = compute_sources_signature()
    apps = build_apps()
    save_cache(sig, apps)
    emit_apps(apps)
    return sig


def run_once():
    cache = load_cache()
    sig = compute_sources_signature()

    if cache and cache.get("signature") == sig:
        emit_apps(cache["apps"])
        return

    refresh_and_emit()


def run_watch():
    try:
        run_watch_inotify()
    except Exception:
        run_watch_polling()


def run_watch_polling():
    last_sig = None

    cache = load_cache()
    if cache:
        emit_apps(cache["apps"])
        last_sig = cache.get("signature")

    current_sig = compute_sources_signature()
    if current_sig != last_sig:
        last_sig = refresh_and_emit()

    while True:
        time.sleep(FALLBACK_POLL_SECONDS)
        current_sig = compute_sources_signature()
        if current_sig == last_sig:
            continue
        last_sig = refresh_and_emit()


def open_inotify():
    fd = LIBC.inotify_init1(os.O_NONBLOCK)
    if fd < 0:
        err = ctypes.get_errno()
        raise OSError(err, os.strerror(err))
    return fd


def add_watch(fd, path):
    wd = LIBC.inotify_add_watch(fd, path.encode("utf-8"), WATCH_MASK)
    if wd < 0:
        err = ctypes.get_errno()
        if err in (errno.ENOENT, errno.ENOTDIR, errno.EACCES):
            return -1
        raise OSError(err, os.strerror(err))
    return wd


def drain_inotify(fd):
    while True:
        try:
            buf = os.read(fd, 65536)
            if not buf:
                break
            offset = 0
            while offset + 16 <= len(buf):
                _, _, _, name_len = struct.unpack_from("iIII", buf, offset)
                offset += 16 + name_len
        except BlockingIOError:
            break
        except OSError as exc:
            if exc.errno in (errno.EAGAIN, errno.EWOULDBLOCK):
                break
            raise


def run_watch_inotify():
    last_sig = None
    cache = load_cache()
    if cache:
        emit_apps(cache["apps"])
        last_sig = cache.get("signature")

    current_sig = compute_sources_signature()
    if current_sig != last_sig:
        last_sig = refresh_and_emit()

    fd = open_inotify()
    try:
        watched = 0
        for d in APP_DIRS:
            if add_watch(fd, d) >= 0:
                watched += 1

        if watched == 0:
            raise RuntimeError("No app dirs could be watched with inotify")

        while True:
            select.select([fd], [], [])
            drain_inotify(fd)

            deadline = time.monotonic() + EVENT_DEBOUNCE_SECONDS
            while True:
                remaining = deadline - time.monotonic()
                if remaining <= 0:
                    break
                ready, _, _ = select.select([fd], [], [], remaining)
                if not ready:
                    break
                drain_inotify(fd)

            current_sig = compute_sources_signature()
            if current_sig != last_sig:
                last_sig = refresh_and_emit()

            # Re-arm watches if directories were recreated.
            for d in APP_DIRS:
                add_watch(fd, d)
    finally:
        os.close(fd)


if __name__ == "__main__":
    if "--record-launch" in sys.argv[1:]:
        idx = sys.argv.index("--record-launch")
        app_id = sys.argv[idx + 1] if idx + 1 < len(sys.argv) else ""
        record_launch(app_id)
    elif "--watch" in sys.argv[1:]:
        run_watch()
    else:
        run_once()
