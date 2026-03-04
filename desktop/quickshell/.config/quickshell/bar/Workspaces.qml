pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Hyprland
import "../theme"

Row {
    id: root
    spacing: Math.max(2, Math.round(Metrics.sectionGapBase * root.uiScale))

    property string monitorName: ""
    property real uiScale: 1.0

    Repeater {
        model: Hyprland.workspaces

        Rectangle {
            id: pill
            required property var modelData

            // Special workspaces are rendered by Scratchpad.qml as "~".
            // Keep the normal workspace row free of special:* entries.
            property bool isSpecialWorkspace: modelData.id === 99
                  || modelData.id === -99
                  || modelData.name === "~"
                  || (modelData.name ?? "").startsWith("special:")
            property bool hasWindows: (modelData.lastIpcObject?.windows ?? 0) > 0

            visible: modelData.id > 0
                  && !isSpecialWorkspace
                  && pill.modelData.monitor?.name === root.monitorName
                  && (hasWindows || modelData.active)

            height: Math.max(16, Math.round(Metrics.workspacePillHeightBase * root.uiScale))
            width: Math.max(
                label.implicitWidth + Math.max(8, Math.round(Metrics.workspacePillPadXBase * root.uiScale)),
                Math.round(Metrics.workspacePillMinWidthBase * root.uiScale)
            )
            radius: height / 2

            color: modelData.active ? Colors.blue : Colors.surface0

            Behavior on color {
                ColorAnimation { duration: 120 }
            }

            Text {
                id: label
                anchors.centerIn: parent
                text: pill.modelData.name
                color: pill.modelData.active ? Colors.crust : Colors.subtext0
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: Math.max(9, Math.round(Metrics.workspaceFontBase * root.uiScale))
                font.bold: pill.modelData.active

                Behavior on color {
                    ColorAnimation { duration: 120 }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: pill.modelData.activate()
            }
        }
    }
}
