import QtQuick
import "../theme"

Text {
    color: Colors.text
    font.family: "JetBrainsMono Nerd Font"
    font.pixelSize: 12

    property var now: new Date()
    text: Qt.formatDateTime(now, "hh:mm")

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: parent.now = new Date()
    }
}
