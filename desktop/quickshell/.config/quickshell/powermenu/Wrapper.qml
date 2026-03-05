pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import QtQuick.Layouts
import "../metrics"
import "../theme"

Item {
    id: root

    property bool open: false
    required property real uiScale
    signal closeRequested()
    readonly property real nonAnimWidth: Math.round(Metrics.powerMenuWidthBase * uiScale)
    readonly property real rounding: Math.round(16 * uiScale)

    visible: width > 0
    width: open ? nonAnimWidth : 0
    height: content.implicitHeight + Math.round(24 * uiScale)
    clip: true

    Behavior on width {
        NumberAnimation {
            duration: Metrics.animDurationMid
            easing.type: Easing.InOutCubic
        }
    }

    ColumnLayout {
        id: content
        anchors.top: parent.top
        anchors.topMargin: Math.round(12 * root.uiScale)
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Math.round(12 * root.uiScale)

        PowerButton {
            Layout.alignment: Qt.AlignHCenter
            icon: "power_settings_new"
            title: "Shutdown"
            command: "systemctl poweroff"
        }

        PowerButton {
            Layout.alignment: Qt.AlignHCenter
            icon: "lock"
            title: "Lock"
            command: "if command -v hyprlock >/dev/null 2>&1; then hyprlock; else loginctl lock-session; fi"
        }

        PowerButton {
            Layout.alignment: Qt.AlignHCenter
            icon: "cached"
            title: "Reboot"
            command: "systemctl reboot"
        }

        PowerButton {
            Layout.alignment: Qt.AlignHCenter
            icon: "downloading"
            title: "Hibernate"
            command: "loginctl lock-session; sleep 1; systemctl suspend-then-hibernate || systemctl hibernate || systemctl suspend"
        }

        PowerButton {
            Layout.alignment: Qt.AlignHCenter
            icon: "logout"
            title: "Logout"
            command: "if command -v uwsm >/dev/null 2>&1; then uwsm stop; elif command -v hyprctl >/dev/null 2>&1; then hyprctl dispatch exit; else loginctl terminate-user \"$USER\"; fi"
        }
    }

    component PowerButton: Item {
        id: button

        required property string icon
        required property string title
        required property string command

        width: Math.round(104 * root.uiScale)
        height: iconButton.height + titleText.implicitHeight + Math.round(8 * root.uiScale)

        Rectangle {
            id: iconButton
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.round(56 * root.uiScale)
            height: Math.round(56 * root.uiScale)
            radius: Math.round(12 * root.uiScale)
            color: buttonMouse.containsMouse ? Colors.surface1 : Colors.surface0

            Text {
                anchors.centerIn: parent
                text: button.icon
                color: Colors.text
                font.family: Fonts.symbols
                font.pixelSize: Math.round(26 * root.uiScale)
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
            anchors.topMargin: Math.round(4 * root.uiScale)
            anchors.horizontalCenter: iconButton.horizontalCenter
            text: button.title
            color: Colors.text
            font.family: Fonts.text
            font.pixelSize: Math.round(10 * root.uiScale)
            font.bold: true
        }

    }
}
