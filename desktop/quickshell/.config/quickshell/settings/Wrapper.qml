pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../metrics"
import "../theme"

Item {
    id: root

    property bool open: false
    required property real uiScale
    required property var placementConfig
    required property var allScreens
    signal closeRequested()

    readonly property real nonAnimWidth: Math.round(Metrics.settingsWidthBase * root.uiScale)
    readonly property real nonAnimHeight: content.implicitHeight + Math.round(24 * root.uiScale)
    readonly property bool singleMode: (placementConfig?.normalizedMode?.() ?? "single") === "single"

    visible: opacity > 0
    width: nonAnimWidth
    height: nonAnimHeight
    opacity: open ? 1 : 0
    scale: open ? 1 : 0.96

    Behavior on opacity {
        NumberAnimation {
            duration: Metrics.animDurationButton
            easing.type: Easing.OutCubic
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: Metrics.animDurationPanel
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Math.round(Metrics.panelCornerRadiusBase * root.uiScale)
        color: Colors.surface0
        border.width: Math.max(1, Math.round(root.uiScale))
        border.color: Colors.overlay0
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: Math.round(Metrics.panelOuterPaddingBase * root.uiScale)
        spacing: Math.round(Metrics.panelRowGapBase * root.uiScale)

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Settings (Placeholder)"
                color: Colors.text
                font.family: Fonts.text
                font.pixelSize: Math.round(13 * root.uiScale)
                font.bold: true
            }

            Item { Layout.fillWidth: true }

            Text {
                text: "close"
                color: Colors.subtext0
                font.family: Fonts.symbols
                font.pixelSize: Math.round(18 * root.uiScale)

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
            font.pixelSize: Math.round(11 * root.uiScale)
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Math.round(8 * root.uiScale)

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
            spacing: Math.round(6 * root.uiScale)

            Text {
                text: "Screen"
                color: Colors.subtext1
                font.family: Fonts.text
                font.pixelSize: Math.round(11 * root.uiScale)
            }

            Flow {
                Layout.fillWidth: true
                spacing: Math.round(6 * root.uiScale)

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
        implicitWidth: label.implicitWidth + Math.round(16 * root.uiScale)
        implicitHeight: Math.round(28 * root.uiScale)
        color: active ? Colors.blue : Colors.surface1

        Text {
            id: label
            anchors.centerIn: parent
            text: modeButton.text
            color: modeButton.active ? Colors.crust : Colors.text
            font.family: Fonts.text
            font.pixelSize: Math.round(11 * root.uiScale)
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
        implicitWidth: screenLabel.implicitWidth + Math.round(14 * root.uiScale)
        implicitHeight: Math.round(24 * root.uiScale)
        color: active ? Colors.teal : Colors.surface1

        Text {
            id: screenLabel
            anchors.centerIn: parent
            text: screenButton.screenName
            color: screenButton.active ? Colors.crust : Colors.text
            font.family: Fonts.text
            font.pixelSize: Math.round(10 * root.uiScale)
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
