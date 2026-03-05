import QtQuick
import "../theme"

// TODO: wire up SystemTrayModel from Quickshell
Item {
    id: root
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight
    property bool sessionOpen: false
    signal toggleSession()
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
            color: testArea.containsMouse ? Colors.teal : Colors.green

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
                font.family: "Material Symbols Rounded"
                font.pixelSize: 14
                font.weight: 700
                renderType: Text.NativeRendering
            }
        }

        Item {
            id: sessionButton
            width: icon.implicitHeight + 2
            height: icon.implicitHeight

            MouseArea {
                id: clickArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggleSession()
            }

            Text {
                id: icon
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: -1
                text: "power_settings_new"
                color: root.sessionOpen ? Colors.maroon : Colors.red
                opacity: clickArea.containsMouse ? 0.85 : 1.0
                font.family: "Material Symbols Rounded"
                font.pixelSize: 18
                font.weight: 700
                renderType: Text.NativeRendering
            }
        }
    }
}
