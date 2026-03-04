import QtQuick
import Quickshell.Hyprland
import "../theme"

// Repeater over all workspaces — only the special workspace (id=-99) renders visibly.
// JS iteration of Hyprland.workspaces is broken; Repeater delegates are reactive.
Repeater {
    id: scratchpadRepeater
    model: Hyprland.workspaces
    property real uiScale: 1.0

    Rectangle {
        required property var modelData

        // activeToplevel switches to the scratchpad workspace when toggled on
        property bool isActive: Hyprland.activeToplevel?.workspace?.id === -99
        property bool hasWindows: (modelData.lastIpcObject?.windows ?? 0) > 0

        visible: modelData.id === -99 && (isActive || hasWindows)

        implicitHeight: Math.max(16, Math.round(Metrics.workspacePillHeightBase * scratchpadRepeater.uiScale))
        implicitWidth: visible ? Math.max(
            label.implicitWidth + Math.max(8, Math.round(Metrics.workspacePillPadXBase * scratchpadRepeater.uiScale)),
            Math.round(Metrics.workspacePillMinWidthBase * scratchpadRepeater.uiScale)
        ) : 0
        radius: implicitHeight / 2
        color: isActive ? Colors.mauve : Colors.surface0

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
            color: isActive ? Colors.crust : Colors.subtext0
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: Math.max(9, Math.round(Metrics.workspaceFontBase * scratchpadRepeater.uiScale))
            font.bold: isActive
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
}
