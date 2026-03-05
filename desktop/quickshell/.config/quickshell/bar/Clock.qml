import QtQuick
import "../theme"

Text {
    property real uiScale: 1.0
    color: Colors.text
    font.family: Fonts.text
    font.pixelSize: Math.round(12 * uiScale)

    property var now: new Date()
    text: Qt.formatDateTime(now, "hh:mm")

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: parent.now = new Date()
    }
}
