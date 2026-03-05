pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import "LauncherLogic.js" as Logic
import "../metrics"

// qmllint disable uncreatable-type
PanelWindow {
    id: root

    visible: false
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    property real uiScale: 1.0
    // Fine-tune launcher size without changing base token values.
    property real scaleBoost: 2.0
    implicitWidth: Math.round(Metrics.launcherWidthBase * uiScale)
    implicitHeight: view.maxHeight

    property var allApps: []
    property var results: []
    property var pendingAppsUpdate: null

    readonly property string scriptPath: Qt.resolvedUrl("list-apps.py").toString().replace(/^file:\/\//, "")
    readonly property string runtimeScriptPath: Qt.resolvedUrl("runtime-config.py").toString().replace(/^file:\/\//, "")

    Process {
        id: appLoader
        command: ["python3", root.scriptPath, "--watch"]

        stdout: SplitParser {
            onRead: function (line) {
                line = line.trim();
                if (!line)
                    return;
                try {
                    const apps = JSON.parse(line);
                    if (root.visible)
                        root.pendingAppsUpdate = apps;
                    else
                        root.applyAppsUpdate(apps);
                } catch (e) {
                    console.warn("Launcher: failed to parse app list:", e);
                }
            }
        }
    }

    Process {
        id: runtimeSync
        command: ["python3", root.runtimeScriptPath, "--sync-hypr-terminal"]
    }

    function moveSelection(direction, keepInputFocus) {
        if (root.results.length <= 0)
            return;
        if (!keepInputFocus && !view.listHasActiveFocus)
            view.focusList();

        const next = Logic.nextSelectionIndex(view.currentIndex, root.results.length, direction);
        view.currentIndex = next;
        view.ensureIndexVisible(next);
    }

    function pageMove(direction) {
        if (root.results.length <= 0)
            return;
        const next = Logic.pageSelectionIndex(view.currentIndex, root.results.length, view.listViewportHeight, view.rowHeight, direction);

        view.currentIndex = next;
        view.ensureIndexVisible(next);
    }

    function refilter() {
        root.results = Logic.buildResults(root.allApps, view.queryText);
    }

    function refilterResetSelection() {
        refilter();

        if (root.results.length <= 0) {
            view.currentIndex = -1;
            return;
        }

        view.currentIndex = 0;
        view.positionAtIndex(0, ListView.Beginning);
    }

    function refilterPreservingSelection(previousEntry, previousIndex) {
        refilter();

        if (root.results.length <= 0) {
            view.currentIndex = -1;
            return;
        }

        if (previousEntry) {
            const prevName = previousEntry.name ?? "";
            const prevExec = previousEntry.exec ?? "";
            const idx = root.results.findIndex(app => (app.name ?? "") === prevName && (app.exec ?? "") === prevExec);
            if (idx >= 0) {
                view.currentIndex = idx;
                view.positionAtIndex(idx, ListView.Contain);
                return;
            }
        }

        const clamped = Logic.clampSelectionIndex(previousIndex, root.results.length);
        view.currentIndex = clamped;
        view.positionAtIndex(clamped, ListView.Contain);
    }

    function applyAppsUpdate(apps) {
        const prevIdx = view.currentIndex;
        const previousEntry = (prevIdx >= 0 && prevIdx < root.results.length) ? root.results[prevIdx] : null;

        root.allApps = apps;
        root.refilterPreservingSelection(previousEntry, prevIdx);
    }

    function launch(entry) {
        if ((entry.kind ?? "") === "calculation") {
            const value = (entry.calc_value ?? "").trim();
            if (value !== "")
                Quickshell.execDetached(["sh", "-lc", "printf %s " + JSON.stringify(value) + " | wl-copy"]);
            root.visible = false;
            return;
        }

        const cmd = Logic.sanitizeExec(entry.exec ?? "");
        if (!cmd)
            return;
        const appId = (entry.id ?? "").trim();
        if (appId !== "") {
            Quickshell.execDetached(["python3", root.scriptPath, "--record-launch", appId]);
            entry.launch_count = Number(entry.launch_count ?? 0) + 1;
            entry.launch_last = Math.floor(Date.now() / 1000);
        }

        if (Boolean(entry.terminal ?? false)) {
            const wrapped = "if python3 " + JSON.stringify(root.runtimeScriptPath) + " --launch-terminal -- sh -lc "
                + JSON.stringify(cmd) + "; then :; else echo 'Launcher: terminal app skipped (runtime terminal not configured)' >&2; fi";
            Quickshell.execDetached(["sh", "-lc", wrapped]);
        } else {
            Quickshell.execDetached(["sh", "-lc", cmd]);
        }
        root.visible = false;
    }

    function computeUiScale() {
        const screenHeight = Number(screen?.height ?? 1080);
        const dpr = Number(screen?.devicePixelRatio ?? 1.0);
        const logicalPixelDensity = Number(screen?.logicalPixelDensity ?? (96 / 25.4));
        const dpiFactor = (logicalPixelDensity * 25.4) / 96;
        const screenName = String(screen?.name ?? "");
        let hyprScale = 1.0;
        const monitors = Hyprland.monitors ?? [];
        for (let i = 0; i < monitors.length; i += 1) {
            const mon = monitors[i];
            if (String(mon?.name ?? "") === screenName) {
                hyprScale = Number(mon?.scale ?? 1.0);
                break;
            }
        }
        if (hyprScale <= 0)
            hyprScale = Number(Hyprland.focusedMonitor?.scale ?? 1.0);
        const pixelFactor = Math.max(1.0, dpr, dpiFactor, hyprScale);
        const effectiveHeight = screenHeight * pixelFactor;
        const baseScale = Math.max(0.75, Math.min(2.0, effectiveHeight / 1080));
        return Math.max(0.75, Math.min(4.0, baseScale * scaleBoost));
    }

    function syncToFocusedScreen() {
        const focusedName = String(Hyprland.focusedMonitor?.name ?? "");
        if (focusedName.length <= 0)
            return;
        const allScreens = Quickshell.screens ?? [];
        for (let i = 0; i < allScreens.length; i += 1) {
            const candidate = allScreens[i];
            if (String(candidate?.name ?? "") === focusedName) {
                root.screen = candidate;
                return;
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            syncToFocusedScreen();
            uiScale = computeUiScale();
            view.resetPointerTracking();
            if (root.pendingAppsUpdate !== null) {
                root.applyAppsUpdate(root.pendingAppsUpdate);
                root.pendingAppsUpdate = null;
            }
            view.queryText = "";
            root.results = Logic.buildResults(root.allApps, view.queryText);
            if (root.results.length > 0)
                view.currentIndex = 0;
            view.focusSearch();
        } else if (root.pendingAppsUpdate !== null) {
            root.applyAppsUpdate(root.pendingAppsUpdate);
            root.pendingAppsUpdate = null;
        }
    }

    Component.onCompleted: {
        syncToFocusedScreen();
        uiScale = computeUiScale();
        appLoader.running = true;
        runtimeSync.running = true;
    }

    LauncherView {
        id: view
        anchors.fill: parent
        uiScale: root.uiScale
        results: root.results

        onQueryChanged: root.refilterResetSelection()
        onLaunchRequested: entry => root.launch(entry)
        onEscapeRequested: root.visible = false
        onStepRequested: (direction, keepInputFocus) => root.moveSelection(direction, keepInputFocus)
        onPageRequested: direction => root.pageMove(direction)
    }
}
