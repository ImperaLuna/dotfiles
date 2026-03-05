pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.Notifications
import QtQuick

QtObject {
    id: root

    property int defaultExpireTimeout: 5000
    property int historyLimit: 200
    readonly property alias model: store
    readonly property int count: store.count
    property int popupCount: 0
    property int hoverCount: 0
    property var states: []
    signal popupAdded()

    function formatAge(timestamp) {
        const diff = Date.now() - timestamp;
        const minutes = Math.floor(diff / 60000);

        if (minutes < 1)
            return "now";

        const hours = Math.floor(minutes / 60);
        const days = Math.floor(hours / 24);
        if (days > 0)
            return days + "d";
        if (hours > 0)
            return hours + "h";
        return minutes + "m";
    }

    function normalizeLine(text) {
        const normalized = String(text ?? "").replace(/\s+/g, " ").trim();
        return normalized;
    }

    function formatDisplayFields(appName, summary, body) {
        const sourceLine = normalizeLine(appName);
        let titleLine = normalizeLine(summary);
        let previewLine = normalizeLine(body);

        if (sourceLine.length > 0 && titleLine.length > 0) {
            const lowerSource = sourceLine.toLowerCase();
            const lowerTitle = titleLine.toLowerCase();
            if (lowerTitle.startsWith(lowerSource + " - "))
                titleLine = titleLine.slice(sourceLine.length + 3).trim();
            else if (lowerTitle.startsWith(lowerSource + ":"))
                titleLine = titleLine.slice(sourceLine.length + 1).trim();
        }

        const sourceIsDiscord = sourceLine.toLowerCase().indexOf("discord") !== -1;
        if (sourceIsDiscord && titleLine.length === 0 && previewLine.indexOf(":") > 0) {
            const splitAt = previewLine.indexOf(":");
            const guessedHeader = previewLine.slice(0, splitAt).trim();
            if (guessedHeader.length > 0 && guessedHeader.length < 80) {
                titleLine = guessedHeader;
                previewLine = previewLine.slice(splitAt + 1).trim();
            }
        }

        if (titleLine.length === 0) {
            if (previewLine.length > 0) {
                titleLine = previewLine;
                previewLine = "";
            } else {
                titleLine = sourceLine.length > 0 ? sourceLine : "Notification";
            }
        }

        return {
            sourceLine: sourceLine.length > 0 ? sourceLine : "Notification",
            titleLine: titleLine,
            previewLine: previewLine
        };
    }

    function resolveIconSource(raw) {
        if (!raw || raw.length === 0)
            return "";
        if (raw.startsWith("/") || raw.startsWith("file:") || raw.startsWith("qrc:")
                || raw.startsWith("http:") || raw.startsWith("https:"))
            return raw;
        // Avoid noisy theme-icon lookup warnings for missing names.
        // If appIcon is only a theme icon name, let the UI use placeholder.
        return "";
    }

    function tryInvokePrimaryNotificationAction(state) {
        const notification = state?.notification;
        if (!notification || !notification.actions || notification.actions.length === 0)
            return false;

        let chosen = null;
        for (const action of notification.actions) {
            if (action.identifier === "default") {
                chosen = action;
                break;
            }
        }
        if (!chosen)
            chosen = notification.actions[0];
        if (!chosen)
            return false;

        try {
            chosen.invoke();
            return true;
        } catch (_err) {
            return false;
        }
    }

    function launchFromState(state) {
        if (!state)
            return false;

        const desktopEntry = String(state.desktopEntry || "").trim();
        const appName = String(state.appName || "").trim();
        if (desktopEntry.length === 0 && appName.length === 0)
            return false;

        const focusOrLaunchPy = `
import json
import os
import re
import subprocess
import sys
from pathlib import Path

desktop = (sys.argv[1] if len(sys.argv) > 1 else "").strip()
app_name = (sys.argv[2] if len(sys.argv) > 2 else "").strip()

def norm(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", "", (value or "").lower())

desktop_stem = re.sub(r"\\.desktop$", "", desktop.lower())
tokens = {norm(desktop_stem), norm(app_name)}
tokens.discard("")

# if "discord" in tokens:
#     tokens.update([norm("discord"), norm("discordcanary"), norm("vesktop")])
# if "whatsapp" in tokens or "zapzap" in tokens:
#     tokens.update([norm("whatsapp"), norm("zapzap")])

try:
    clients = json.loads(subprocess.check_output(["hyprctl", "clients", "-j"], text=True))
except Exception:
    clients = []

best = None
best_score = 0
for client in clients:
    address = client.get("address", "")
    if not address:
        continue

    cls = norm(client.get("class", ""))
    icls = norm(client.get("initialClass", ""))
    title = norm(client.get("title", ""))
    score = 0

    for token in tokens:
        if cls == token:
            score = max(score, 220)
        if icls == token:
            score = max(score, 210)
        if token in cls:
            score = max(score, 160)
        if token in icls:
            score = max(score, 150)
        if token in title:
            score = max(score, 80)

    if score > best_score:
        best_score = score
        best = client

if best and best_score >= 150:
    ws = best.get("workspace") or {}
    wsid = ws.get("id", 0)
    try:
        wsid = int(wsid)
    except Exception:
        wsid = 0
    if wsid > 0:
        subprocess.run(["hyprctl", "dispatch", "workspace", str(wsid)], check=False)
    subprocess.run(["hyprctl", "dispatch", "focuswindow", f"address:{best['address']}"], check=False)
    sys.exit(0)

if desktop:
    subprocess.run(["gtk-launch", desktop], check=False)
    sys.exit(0)

def infer_desktop_entry() -> str:
    # Resolve an app desktop entry from installed .desktop files when
    # notifications do not provide desktopEntry.
    token_list = [t for t in tokens if t]
    if not token_list:
        return ""

    app_dirs = []
    data_home = Path.home() / ".local" / "share" / "applications"
    app_dirs.append(data_home)
    xdg_data_dirs = os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share").split(":")
    for base in xdg_data_dirs:
        if base:
            app_dirs.append(Path(base) / "applications")

    best_stem = ""
    best_score = 0

    for directory in app_dirs:
        if not directory.is_dir():
            continue
        try:
            entries = directory.glob("*.desktop")
        except Exception:
            continue

        for entry in entries:
            stem = entry.stem.lower()
            score = 0
            for token in token_list:
                if stem == token:
                    score = max(score, 220)
                elif stem.startswith(token):
                    score = max(score, 180)
                elif token in stem:
                    score = max(score, 140)

            if score > best_score:
                best_score = score
                best_stem = entry.stem

    return best_stem if best_score >= 140 else ""

desktop_inferred = infer_desktop_entry()
if desktop_inferred:
    subprocess.run(["gtk-launch", desktop_inferred], check=False)
    sys.exit(0)

sys.exit(1)
`;

        Quickshell.execDetached(["python3", "-c", focusOrLaunchPy, desktopEntry, appName]);
        return true;
    }

    function updateState(state) {
        if (state.modelIndex < 0 || state.modelIndex >= store.count)
            return;

        store.set(state.modelIndex, state.toRecord());
        recalcPopupCount();
    }

    function insertState(state) {
        state.modelIndex = states.length;
        states.push(state);
        store.append(state.toRecord());

        if (store.count > historyLimit)
            removeAt(0, false);

        recalcPopupCount();
        if (state.popup)
            popupAdded();
    }

    function removeState(state, dismissServer) {
        if (!state)
            return;

        let idx = state.modelIndex;
        if (idx < 0 || idx >= states.length || states[idx] !== state)
            idx = states.indexOf(state);
        if (idx < 0)
            return;

        removeAt(idx, dismissServer);
    }

    function removeAt(index, dismissServer) {
        if (index < 0 || index >= store.count)
            return;

        const state = states[index];
        if (!state || state.modelIndex !== index)
            return;

        let notificationToDismiss = null;
        if (dismissServer && !state.closing && state.notification) {
            state.closing = true;
            notificationToDismiss = state.notification;
        }

        store.remove(index, 1);
        states.splice(index, 1);
        state.modelIndex = -1;
        state.destroy();

        for (let i = index; i < states.length; i++)
            states[i].modelIndex = i;

        recalcPopupCount();

        if (notificationToDismiss) {
            try {
                notificationToDismiss.dismiss();
            } catch (_err) {
            }
        }
    }

    function dismissByIndex(index) {
        removeAt(index, true);
    }

    function setExpanded(index, value) {
        if (index < 0 || index >= states.length)
            return;

        const state = states[index];
        if (!state)
            return;

        state.expanded = value;
        store.setProperty(index, "expanded", value);
    }

    function invokePrimaryAction(index) {
        if (index < 0 || index >= states.length)
            return;

        const state = states[index];
        // Prefer the sender-provided default action (open conversation, focus chat, etc.)
        // before our local fallback focus/launch heuristic.
        if (tryInvokePrimaryNotificationAction(state))
            return;

        const desktopEntry = String(state?.desktopEntry || "").trim();
        const appName = String(state?.appName || "").trim();
        if (desktopEntry.length > 0 || appName.length > 0)
            launchFromState(state);
    }

    function setHovered(index, hovered) {
        if (index < 0 || index >= states.length)
            return;

        const state = states[index];
        if (!state)
            return;

        if (state.hovered === hovered)
            return;

        state.hovered = hovered;
        hoverCount += hovered ? 1 : -1;
        if (hoverCount < 0)
            hoverCount = 0;

        if (hoverCount > 0) {
            for (const item of states)
                item.popupTimer.stop();
        } else {
            for (const item of states)
                item.restartPopupTimer();
        }
    }

    function recalcPopupCount() {
        let n = 0;
        for (let i = 0; i < store.count; i++) {
            if (store.get(i).popup)
                n += 1;
        }
        popupCount = n;
    }

    function handleNotification(notification) {
        const state = notifStateComp.createObject(root, {
            notification: notification
        });
        insertState(state);
    }

    readonly property Timer ageRefreshTimer: Timer {
        interval: 30000
        repeat: true
        running: true
        onTriggered: {
            for (const state of root.states) {
                state.updateAgeText();
                root.updateState(state);
            }
        }
    }

    readonly property NotificationServer server: NotificationServer {
        id: server

        // Keep DBus ownership stable during quickshell config reloads.
        // Some apps (e.g. ZapZap) crash if org.freedesktop.Notifications disappears briefly.
        keepOnReload: true
        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notification => {
            notification.tracked = true;
            root.handleNotification(notification);
        }
    }

    readonly property ListModel store: ListModel {
        id: store
    }

    component NotifState: QtObject {
        id: state

        property var notification
        property int modelIndex: -1
        property bool closing: false
        property string notifId: ""
        property string appName: ""
        property string desktopEntry: ""
        property string ageText: "now"
        property string summary: ""
        property string body: ""
        property string sourceLine: ""
        property string titleLine: ""
        property string previewLine: ""
        property string iconSource: ""
        property string imageSource: ""
        property bool canLaunch: false
        property bool hasPrimaryAction: false
        property bool expanded: false
        property bool popup: true
        property bool hovered: false
        property double timestamp: Date.now()
        property int expireTimeout: root.defaultExpireTimeout

        function notificationText() {
            if (body && body.trim().length > 0)
                return body;
            return summary;
        }

        function toRecord() {
            return {
                appName: appName,
                ageText: ageText,
                sourceLine: sourceLine,
                titleLine: titleLine,
                previewLine: previewLine,
                summary: summary,
                body: body,
                iconSource: iconSource,
                imageSource: imageSource,
                hasPrimaryAction: hasPrimaryAction,
                expanded: expanded,
                popup: popup,
                timestamp: timestamp
            };
        }

        function updateAgeText() {
            ageText = root.formatAge(timestamp);
        }

        function restartPopupTimer() {
            if (root.hoverCount > 0 || hovered || !popup) {
                popupTimer.stop();
                return;
            }

            if (expireTimeout <= 0)
                popupTimer.stop();
            else {
                popupTimer.interval = expireTimeout;
                popupTimer.restart();
            }
        }

        function refreshFromNotification() {
            if (!notification)
                return;

            notifId = String(notification.id);
            appName = notification.appName || "";
            desktopEntry = notification.desktopEntry || "";
            summary = notification.summary || "";
            body = notification.body || "";
            const display = root.formatDisplayFields(appName, summary, body);
            sourceLine = display.sourceLine;
            titleLine = display.titleLine;
            previewLine = display.previewLine;
            iconSource = root.resolveIconSource(notification.appIcon || "");
            imageSource = notification.image || "";
            canLaunch = desktopEntry.length > 0;
            hasPrimaryAction = canLaunch || (notification.actions && notification.actions.length > 0);
            expireTimeout = notification.expireTimeout > 0 ? notification.expireTimeout : root.defaultExpireTimeout;
            timestamp = Date.now();
            updateAgeText();
            restartPopupTimer();
        }

        function closeFromServer() {
            // Keep history/popups when apps replace notifications with the same ID.
            // We only remove immediately when we explicitly dismiss from our UI path.
            if (closing) {
                root.removeState(state, false);
                return;
            }

            notification = null;
            restartPopupTimer();
        }

        readonly property Connections conn: Connections {
            target: state.notification
            function onClosed() {
                state.closeFromServer();
            }
            function onSummaryChanged() {
                state.refreshFromNotification();
                root.updateState(state);
            }
            function onBodyChanged() {
                state.refreshFromNotification();
                root.updateState(state);
            }
            function onAppIconChanged() {
                state.refreshFromNotification();
                root.updateState(state);
            }
            function onAppNameChanged() {
                state.refreshFromNotification();
                root.updateState(state);
            }
            function onImageChanged() {
                state.refreshFromNotification();
                root.updateState(state);
            }
            function onExpireTimeoutChanged() {
                state.refreshFromNotification();
                root.updateState(state);
            }
            function onDesktopEntryChanged() {
                state.refreshFromNotification();
                root.updateState(state);
            }
            function onActionsChanged() {
                state.refreshFromNotification();
                root.updateState(state);
            }
        }

        readonly property Timer popupTimer: Timer {
            id: popupTimer
            interval: state.expireTimeout
            running: false
            onTriggered: {
                state.popup = false;
                root.updateState(state);
            }
        }

        Component.onCompleted: {
            refreshFromNotification();
        }
    }

    readonly property Component notifStateComp: Component {
        id: notifStateComp
        NotifState {}
    }
}
