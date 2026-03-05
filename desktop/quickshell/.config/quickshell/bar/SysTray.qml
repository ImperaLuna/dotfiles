import QtQuick
import "../theme"

// TODO: wire up SystemTrayModel from Quickshell
Item {
    id: root
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight
    property real uiScale: 1.0
    property bool powerMenuOpen: false
    property bool settingsOpen: false
    signal togglePowerMenu()
    signal triggerTest()

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Math.round(8 * root.uiScale)

        Rectangle {
            id: testButton
            width: Math.round(22 * root.uiScale)
            height: Math.round(22 * root.uiScale)
            radius: Math.round(6 * root.uiScale)
            color: root.settingsOpen ? Colors.teal : (testArea.containsMouse ? Colors.teal : Colors.green)

            MouseArea {
                id: testArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.triggerTest()
            }

            Text {
                anchors.centerIn: parent
                text: "science"
                color: Colors.mantle
                font.family: Fonts.symbols
                font.pixelSize: Math.round(14 * root.uiScale)
                font.weight: 700
                renderType: Text.NativeRendering
            }
        }

        Item {
            id: powerMenuButton
            width: icon.implicitHeight + Math.round(2 * root.uiScale)
            height: icon.implicitHeight

            MouseArea {
                id: clickArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.togglePowerMenu()
            }

            Text {
                id: icon
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: -Math.round(root.uiScale)
                text: "power_settings_new"
                color: root.powerMenuOpen ? Colors.maroon : Colors.red
                opacity: clickArea.containsMouse ? 0.85 : 1.0
                font.family: Fonts.symbols
                font.pixelSize: Math.round(18 * root.uiScale)
                font.weight: 700
                renderType: Text.NativeRendering
            }
        }
    }
}
