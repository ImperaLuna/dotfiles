pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var notificationService
    required property bool notificationHost
    property bool open: false
    signal closeRequested()
    readonly property real nonAnimWidth: 320
    readonly property int popupCount: (notificationHost && notificationService) ? notificationService.popupCount : 0
    readonly property bool hasVisiblePopups: popupCount > 0
    readonly property real nonAnimHeight: popupCount > 0 ? content.implicitHeight + 24 : 0

    function dismissNotification(idx) {
        notificationService.dismissByIndex(idx)
    }

    function setExpanded(idx, value) {
        notificationService.setExpanded(idx, value)
    }

    function setHovered(idx, hovered) {
        notificationService.setHovered(idx, hovered)
    }

    visible: height > 0
    width: nonAnimWidth
    height: (open || hasVisiblePopups) && hasVisiblePopups ? nonAnimHeight : 0
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

        Repeater {
            model: (root.notificationHost && root.notificationService) ? root.notificationService.model : null

            delegate: NotificationItem {
                required property int index
                required property string appName
                required property string ageText
                required property string sourceLine
                required property string titleLine
                required property string previewLine
                required property string summary
                required property string body
                required property string iconSource
                required property string imageSource
                required property bool hasPrimaryAction
                required property bool expanded
                required property bool popup

                Layout.fillWidth: true
                Layout.preferredHeight: popup ? implicitHeight : 0
                visible: popup
                notifIndex: index
                notifAppName: sourceLine
                notifAgeText: ageText
                notifSummary: titleLine
                notifBody: previewLine
                notifIconSource: iconSource
                notifImageSource: imageSource
                notifHasPrimaryAction: hasPrimaryAction
                notifExpanded: expanded
                onToggleRequested: function(idx, value) { root.setExpanded(idx, value) }
                onDismissRequested: function(idx) { root.dismissNotification(idx) }
                onActivateRequested: function(idx) { root.notificationService.invokePrimaryAction(idx) }
                onHoverChanged: function(idx, hovered) { root.setHovered(idx, hovered) }
            }
        }
    }

    onPopupCountChanged: {
        if (root.popupCount === 0)
            root.closeRequested();
    }
}
