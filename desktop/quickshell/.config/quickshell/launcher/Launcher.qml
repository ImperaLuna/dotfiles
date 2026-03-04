pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "LauncherLogic.js" as Logic

PanelWindow {
    id: root

    visible: false
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    implicitWidth: 640
    implicitHeight: 480

    property var allApps: []
    property var results: []
    property var pendingAppsUpdate: null

    readonly property string scriptPath:
        Qt.resolvedUrl("list-apps.py").toString().replace(/^file:\/\//, "")

    Process {
        id: appLoader
        command: ["python3", root.scriptPath, "--watch"]

        stdout: SplitParser {
            onRead: function(line) {
                line = line.trim()
                if (!line)
                    return
                try {
                    const apps = JSON.parse(line)
                    if (root.visible)
                        root.pendingAppsUpdate = apps
                    else
                        root.applyAppsUpdate(apps)
                } catch (e) {
                    console.warn("Launcher: failed to parse app list:", e)
                }
            }
        }
    }

    function moveSelection(direction, keepInputFocus) {
        if (root.results.length <= 0)
            return

        if (!keepInputFocus && !view.listHasActiveFocus)
            view.focusList()

        const next = Logic.nextSelectionIndex(view.currentIndex, root.results.length, direction)
        view.currentIndex = next
        view.ensureIndexVisible(next)
    }

    function pageMove(direction) {
        if (root.results.length <= 0)
            return

        const next = Logic.pageSelectionIndex(
            view.currentIndex,
            root.results.length,
            view.listViewportHeight,
            56,
            direction
        )

        view.currentIndex = next
        view.ensureIndexVisible(next)
    }

    function refilter() {
        root.results = Logic.filterApps(root.allApps, view.queryText)
    }

    function refilterResetSelection() {
        refilter()

        if (root.results.length <= 0) {
            view.currentIndex = -1
            return
        }

        view.currentIndex = 0
        view.positionAtIndex(0, ListView.Beginning)
    }

    function refilterPreservingSelection(previousEntry, previousIndex) {
        refilter()

        if (root.results.length <= 0) {
            view.currentIndex = -1
            return
        }

        if (previousEntry) {
            const prevName = previousEntry.name ?? ""
            const prevExec = previousEntry.exec ?? ""
            const idx = root.results.findIndex(app =>
                (app.name ?? "") === prevName && (app.exec ?? "") === prevExec
            )
            if (idx >= 0) {
                view.currentIndex = idx
                view.positionAtIndex(idx, ListView.Contain)
                return
            }
        }

        const clamped = Logic.clampSelectionIndex(previousIndex, root.results.length)
        view.currentIndex = clamped
        view.positionAtIndex(clamped, ListView.Contain)
    }

    function applyAppsUpdate(apps) {
        const prevIdx = view.currentIndex
        const previousEntry = (prevIdx >= 0 && prevIdx < root.results.length)
            ? root.results[prevIdx]
            : null

        root.allApps = apps
        root.refilterPreservingSelection(previousEntry, prevIdx)
    }

    function launch(entry) {
        const cmd = Logic.sanitizeExec(entry.exec ?? "")
        if (!cmd)
            return

        const appId = (entry.id ?? "").trim()
        if (appId !== "") {
            Quickshell.execDetached(["python3", root.scriptPath, "--record-launch", appId])
            entry.launch_count = Number(entry.launch_count ?? 0) + 1
            entry.launch_last = Math.floor(Date.now() / 1000)
        }

        Quickshell.execDetached(["sh", "-lc", cmd])
        root.visible = false
    }

    onVisibleChanged: {
        if (visible) {
            view.resetPointerTracking()
            if (root.pendingAppsUpdate !== null) {
                root.applyAppsUpdate(root.pendingAppsUpdate)
                root.pendingAppsUpdate = null
            }
            view.queryText = ""
            root.results = root.allApps
            if (root.allApps.length > 0)
                view.currentIndex = 0
            view.focusSearch()
        } else if (root.pendingAppsUpdate !== null) {
            root.applyAppsUpdate(root.pendingAppsUpdate)
            root.pendingAppsUpdate = null
        }
    }

    Component.onCompleted: {
        appLoader.running = true
    }

    LauncherView {
        id: view
        anchors.fill: parent
        results: root.results

        onQueryChanged: root.refilterResetSelection()
        onLaunchRequested: entry => root.launch(entry)
        onEscapeRequested: root.visible = false
        onStepRequested: (direction, keepInputFocus) => root.moveSelection(direction, keepInputFocus)
        onPageRequested: direction => root.pageMove(direction)
    }
}
