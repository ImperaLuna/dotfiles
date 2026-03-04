import Quickshell
import QtQuick
import "../theme"

// TODO: wire up SystemTrayModel from Quickshell
Item {
    id: root
    implicitWidth: icon.implicitHeight + 6
    implicitHeight: icon.implicitHeight
    property bool sessionOpen: false
    signal toggleSession()

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
        color: sessionOpen ? Colors.maroon : Colors.red
        opacity: clickArea.containsMouse ? 0.85 : 1.0
        font.family: "Material Symbols Rounded"
        font.pixelSize: 18
        font.weight: 700
        renderType: Text.NativeRendering
    }
}
