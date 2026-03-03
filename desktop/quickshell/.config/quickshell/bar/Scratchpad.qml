import QtQuick
import Quickshell.Hyprland
import "../theme"

// Repeater over all workspaces — only the special workspace (id=-99) renders visibly.
// JS iteration of Hyprland.workspaces is broken; Repeater delegates are reactive.
Repeater {
    model: Hyprland.workspaces

    Rectangle {
        required property var modelData

        // activeToplevel switches to the scratchpad workspace when toggled on
        property bool isActive: Hyprland.activeToplevel?.workspace?.id === -99
        property bool hasWindows: (modelData.lastIpcObject?.windows ?? 0) > 0

        visible: modelData.id === -99 && (isActive || hasWindows)

        implicitHeight: 22
        implicitWidth: visible ? Math.max(label.implicitWidth + 16, 22) : 0
        radius: implicitHeight / 2
        color: isActive ? Colors.mauve : Colors.surface0

        Behavior on color {
            ColorAnimation { duration: 120 }
        }

        Text {
            id: label
            anchors.centerIn: parent
            text: "~"
            color: isActive ? Colors.crust : Colors.subtext0
            font.family: "JetBrainsMono Nerd Font"
            font.pointSize: 9
            font.bold: isActive

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
}
