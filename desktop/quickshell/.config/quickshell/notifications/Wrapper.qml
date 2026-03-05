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

            delegate: Item {
                id: popupShell
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
                property real slideProgress: 0

                Layout.fillWidth: true
                Layout.preferredHeight: popup ? notifItem.implicitHeight : 0
                visible: popup || slideProgress > 0.01
                clip: true

                Item {
                    id: slideLayer
                    width: parent.width
                    height: notifItem.implicitHeight
                    opacity: 1
                    x: (1 - popupShell.slideProgress) * (parent.width * 0.8)

                    NotificationItem {
                        id: notifItem
                        anchors.fill: parent
                        notifIndex: popupShell.index
                        notifUiScale: root.uiScale
                        notifAppName: popupShell.sourceLine
                        notifAgeText: popupShell.ageText
                        notifSummary: popupShell.titleLine
                        notifBody: popupShell.body
                        notifIconSource: popupShell.iconSource
                        notifImageSource: popupShell.imageSource
                        notifHasPrimaryAction: popupShell.hasPrimaryAction
                        notifExpanded: popupShell.expanded
                        onToggleRequested: function(idx, value) { root.setExpanded(idx, value) }
                        onDismissRequested: function(idx) { root.dismissNotification(idx) }
                        onActivateRequested: function(idx) { root.notificationService.invokePrimaryAction(idx) }
                        onHoverChanged: function(idx, hovered) { root.setHovered(idx, hovered) }
                    }
                }

                onPopupChanged: {
                    if (popup) {
                        slideProgress = 0;
                        slideInAnim.restart();
                    } else {
                        slideOutAnim.restart();
                    }
                }

                Component.onCompleted: {
                    if (popup) {
                        slideProgress = 0;
                        slideInAnim.restart();
                    } else {
                        slideProgress = 0;
                    }
                }

                NumberAnimation {
                    id: slideInAnim
                    target: popupShell
                    property: "slideProgress"
                    from: 0
                    to: 1
                    duration: Metrics.animDurationSlow
                    easing.type: Easing.OutCubic
                }

                NumberAnimation {
                    id: slideOutAnim
                    target: popupShell
                    property: "slideProgress"
                    from: popupShell.slideProgress
                    to: 0
                    duration: Metrics.animDurationMid
                    easing.type: Easing.InCubic
                }
            }
        }
    }

    onPopupCountChanged: {
        if (root.popupCount === 0)
            root.closeRequested();
    }
}
