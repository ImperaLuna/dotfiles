#!/usr/bin/env bash
set -euo pipefail

SYSTEMD_USER_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
DBUS_SERVICE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/dbus-1/services"

mkdir -p "$SYSTEMD_USER_DIR" "$DBUS_SERVICE_DIR"

cat > "$SYSTEMD_USER_DIR/qs-notifications.service" << 'EOF'
[Unit]
Description=Quickshell Notifications Service (org.freedesktop.Notifications)
Documentation=https://quickshell.org/
PartOf=graphical-session.target
After=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/qs
Restart=on-failure
RestartSec=1s
EOF

cat > "$DBUS_SERVICE_DIR/org.freedesktop.Notifications.service" << 'EOF'
[D-BUS Service]
Name=org.freedesktop.Notifications
SystemdService=qs-notifications.service
Exec=/usr/bin/qs
EOF

systemctl --user daemon-reload
systemctl --user unmask dunst.service swaync.service mako.service >/dev/null 2>&1 || true
systemctl --user disable --now dunst.service swaync.service mako.service >/dev/null 2>&1 || true

# Keep this service installed for DBus activation fallback only.
# Do not enable it globally; most setups already start quickshell elsewhere.
systemctl --user disable --now qs-notifications.service >/dev/null 2>&1 || true

if busctl --user list | rg -q '^org\.freedesktop\.Notifications\b'; then
    OWNER_LINE="$(busctl --user list | rg '^org\.freedesktop\.Notifications\b' | head -n1)"
    printf 'OK: %s\n' "$OWNER_LINE"
else
    printf 'ERROR: org.freedesktop.Notifications is not owned after setup.\n' >&2
    exit 1
fi
