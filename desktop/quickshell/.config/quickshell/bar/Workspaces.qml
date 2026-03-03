import QtQuick
import Quickshell.Hyprland
import "../theme"

Row {
    spacing: 4

    property string monitorName: ""

    Repeater {
        model: Hyprland.workspaces

        Rectangle {
            required property var modelData

            visible: modelData.id > 0
                  && modelData.monitor?.name === monitorName
                  && ((modelData.lastIpcObject?.windows ?? 0) > 0 || modelData.active)

            height: 22
            width: Math.max(label.implicitWidth + 16, 22)
            radius: height / 2

            color: modelData.active ? Colors.blue : Colors.surface0

            Behavior on color {
                ColorAnimation { duration: 120 }
            }

            Text {
                id: label
                anchors.centerIn: parent
                text: modelData.name
                color: modelData.active ? Colors.crust : Colors.subtext0
                font.family: "JetBrainsMono Nerd Font"
                font.pointSize: 9
                font.bold: modelData.active

                Behavior on color {
                    ColorAnimation { duration: 120 }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: modelData.activate()
            }
        }
    }
}
