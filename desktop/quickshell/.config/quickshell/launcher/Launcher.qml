pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

PanelWindow {
    id: root

    visible: false
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    // Fixed size, no anchors — layer shell centers on the active output
    implicitWidth: 640
    implicitHeight: 480

    property point lastHoverGlobalPos: Qt.point(-1, -1)
    property var allApps: []
    property var results: []
    property var pendingAppsUpdate: null

    function moveSelection(direction) {
        if (root.results.length <= 0)
            return

        if (!listView.activeFocus)
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
        results = allApps.filter(app =>
            (app.name ?? "").toLowerCase().includes(q) ||
            (app.description ?? "").toLowerCase().includes(q)
        )
    }

    function refilterResetSelection() {
        refilter()

        if (results.length <= 0) {
            listView.currentIndex = -1
            return
        }

        listView.currentIndex = 0
        listView.positionViewAtIndex(0, ListView.Beginning)
    }

    function refilterPreservingSelection(previousEntry) {
        refilter()

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

        Quickshell.execDetached(["sh", "-lc", cmd])
        root.visible = false
    }

    // ── Lifecycle ─────────────────────────────────────────────────────────────

    onVisibleChanged: {
        if (visible) {
            if (root.pendingAppsUpdate !== null) {
                root.applyAppsUpdate(root.pendingAppsUpdate)
                root.pendingAppsUpdate = null
            }
            searchField.text = ""
            results = allApps
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

                    Keys.onUpPressed: root.moveSelection(-1)
                    Keys.onDownPressed: root.moveSelection(1)

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
                model: root.results
                clip: true
                keyNavigationEnabled: false
                keyNavigationWraps: false
                preferredHighlightBegin: 0
                preferredHighlightEnd: height
                highlightRangeMode: ListView.ApplyRange
                highlightFollowsCurrentItem: true
                highlightMoveDuration: 90
                highlightResizeDuration: 90

                highlight: Rectangle {
                    width: listView.width
                    height: listView.currentItem ? listView.currentItem.height : 56
                    radius: 6
                    color: Colors.surface0
                    opacity: listView.currentIndex >= 0 ? 1 : 0
                }

                add: Transition {
                    NumberAnimation {
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: 110
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        property: "scale"
                        from: 0.98
                        to: 1
                        duration: 110
                        easing.type: Easing.OutCubic
                    }
                }

                remove: Transition {
                    NumberAnimation {
                        property: "opacity"
                        from: 1
                        to: 0
                        duration: 90
                        easing.type: Easing.InCubic
                    }
                    NumberAnimation {
                        property: "scale"
                        from: 1
                        to: 0.98
                        duration: 90
                        easing.type: Easing.InCubic
                    }
                }

                move: Transition {
                    NumberAnimation {
                        property: "y"
                        duration: 130
                        easing.type: Easing.OutCubic
                    }
                }

                addDisplaced: Transition {
                    NumberAnimation {
                        property: "y"
                        duration: 130
                        easing.type: Easing.OutCubic
                    }
                }

                displaced: Transition {
                    NumberAnimation {
                        property: "y"
                        duration: 130
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
                    } else {
                        event.accepted = false
                    }
                }

                delegate: Rectangle {
                    id: appItem
                    required property var modelData
                    required property int index

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
                                source: ((appItem.modelData.icon_name ?? "") !== ""
                                    && !(appItem.modelData.icon_name ?? "").startsWith("/")
                                    && !((appItem.modelData.icon ?? "").startsWith("/")))
                                    ? "image://icon/" + appItem.modelData.icon_name
                                    : ""
                                visible: status === Image.Ready
                            }

                            Image {
                                id: fileIcon
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                mipmap: true
                                source: ((appItem.modelData.icon ?? "").startsWith("/"))
                                    ? "file://" + appItem.modelData.icon
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
                                text: appItem.modelData.name ?? ""
                                color: Colors.text
                                font.pixelSize: 14
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Text {
                                text: appItem.modelData.description ?? ""
                                color: Colors.subtext0
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                width: parent.width
                                visible: (appItem.modelData.description ?? "") !== ""
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: {
                            const gpos = mapToGlobal(mouseX, mouseY)
                            if (gpos.x !== root.lastHoverGlobalPos.x || gpos.y !== root.lastHoverGlobalPos.y) {
                                root.lastHoverGlobalPos = gpos
                                listView.currentIndex = appItem.index
                            }
                        }
                        onPositionChanged: mouse => {
                            const gpos = mapToGlobal(mouse.x, mouse.y)
                            if (gpos.x !== root.lastHoverGlobalPos.x || gpos.y !== root.lastHoverGlobalPos.y) {
                                root.lastHoverGlobalPos = gpos
                                listView.currentIndex = appItem.index
                            }
                        }
                        onClicked: root.launch(appItem.modelData)
                    }
                }
            }
        }
    }
}
