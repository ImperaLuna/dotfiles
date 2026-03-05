pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../theme"

Item {
    id: root

    property bool open: false
    signal closeRequested()
    readonly property real nonAnimWidth: 272
    readonly property real nonAnimHeight: content.implicitHeight + 24

    visible: height > 0
    width: nonAnimWidth
    height: open ? nonAnimHeight : 0
    clip: true

    Behavior on height {
        NumberAnimation {
            duration: 170
            easing.type: Easing.InOutCubic
        }
    }

    ColumnLayout {
        id: content
        anchors.top: parent.top
        anchors.topMargin: 12
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 12
        spacing: 8

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Test Notifications"
                color: Colors.text
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                font.bold: true
            }

            Item { Layout.fillWidth: true }

            Text {
                id: closeIcon
                text: "close"
                color: Colors.subtext1
                opacity: closeMouse.containsMouse ? 1 : 0.8
                font.family: "Material Symbols Rounded"
                font.pixelSize: 16
                font.weight: 600
                renderType: Text.NativeRendering

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.closeRequested()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Colors.surface1
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 54
            radius: 10
            color: Colors.surface0

            Text {
                anchors.centerIn: parent
                text: "Placeholder toast item"
                color: Colors.subtext1
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 10
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 54
            radius: 10
            color: Colors.surface0

            Text {
                anchors.centerIn: parent
                text: "Hook this to real Notifs service"
                color: Colors.subtext1
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 10
            }
        }
    }
}
