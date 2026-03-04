import QtQuick
import Quickshell.Hyprland
import Quickshell.Io
import "../theme"

Item {
    id: root
    property real uiScale: 1.0
    property int specialClientCount: 0

    readonly property int focusedWorkspaceId: Hyprland.focusedWorkspace?.id ?? 0
    readonly property string focusedWorkspaceName: Hyprland.focusedWorkspace?.name ?? ""
    readonly property bool isActive: focusedWorkspaceId === -99
          || focusedWorkspaceId === 99
          || focusedWorkspaceName === "~"
          || focusedWorkspaceName.startsWith("special:")
    readonly property bool hasWindows: specialClientCount > 0

    visible: isActive || hasWindows
    implicitHeight: visible ? Math.max(16, Math.round(Metrics.workspacePillHeightBase * root.uiScale)) : 0
    implicitWidth: visible ? Math.max(
        label.implicitWidth + Math.max(8, Math.round(Metrics.workspacePillPadXBase * root.uiScale)),
        Math.round(Metrics.workspacePillMinWidthBase * root.uiScale)
    ) : 0

    Rectangle {
        anchors.fill: parent
        radius: Math.max(1, parent.height / 2)
        color: root.isActive ? Colors.mauve : Colors.surface0

        Behavior on color {
            ColorAnimation { duration: 120 }
        }

        Text {
            id: label
            anchors.fill: parent
            text: "~"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            x: Metrics.scratchpadGlyphNudgeX
            color: root.isActive ? Colors.crust : Colors.subtext0
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: Math.max(9, Math.round(Metrics.workspaceFontBase * root.uiScale))
            font.bold: root.isActive
            renderType: Text.NativeRendering

            Behavior on color {
                ColorAnimation { duration: 120 }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Hyprland.dispatch("togglespecialworkspace")
        }
    }

    Process {
        id: clientProbe
        running: false
        command: [
            "sh", "-lc",
            "hyprctl clients -j | python3 -c 'import json,sys; data=json.load(sys.stdin); print(sum(1 for c in data if int((c.get(\"workspace\") or {}).get(\"id\",0)) in (99,-99) or str((c.get(\"workspace\") or {}).get(\"name\",\"\")).startswith(\"special:\") or str((c.get(\"workspace\") or {}).get(\"name\",\"\")) == \"~\"))'"
        ]

        stdout: SplitParser {
            onRead: function(line) {
                const n = parseInt((line ?? "").trim())
                if (!Number.isNaN(n))
                    root.specialClientCount = Math.max(0, n)
            }
        }
    }

    Timer {
        interval: 900
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            if (!clientProbe.running)
                clientProbe.running = true
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent() {
            if (!clientProbe.running)
                clientProbe.running = true
        }
    }
}
