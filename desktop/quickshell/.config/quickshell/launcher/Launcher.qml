pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

/*
  Launcher interaction regression checklist (do not break):

  1) Arrow-key navigation must not jump back to the last mouse-hovered row.
  2) Mouse movement alone must not scroll/reposition the list viewport.
  3) Hovering near top/bottom edges must not select partially clipped rows.
  4) There must be a single effective selection source (`currentIndex`) and one
     visible selected item at a time.
  5) Keyboard navigation should continue from the currently selected row, including
     rows selected by mouse interaction.
  6) Search updates should keep selection behavior stable (reset to first result
     for typed filter changes).

  Current design constraints used to enforce this:
  - Hover selection is gated by real pointer movement (`pointerActuallyMoved`).
  - Hover selection is gated by full row visibility (`fullyVisibleInList`).
  - List auto-scroll on highlight changes is disabled (`NoHighlightRange`).
  - Explicit scrolling is keyboard-driven via `positionViewAtIndex`.
*/

PanelWindow {
    id: root

    visible: false
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    // Fixed size, no anchors — layer shell centers on the active output
    implicitWidth: 640
    implicitHeight: 480

    property var allApps: []
    property var results: []
    property var pendingAppsUpdate: null
    property point lastPointerGlobalPos: Qt.point(-1, -1)

    // Ignore hover changes caused only by delegate movement under a fixed cursor.
    function pointerActuallyMoved(globalPos) {
        if (globalPos.x !== root.lastPointerGlobalPos.x || globalPos.y !== root.lastPointerGlobalPos.y) {
            root.lastPointerGlobalPos = globalPos
            return true
        }
        return false
    }

    function moveSelection(direction, keepInputFocus) {
        if (root.results.length <= 0)
            return

        if (!keepInputFocus && !listView.activeFocus)
            listView.forceActiveFocus()

        let next = listView.currentIndex
        if (next < 0) {
            next = direction > 0 ? 0 : root.results.length - 1
        } else if (direction > 0) {
            next = Math.min(root.results.length - 1, next + 1)
        } else {
            next = Math.max(0, next - 1)
        }

        listView.currentIndex = next
        listView.positionViewAtIndex(next, ListView.Contain)
    }

    function pageMove(direction) {
        if (root.results.length <= 0)
            return

        const itemHeight = 56
        const step = Math.max(1, Math.floor(listView.height / itemHeight) - 1)

        let next = listView.currentIndex
        if (next < 0)
            next = 0

        next = direction > 0
            ? Math.min(root.results.length - 1, next + step)
            : Math.max(0, next - step)

        listView.currentIndex = next
        listView.positionViewAtIndex(next, ListView.Contain)
    }

    // ── App loading via Python helper ─────────────────────────────────────────

    readonly property string scriptPath:
        Qt.resolvedUrl("list-apps.py").toString().replace(/^file:\/\//, "")

    Process {
        id: appLoader
        command: ["python3", root.scriptPath, "--watch"]

        stdout: SplitParser {
            onRead: function(line) {
                line = line.trim()
                if (!line) return
                try {
                    const apps = JSON.parse(line)
                    if (root.visible)
                        root.pendingAppsUpdate = apps
                    else
                        root.applyAppsUpdate(apps)
                } catch(e) {
                    console.warn("Launcher: failed to parse app list:", e)
                }
            }
        }
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    function refilter() {
        const q = searchField.text.toLowerCase()
        if (q === "") {
            results = allApps
            return
        }

        function scoreField(field, needle, base, allowSubsequence) {
            if (!field)
                return -1

            const text = field.toLowerCase()
            if (text === needle)
                return base + 8000
            if (text.startsWith(needle))
                return base + 6000 - Math.min(2000, text.length)

            const idx = text.indexOf(needle)
            if (idx >= 0) {
                // Keep very short queries strict to avoid noisy matches.
                if (needle.length <= 3 && idx > 0) {
                    const prev = text[idx - 1]
                    const wordBoundary = (prev < "a" || prev > "z") && (prev < "0" || prev > "9")
                    if (!wordBoundary)
                        return -1
                }
                return base + 3500 - idx * 18
            }

            if (!allowSubsequence || needle.length < 4)
                return -1

            // Lightweight subsequence matching for fuzzy-ish reordering.
            let last = -1
            let streak = 0
            let hits = 0
            for (let i = 0; i < needle.length; i++) {
                const pos = text.indexOf(needle[i], last + 1)
                if (pos < 0)
                    return -1
                if (pos === last + 1)
                    streak += 1
                else
                    streak = 0
                hits += 1 + streak
                last = pos
            }
            return base + 1200 + hits * 16 - last
        }

        const scored = []
        for (const app of allApps) {
            const name = app.name ?? ""
            const desc = app.description ?? ""
            const exec = app.exec ?? ""

            const sName = scoreField(name, q, 6000, true)
            const sDesc = q.length >= 3 ? scoreField(desc, q, 2400, false) : -1
            const sExec = q.length >= 4 ? scoreField(exec, q, 1200, false) : -1
            let score = Math.max(sName, sDesc, sExec)

            if (score >= 0) {
                const launches = Number(app.launch_count ?? 0)
                const lastLaunch = Number(app.launch_last ?? 0)
                if (launches > 0) {
                    const nowSec = Date.now() / 1000
                    const ageDays = Math.max(0, (nowSec - lastLaunch) / 86400)

                    // 7-day half-life: recent usage matters more, old usage fades.
                    const recency = lastLaunch > 0
                        ? Math.exp(-Math.LN2 * ageDays / 7)
                        : 0
                    const frequency = Math.log2(launches + 1)
                    const frecency = frequency * (520 + recency * 780)
                    const recencyKick = ageDays < (1 / 24) ? 200 : (ageDays < 1 ? 90 : 0)

                    score += Math.min(3400, frecency + recencyKick)
                }
                scored.push({ app, score })
            }
        }

        scored.sort((a, b) => {
            if (b.score !== a.score)
                return b.score - a.score
            const an = (a.app.name ?? "").toLowerCase()
            const bn = (b.app.name ?? "").toLowerCase()
            return an.localeCompare(bn)
        })

        results = scored.map(e => e.app)
    }

    function refilterResetSelection() {
        refilter()
        syncResultsModel()

        if (results.length <= 0) {
            listView.currentIndex = -1
            return
        }

        listView.currentIndex = 0
        listView.positionViewAtIndex(0, ListView.Beginning)
    }

    function refilterPreservingSelection(previousEntry) {
        refilter()
        syncResultsModel()

        if (results.length <= 0) {
            listView.currentIndex = -1
            return
        }

        if (previousEntry) {
            const prevName = previousEntry.name ?? ""
            const prevExec = previousEntry.exec ?? ""
            const idx = results.findIndex(app =>
                (app.name ?? "") === prevName && (app.exec ?? "") === prevExec
            )
            if (idx >= 0) {
                listView.currentIndex = idx
                listView.positionViewAtIndex(idx, ListView.Contain)
                return
            }
        }

        const clamped = Math.max(0, Math.min(listView.currentIndex, results.length - 1))
        listView.currentIndex = clamped
        listView.positionViewAtIndex(clamped, ListView.Contain)
    }

    function applyAppsUpdate(apps) {
        const previousEntry = (listView.currentIndex >= 0 && listView.currentIndex < results.length)
            ? results[listView.currentIndex]
            : null

        root.allApps = apps
        root.refilterPreservingSelection(previousEntry)
    }

    function syncResultsModel() {
        resultsModel.clear()
        for (const app of results)
            resultsModel.append({ entry: app })
    }

    function sanitizeExec(execLine) {
        if (!execLine) return ""

        // Keep literal percent (%%) intact while stripping desktop entry field codes.
        let cmd = execLine.replace(/%%/g, "__QS_LITERAL_PERCENT__")
        cmd = cmd.replace(/%[A-Za-z]/g, "")
        cmd = cmd.replace(/__QS_LITERAL_PERCENT__/g, "%")

        // Normalize whitespace after placeholder removal.
        return cmd.replace(/\s+/g, " ").trim()
    }

    function launch(entry) {
        const cmd = sanitizeExec(entry.exec ?? "")
        if (!cmd) return

        const appId = (entry.id ?? "").trim()
        if (appId !== "") {
            Quickshell.execDetached(["python3", root.scriptPath, "--record-launch", appId])
            entry.launch_count = Number(entry.launch_count ?? 0) + 1
            entry.launch_last = Math.floor(Date.now() / 1000)
        }

        Quickshell.execDetached(["sh", "-lc", cmd])
        root.visible = false
    }

    function shouldSelectFromHover(globalPos, fullyVisible) {
        return pointerActuallyMoved(globalPos) && !listView.moving && fullyVisible
    }

    // ── Lifecycle ─────────────────────────────────────────────────────────────

    onVisibleChanged: {
        if (visible) {
            root.lastPointerGlobalPos = Qt.point(-1, -1)
            if (root.pendingAppsUpdate !== null) {
                root.applyAppsUpdate(root.pendingAppsUpdate)
                root.pendingAppsUpdate = null
            }
            searchField.text = ""
            results = allApps
            syncResultsModel()
            if (allApps.length > 0) {
                listView.currentIndex = 0
                searchField.forceActiveFocus()
            }
        } else if (root.pendingAppsUpdate !== null) {
            root.applyAppsUpdate(root.pendingAppsUpdate)
            root.pendingAppsUpdate = null
        }
    }

    Component.onCompleted: {
        appLoader.running = true
    }

    // ── UI ────────────────────────────────────────────────────────────────────

    Rectangle {
        anchors.fill: parent
        color: Colors.base
        radius: 12
        border.color: Colors.surface1
        border.width: 1

        ColumnLayout {
            anchors {
                fill: parent
                margins: 12
            }
            spacing: 8

            // Search field
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 42
                color: Colors.mantle
                radius: 8

                TextField {
                    id: searchField
                    anchors {
                        fill: parent
                        leftMargin: 12
                        rightMargin: 12
                    }
                    placeholderText: "Search applications…"
                    background: null
                    color: Colors.text
                    placeholderTextColor: Colors.overlay0
                    font.pixelSize: 14
                    font.family: "JetBrainsMono Nerd Font"

                    onTextChanged: root.refilterResetSelection()

                    Keys.onUpPressed: root.moveSelection(-1, true)
                    Keys.onDownPressed: root.moveSelection(1, true)

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            root.visible = false
                            event.accepted = true
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            if (listView.currentIndex >= 0 && listView.currentIndex < root.results.length)
                                root.launch(root.results[listView.currentIndex])
                            else if (root.results.length > 0)
                                root.launch(root.results[0])
                            event.accepted = true
                        } else if (event.modifiers & Qt.ControlModifier) {
                            if (event.key === Qt.Key_J) {
                                root.moveSelection(1, true)
                                event.accepted = true
                            } else if (event.key === Qt.Key_K) {
                                root.moveSelection(-1, true)
                                event.accepted = true
                            } else if (event.key === Qt.Key_D) {
                                root.pageMove(1)
                                event.accepted = true
                            } else if (event.key === Qt.Key_U) {
                                root.pageMove(-1)
                                event.accepted = true
                            } else {
                                event.accepted = false
                            }
                        } else {
                            event.accepted = false
                        }
                    }
                }
            }

            // App list
            ListView {
                id: listView
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: ListModel { id: resultsModel }
                clip: true
                boundsBehavior: Flickable.DragAndOvershootBounds
                maximumFlickVelocity: 3000
                flickDeceleration: 8500
                keyNavigationEnabled: false
                keyNavigationWraps: false
                preferredHighlightBegin: 0
                preferredHighlightEnd: height
                // Keep hover/currentIndex updates from auto-scrolling the viewport.
                highlightRangeMode: ListView.NoHighlightRange
                highlightFollowsCurrentItem: false
                highlightMoveDuration: 90
                highlightResizeDuration: 90

                rebound: Transition {
                    NumberAnimation {
                        properties: "x,y"
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on contentY {
                    enabled: !listView.moving && !listView.dragging

                    NumberAnimation {
                        duration: 120
                        easing.type: Easing.OutCubic
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    id: scrollBar
                    property bool showWhileScrolling: false

                    visible: listView.contentHeight > listView.height
                    policy: ScrollBar.AsNeeded
                    active: showWhileScrolling || pressed
                    width: 10
                    padding: 2

                    Connections {
                        target: listView

                        function onMovingChanged() {
                            if (listView.moving) {
                                fadeOutTimer.stop()
                                scrollBar.showWhileScrolling = true
                            } else {
                                fadeOutTimer.restart()
                            }
                        }
                    }

                    Timer {
                        id: fadeOutTimer
                        interval: 650
                        onTriggered: scrollBar.showWhileScrolling = false
                    }

                    background: Rectangle {
                        radius: 999
                        color: Colors.surface0
                        opacity: (scrollBar.size < 1 && scrollBar.showWhileScrolling) ? 0.4 : 0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 420
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    contentItem: Rectangle {
                        radius: 999
                        color: Colors.overlay0
                        opacity: {
                            if (scrollBar.size >= 1)
                                return 0
                            if (scrollBar.pressed)
                                return 0.95
                            if (scrollBar.showWhileScrolling)
                                return 0.8
                            return 0
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 420
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }

                highlight: Rectangle {
                    width: listView.width
                    height: listView.currentItem ? listView.currentItem.height : 56
                    radius: 6
                    color: Colors.surface0
                    opacity: (listView.currentIndex >= 0 && !listView.moving) ? 1 : 0
                    y: listView.currentItem ? listView.currentItem.y : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 70
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on y {
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                add: Transition {
                    NumberAnimation {
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: 130
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        property: "y"
                        from: 10
                        duration: 130
                        easing.type: Easing.OutCubic
                    }
                }

                remove: Transition {
                    NumberAnimation {
                        property: "opacity"
                        from: 1
                        to: 0
                        duration: 110
                        easing.type: Easing.InOutCubic
                    }
                    NumberAnimation {
                        property: "scale"
                        from: 1
                        to: 0.985
                        duration: 110
                        easing.type: Easing.InOutCubic
                    }
                }

                move: Transition {
                    NumberAnimation {
                        property: "y"
                        duration: 170
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        property: "opacity"
                        to: 1
                        duration: 120
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        property: "scale"
                        to: 1
                        duration: 150
                        easing.type: Easing.OutCubic
                    }
                }

                addDisplaced: Transition {
                    NumberAnimation {
                        property: "y"
                        duration: 170
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        property: "opacity"
                        to: 1
                        duration: 120
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        property: "scale"
                        to: 1
                        duration: 150
                        easing.type: Easing.OutCubic
                    }
                }

                displaced: Transition {
                    NumberAnimation {
                        property: "y"
                        duration: 170
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        property: "opacity"
                        to: 1
                        duration: 120
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        property: "scale"
                        to: 1
                        duration: 150
                        easing.type: Easing.OutCubic
                    }
                }

                Keys.onUpPressed: {
                    root.moveSelection(-1)
                }
                Keys.onDownPressed: {
                    root.moveSelection(1)
                }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        root.visible = false
                        event.accepted = true
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        if (currentIndex >= 0 && currentIndex < root.results.length)
                            root.launch(root.results[currentIndex])
                        event.accepted = true
                    } else if (event.modifiers & Qt.ControlModifier) {
                        if (event.key === Qt.Key_J) {
                            root.moveSelection(1)
                            event.accepted = true
                        } else if (event.key === Qt.Key_K) {
                            root.moveSelection(-1)
                            event.accepted = true
                        } else if (event.key === Qt.Key_D) {
                            root.pageMove(1)
                            event.accepted = true
                        } else if (event.key === Qt.Key_U) {
                            root.pageMove(-1)
                            event.accepted = true
                        } else {
                            event.accepted = false
                        }
                    } else {
                        event.accepted = false
                    }
                }

                delegate: Rectangle {
                    id: appItem
                    required property var entry
                    required property int index

                    // Ignore partially clipped top/bottom rows for hover selection.
                    function fullyVisibleInList() {
                        const viewportY = appItem.y - listView.contentY
                        return viewportY >= 0 && (viewportY + appItem.height) <= listView.height
                    }

                    width: listView.width
                    height: 56
                    color: "transparent"
                    radius: 6

                    Row {
                        anchors {
                            verticalCenter: parent.verticalCenter
                            left: parent.left
                            leftMargin: 8
                            right: parent.right
                            rightMargin: 8
                        }
                        spacing: 12

                        // Icon
                        Item {
                            width: 36
                            height: 36
                            anchors.verticalCenter: parent.verticalCenter

                            Image {
                                id: themeIcon
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                mipmap: true
                                source: ((appItem.entry.icon_name ?? "") !== ""
                                    && !(appItem.entry.icon_name ?? "").startsWith("/")
                                    && !((appItem.entry.icon ?? "").startsWith("/")))
                                    ? "image://icon/" + appItem.entry.icon_name
                                    : ""
                                visible: status === Image.Ready
                            }

                            Image {
                                id: fileIcon
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                mipmap: true
                                source: ((appItem.entry.icon ?? "").startsWith("/"))
                                    ? "file://" + appItem.entry.icon
                                    : ""
                                visible: status === Image.Ready
                            }

                            Rectangle {
                                anchors.fill: parent
                                visible: themeIcon.status !== Image.Ready && !fileIcon.visible
                                radius: 6
                                color: Colors.surface1

                                Text {
                                    anchors.centerIn: parent
                                    text: "\u25A1"
                                    color: Colors.overlay0
                                    font.pixelSize: 16
                                }
                            }
                        }

                        // Name + description
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            width: parent.width - 48   // 36 icon + 12 spacing

                            Text {
                                text: appItem.entry.name ?? ""
                                color: Colors.text
                                font.pixelSize: 14
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Text {
                                text: appItem.entry.description ?? ""
                                color: Colors.subtext0
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                width: parent.width
                                visible: (appItem.entry.description ?? "") !== ""
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: {
                            const gpos = mapToGlobal(mouseX, mouseY)
                            if (root.shouldSelectFromHover(gpos, appItem.fullyVisibleInList()))
                                listView.currentIndex = appItem.index
                        }
                        onPositionChanged: mouse => {
                            const gpos = mapToGlobal(mouse.x, mouse.y)
                            if (root.shouldSelectFromHover(gpos, appItem.fullyVisibleInList()))
                                listView.currentIndex = appItem.index
                        }
                        onPressed: {
                            root.lastPointerGlobalPos = mapToGlobal(mouseX, mouseY)
                            listView.currentIndex = appItem.index
                        }
                        onClicked: root.launch(appItem.entry)
                    }
                }
            }
        }
    }
}
