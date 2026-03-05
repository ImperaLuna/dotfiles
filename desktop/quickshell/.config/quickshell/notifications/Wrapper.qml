pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../metrics"

Item {
    id: root

    required property var notificationService
    required property bool notificationHost
    required property real uiScale
    property bool open: false
    signal closeRequested()
    readonly property real nonAnimWidth: Math.round(Metrics.notifWidthBase * uiScale)
    readonly property int popupCount: (notificationHost && notificationService) ? notificationService.popupCount : 0
    readonly property bool hasVisiblePopups: popupCount > 0
    readonly property real nonAnimHeight: popupCount > 0 ? content.implicitHeight + Math.round(Metrics.panelOuterPaddingBase * 2 * uiScale) : 0

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
            duration: Metrics.animDurationMid
            easing.type: Easing.InOutCubic
        }
    }

    ColumnLayout {
        id: content
        anchors.top: parent.top
        anchors.topMargin: Math.round(Metrics.notifOuterPaddingBase * root.uiScale)
        anchors.left: parent.left
        anchors.leftMargin: Math.round(Metrics.notifOuterPaddingBase * root.uiScale)
        anchors.right: parent.right
        anchors.rightMargin: Math.round(Metrics.notifOuterPaddingBase * root.uiScale)
        spacing: Math.round(Metrics.notifCardGapBase * root.uiScale)

        Repeater {
            model: (root.notificationHost && root.notificationService) ? root.notificationService.model : null

            delegate: NotificationItem {
                id: notifItem
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
                Layout.preferredHeight: popup ? notifItem.implicitHeight : 0
                visible: popup
                notifIndex: index
                notifUiScale: root.uiScale
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
