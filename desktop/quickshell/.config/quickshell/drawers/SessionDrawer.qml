import Quickshell
import QtQuick
import QtQuick.Layouts
import "../theme"

Item {
    id: root

    property bool open: false
    signal closeRequested()
    readonly property real nonAnimWidth: 176
    readonly property real rounding: 16

    visible: width > 0
    width: open ? nonAnimWidth : 0
    height: content.implicitHeight + 24
    clip: true

    Behavior on width {
        NumberAnimation {
            duration: 170
            easing.type: Easing.InOutCubic
        }
    }

    ColumnLayout {
        id: content
        anchors.top: parent.top
        anchors.topMargin: 12
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 12

        SessionButton {
            Layout.alignment: Qt.AlignHCenter
            icon: "power_settings_new"
            title: "Shutdown"
            command: "systemctl poweroff"
        }

        SessionButton {
            Layout.alignment: Qt.AlignHCenter
            icon: "lock"
            title: "Lock"
            command: "if command -v hyprlock >/dev/null 2>&1; then hyprlock; else loginctl lock-session; fi"
        }

        SessionButton {
            Layout.alignment: Qt.AlignHCenter
            icon: "cached"
            title: "Reboot"
            command: "systemctl reboot"
        }

        SessionButton {
            Layout.alignment: Qt.AlignHCenter
            icon: "downloading"
            title: "Hibernate"
            command: "loginctl lock-session; sleep 1; systemctl suspend-then-hibernate || systemctl hibernate || systemctl suspend"
        }

        SessionButton {
            Layout.alignment: Qt.AlignHCenter
            icon: "logout"
            title: "Logout"
            command: "if command -v uwsm >/dev/null 2>&1; then uwsm stop; elif command -v hyprctl >/dev/null 2>&1; then hyprctl dispatch exit; else loginctl terminate-user \"$USER\"; fi"
        }
    }

    component SessionButton: Item {
        id: button

        required property string icon
        required property string title
        required property string command

        width: 104
        height: iconButton.height + titleText.implicitHeight + 8

        Rectangle {
            id: iconButton
            anchors.horizontalCenter: parent.horizontalCenter
            width: 56
            height: 56
            radius: 12
            color: buttonMouse.containsMouse ? Colors.surface1 : Colors.surface0

            Text {
                anchors.centerIn: parent
                text: button.icon
                color: Colors.text
                font.family: "Material Symbols Rounded"
                font.pixelSize: 26
                font.weight: 600
                renderType: Text.NativeRendering
            }

            MouseArea {
                id: buttonMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Quickshell.execDetached(["sh", "-lc", button.command])
                    root.closeRequested()
                }
            }
        }

        Text {
            id: titleText
            anchors.top: iconButton.bottom
            anchors.topMargin: 4
            anchors.horizontalCenter: iconButton.horizontalCenter
            text: button.title
            color: Colors.text
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 10
            font.bold: true
        }

    }
}
