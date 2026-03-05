pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property bool open: false
    signal closeRequested()
    readonly property real nonAnimWidth: 320
    readonly property real nonAnimHeight: content.implicitHeight + 24

    function dismissNotification(idx) {
        notifs.remove(idx, 1)
        if (notifs.count === 0)
            root.closeRequested()
    }

    function setExpanded(idx, value) {
        notifs.setProperty(idx, "expanded", value)
    }

    visible: height > 0
    width: nonAnimWidth
    height: open ? nonAnimHeight : 0
    clip: true

    Behavior on height {
        NumberAnimation {
            duration: 170
            easing.type: Easing.InOutCubic
        }
    }

    ColumnLayout {
        id: content
        anchors.top: parent.top
        anchors.topMargin: 12
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 12
        spacing: 10

        NotifModel {
            id: notifs
        }

        Repeater {
            model: notifs

            delegate: NotificationItem {
                required property int index
                required property string appName
                required property string ageText
                required property string summary
                required property string iconSource
                required property bool expanded

                Layout.fillWidth: true
                notifIndex: index
                notifAppName: appName
                notifAgeText: ageText
                notifSummary: summary
                notifIconSource: iconSource
                notifExpanded: expanded
                onToggleRequested: function(idx, value) { root.setExpanded(idx, value) }
                onDismissRequested: function(idx) { root.dismissNotification(idx) }
            }
        }
    }
}
