pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../theme"

Item {
    id: root

    property bool open: false
    required property var placementConfig
    required property var allScreens
    signal closeRequested()

    readonly property real nonAnimWidth: 360
    readonly property real nonAnimHeight: content.implicitHeight + 24
    readonly property bool singleMode: (placementConfig?.normalizedMode?.() ?? "single") === "single"

    visible: opacity > 0
    width: nonAnimWidth
    height: nonAnimHeight
    opacity: open ? 1 : 0
    scale: open ? 1 : 0.96

    Behavior on opacity {
        NumberAnimation {
            duration: 140
            easing.type: Easing.OutCubic
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: Colors.surface0
        border.width: 1
        border.color: Colors.overlay0
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Settings (Placeholder)"
                color: Colors.text
                font.family: Fonts.text
                font.pixelSize: 13
                font.bold: true
            }

            Item { Layout.fillWidth: true }

            Text {
                text: "close"
                color: Colors.subtext0
                font.family: Fonts.symbols
                font.pixelSize: 18

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.closeRequested()
                }
            }
        }

        Text {
            text: "Notification Placement"
            color: Colors.subtext1
            font.family: Fonts.text
            font.pixelSize: 11
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            ModeButton {
                text: "Single"
                active: root.placementConfig.normalizedMode() === "single"
                onClicked: root.placementConfig.mode = "single"
            }

            ModeButton {
                text: "Focused"
                active: root.placementConfig.normalizedMode() === "focused"
                onClicked: root.placementConfig.mode = "focused"
            }

            ModeButton {
                text: "All"
                active: root.placementConfig.normalizedMode() === "all"
                onClicked: root.placementConfig.mode = "all"
            }
        }

        ColumnLayout {
            visible: root.singleMode
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "Screen"
                color: Colors.subtext1
                font.family: Fonts.text
                font.pixelSize: 11
            }

            Flow {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: root.allScreens ?? []

                    delegate: ScreenButton {
                        required property var modelData
                        screenName: modelData.name
                        active: (root.placementConfig.screenName.trim().length > 0
                            ? root.placementConfig.screenName === screenName
                            : modelData === root.allScreens[0])
                        onClicked: root.placementConfig.screenName = screenName
                    }
                }
            }
        }
    }

    component ModeButton: Rectangle {
        id: modeButton
        required property string text
        required property bool active
        signal clicked()

        radius: 10
        implicitWidth: label.implicitWidth + 16
        implicitHeight: 28
        color: active ? Colors.blue : Colors.surface1

        Text {
            id: label
            anchors.centerIn: parent
            text: modeButton.text
            color: modeButton.active ? Colors.crust : Colors.text
            font.family: Fonts.text
            font.pixelSize: 11
            font.bold: modeButton.active
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: modeButton.clicked()
        }
    }

    component ScreenButton: Rectangle {
        id: screenButton
        required property string screenName
        required property bool active
        signal clicked()

        radius: 8
        implicitWidth: screenLabel.implicitWidth + 14
        implicitHeight: 24
        color: active ? Colors.teal : Colors.surface1

        Text {
            id: screenLabel
            anchors.centerIn: parent
            text: screenButton.screenName
            color: screenButton.active ? Colors.crust : Colors.text
            font.family: Fonts.text
            font.pixelSize: 10
            font.bold: screenButton.active
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: screenButton.clicked()
        }
    }
}
