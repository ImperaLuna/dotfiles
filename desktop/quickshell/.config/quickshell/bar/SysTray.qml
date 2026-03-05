import QtQuick
import "../theme"

// TODO: wire up SystemTrayModel from Quickshell
Item {
    id: root
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight
    property bool powerMenuOpen: false
    property bool notificationOpen: false
    signal togglePowerMenu()
    signal triggerTest()

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8

        Rectangle {
            id: testButton
            width: 22
            height: 22
            radius: 6
            color: root.notificationOpen ? Colors.teal : (testArea.containsMouse ? Colors.teal : Colors.green)

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
                font.pixelSize: 14
                font.weight: 700
                renderType: Text.NativeRendering
            }
        }

        Item {
            id: powerMenuButton
            width: icon.implicitHeight + 2
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
                anchors.horizontalCenterOffset: -1
                text: "power_settings_new"
                color: root.powerMenuOpen ? Colors.maroon : Colors.red
                opacity: clickArea.containsMouse ? 0.85 : 1.0
                font.family: Fonts.symbols
                font.pixelSize: 18
                font.weight: 700
                renderType: Text.NativeRendering
            }
        }
    }
}
