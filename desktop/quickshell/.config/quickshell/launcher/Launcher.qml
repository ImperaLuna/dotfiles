import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
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

    property var allApps: []
    property var results: []

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
                    root.allApps = JSON.parse(line)
                    root.results = root.allApps
                    if (root.visible) searchField.forceActiveFocus()
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
            searchField.text = ""
            results = allApps
            if (allApps.length > 0) {
                searchField.forceActiveFocus()
            }
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
                height: 42
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

                    onTextChanged: root.refilter()

                    Keys.onEscapePressed: root.visible = false
                    Keys.onDownPressed:   listView.forceActiveFocus()
                    Keys.onReturnPressed: {
                        if (root.results.length > 0)
                            root.launch(root.results[0])
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
                keyNavigationEnabled: true
                keyNavigationWraps: true

                Keys.onEscapePressed: root.visible = false
                Keys.onReturnPressed: {
                    if (currentIndex >= 0 && currentIndex < root.results.length)
                        root.launch(root.results[currentIndex])
                }
                Keys.onUpPressed: {
                    if (currentIndex <= 0)
                        searchField.forceActiveFocus()
                    else
                        decrementCurrentIndex()
                }

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    width: listView.width
                    height: 56
                    color: ListView.isCurrentItem ? Colors.surface0 : "transparent"
                    radius: 6

                    Behavior on color { ColorAnimation { duration: 80 } }

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
                                source: ((modelData.icon_name ?? "") !== ""
                                    && !(modelData.icon_name ?? "").startsWith("/")
                                    && !((modelData.icon ?? "").startsWith("/")))
                                    ? "image://icon/" + modelData.icon_name
                                    : ""
                                visible: status === Image.Ready
                            }

                            Image {
                                id: fileIcon
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                mipmap: true
                                source: ((modelData.icon ?? "").startsWith("/"))
                                    ? "file://" + modelData.icon
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
                                text: modelData.name ?? ""
                                color: Colors.text
                                font.pixelSize: 14
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Text {
                                text: modelData.description ?? ""
                                color: Colors.subtext0
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                width: parent.width
                                visible: (modelData.description ?? "") !== ""
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: listView.currentIndex = index
                        onClicked: root.launch(modelData)
                    }
                }
            }
        }
    }
}
