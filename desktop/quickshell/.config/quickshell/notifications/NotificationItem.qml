import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import "../metrics"
import "../theme"

Rectangle {
    id: root

    required property int notifIndex
    required property real notifUiScale
    required property string notifAppName
    required property string notifAgeText
    required property string notifSummary
    required property string notifBody
    required property string notifIconSource
    required property string notifImageSource
    required property bool notifHasPrimaryAction
    required property bool notifExpanded
    signal toggleRequested(int idx, bool value)
    signal dismissRequested(int idx)
    signal activateRequested(int idx)
    signal hoverChanged(int idx, bool hovered)
    readonly property bool hasPreviewImage: notifImageSource.length > 0
    readonly property bool hasAppIcon: notifIconSource.length > 0
    readonly property bool hasVisualIcon: hasPreviewImage || hasAppIcon
    readonly property bool hasBodyText: String(notifBody ?? "").length > 0
    readonly property bool centerCompactContent: !notifExpanded && !hasBodyText
    readonly property int actionRowHeight: notifExpanded ? Math.round(24 * root.notifUiScale) : 0
    readonly property int actionRowGap: notifExpanded ? Math.round(8 * root.notifUiScale) : 0
    readonly property int minContentHeight: Math.round(36 * root.notifUiScale)
    readonly property int bottomSafeGap: Math.round(12 * root.notifUiScale)
    readonly property int expandedBodyNaturalHeight: root.hasBodyText ? Math.round(bodyText.implicitHeight) : 0
    readonly property int expandedContentNaturalHeight: headerBlock.implicitHeight
            + (root.hasBodyText ? (expandedBodyNaturalHeight + contentColumn.spacing) : 0)
    readonly property int naturalImplicitHeight: (root.notifExpanded
            ? Math.max(Math.max(expandedContentNaturalHeight, avatarFrame.implicitHeight), minContentHeight)
            : Math.max(Math.max(contentColumn.implicitHeight, avatarFrame.implicitHeight), minContentHeight))
            + Math.round(16 * root.notifUiScale) + actionRowGap + actionRowHeight
    readonly property int availableDrawerHeight: {
        const _trackY = root.y;
        const itemPos = root.mapToItem(null, 0, 0);
        const windowHeight = Window.height > 0 ? Window.height : 1080;
        const availableUntilBottom = windowHeight - itemPos.y - root.bottomSafeGap;
        return Math.max(Math.round(120 * root.notifUiScale), Math.floor(availableUntilBottom));
    }
    // Notification Center Drawer: activated only when expanded content would
    // otherwise overflow the bottom safe boundary.
    readonly property bool notificationCenterDrawer: root.notifExpanded && naturalImplicitHeight > availableDrawerHeight
    readonly property int drawerReservedHeight: headerBlock.implicitHeight
            + Math.round(20 * root.notifUiScale) // card vertical paddings
            + Math.round(4 * root.notifUiScale)  // header/body spacing
            + root.actionRowGap
            + root.actionRowHeight
    readonly property int drawerBodyHeight: Math.max(Math.round(64 * root.notifUiScale), availableDrawerHeight - drawerReservedHeight)

    radius: Math.round(16 * root.notifUiScale)
    color: Colors.surface0
    border.width: Math.max(1, Math.round(root.notifUiScale))
    border.color: Colors.overlay0
    implicitHeight: notificationCenterDrawer ? availableDrawerHeight : naturalImplicitHeight

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Math.round(12 * root.notifUiScale)
        anchors.rightMargin: Math.round(30 * root.notifUiScale)
        anchors.topMargin: Math.round(7 * root.notifUiScale)
        anchors.bottomMargin: Math.round(9 * root.notifUiScale) + root.actionRowGap + root.actionRowHeight
        spacing: Math.round(10 * root.notifUiScale)

        Rectangle {
            id: avatarFrame
            Layout.alignment: root.centerCompactContent ? Qt.AlignVCenter : Qt.AlignTop
            Layout.preferredWidth: root.hasPreviewImage ? Math.round(36 * root.notifUiScale) : Math.round(30 * root.notifUiScale)
            Layout.preferredHeight: root.hasPreviewImage ? Math.round(36 * root.notifUiScale) : Math.round(30 * root.notifUiScale)
            radius: root.hasPreviewImage ? Math.round(9 * root.notifUiScale) : Math.round(15 * root.notifUiScale)
            color: root.hasVisualIcon ? "transparent" : Colors.surface0
            border.width: root.hasVisualIcon ? 0 : 1
            border.color: Colors.overlay0
            clip: true

            Image {
                anchors.fill: parent
                source: root.hasPreviewImage ? root.notifImageSource : root.notifIconSource
                asynchronous: true
                smooth: true
                mipmap: true
                fillMode: root.hasPreviewImage ? Image.PreserveAspectCrop : Image.PreserveAspectFit
                sourceSize.width: Math.round(width * 2)
                sourceSize.height: Math.round(height * 2)
                visible: root.hasVisualIcon
            }

            Text {
                anchors.centerIn: parent
                visible: !root.hasVisualIcon
                text: "question_mark"
                color: Colors.text
                font.family: Fonts.symbols
                font.pixelSize: Math.round(20 * root.notifUiScale)
                font.weight: 600
                renderType: Text.NativeRendering
            }
        }

        ColumnLayout {
            id: contentColumn
            Layout.fillWidth: true
            Layout.alignment: root.centerCompactContent ? Qt.AlignVCenter : Qt.AlignTop
            spacing: 4

            Item {
                id: headerBlock
                Layout.fillWidth: true
                implicitHeight: root.notifExpanded ? appName.implicitHeight + summary.implicitHeight + Math.round(2 * root.notifUiScale) : summary.implicitHeight
                // Keep text + time metadata inside a safe right bound so nothing
                // collides with the expand toggle.
                readonly property int rightTextEdge: Math.round(width - 10 * root.notifUiScale)
                readonly property int titleGap: Math.round(6 * root.notifUiScale)

                Text {
                    id: appName
                    anchors.top: parent.top
                    anchors.left: parent.left
                    width: root.notifExpanded
                           ? Math.max(0, headerBlock.rightTextEdge - appName.x)
                           : appNameMetrics.elideWidth
                    text: root.notifExpanded ? root.notifAppName : appNameMetrics.elidedText
                    color: Colors.subtext0
                    font.family: Fonts.text
                    font.pixelSize: Math.round(10 * root.notifUiScale)
                    font.bold: true
                    maximumLineCount: 1
                    elide: root.notifExpanded ? Text.ElideNone : Text.ElideRight
                    opacity: root.notifExpanded ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Metrics.animDurationMid
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                TextMetrics {
                    id: appNameMetrics
                    text: root.notifAppName
                    font.family: appName.font.family
                    font.pixelSize: appName.font.pixelSize
                    elide: Text.ElideRight
                    elideWidth: Math.max(0, rightMeta.x - appName.x - headerBlock.titleGap)
                }

                TextMetrics {
                    id: appNameRawMetrics
                    text: root.notifAppName
                    font.family: appName.font.family
                    font.pixelSize: appName.font.pixelSize
                }

                Text {
                    id: summary
                    anchors.top: parent.top
                    anchors.left: parent.left
                    width: root.notifExpanded
                           ? Math.max(0, headerBlock.rightTextEdge - summary.x)
                           : summaryMetrics.elideWidth
                    text: root.notifExpanded ? root.notifSummary : summaryMetrics.elidedText
                    color: Colors.text
                    font.family: Fonts.text
                    font.pixelSize: Math.round(11 * root.notifUiScale)
                    font.bold: true
                    wrapMode: Text.WordWrap
                    maximumLineCount: root.notifExpanded ? 0 : 1
                    elide: root.notifExpanded ? Text.ElideNone : Text.ElideRight
                }

                TextMetrics {
                    id: summaryMetrics
                    text: root.notifSummary
                    font.family: summary.font.family
                    font.pixelSize: summary.font.pixelSize
                    elide: Text.ElideRight
                    elideWidth: Math.max(0, rightMeta.x - summary.x - headerBlock.titleGap)
                }

                TextMetrics {
                    id: summaryRawMetrics
                    text: root.notifSummary
                    font.family: summary.font.family
                    font.pixelSize: summary.font.pixelSize
                }

                Item {
                    id: rightMeta
                    width: timeSep.implicitWidth + Math.round(4 * root.notifUiScale) + timeText.implicitWidth
                    implicitHeight: Math.max(timeSep.implicitHeight, timeText.implicitHeight)
                    readonly property int desiredX: {
                        const base = root.notifExpanded ? appName : summary;
                        const rawWidth = root.notifExpanded ? appNameRawMetrics.width : summaryRawMetrics.width;
                        return Math.round(base.x + rawWidth + headerBlock.titleGap);
                    }
                    readonly property int maxX: Math.max(0, headerBlock.rightTextEdge - width)
                    x: Math.min(maxX, desiredX)
                    y: root.notifExpanded ? appName.y : summary.y

                    Behavior on x {
                        NumberAnimation {
                            duration: Metrics.animDurationMid
                            easing.type: Easing.InOutCubic
                        }
                    }

                    Behavior on y {
                        NumberAnimation {
                            duration: Metrics.animDurationMid
                            easing.type: Easing.InOutCubic
                        }
                    }

                    Text {
                        id: timeSep
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "•"
                        color: Colors.subtext0
                        font.pixelSize: Math.round(10 * root.notifUiScale)
                    }

                    Text {
                        id: timeText
                        anchors.left: timeSep.right
                        anchors.leftMargin: Math.round(4 * root.notifUiScale)
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.notifAgeText
                        color: Colors.subtext0
                        font.family: Fonts.text
                        font.pixelSize: Math.round(10 * root.notifUiScale)
                    }
                }

                states: State {
                    name: "expanded"
                    when: root.notifExpanded

                    AnchorChanges {
                        target: summary
                        anchors.top: appName.bottom
                    }
                }

                transitions: Transition {
                    AnchorAnimation {
                        duration: Metrics.animDurationMid
                        easing.type: Easing.InOutCubic
                    }
                }
            }

            Item {
                id: bodyContainer
                Layout.fillWidth: true
                visible: root.hasBodyText
                readonly property bool bodyOverflow: root.notificationCenterDrawer && bodyText.implicitHeight > root.drawerBodyHeight
                implicitHeight: root.notifExpanded
                                ? (root.notificationCenterDrawer ? Math.min(bodyText.implicitHeight, root.drawerBodyHeight) : bodyText.implicitHeight)
                                : bodyText.implicitHeight
                clip: true

                Flickable {
                    id: bodyFlick
                    anchors.fill: parent
                    clip: true
                    contentWidth: width
                    contentHeight: bodyText.implicitHeight
                    interactive: root.notifExpanded && bodyContainer.bodyOverflow
                    boundsBehavior: Flickable.StopAtBounds

                    Text {
                        id: bodyText
                        width: bodyFlick.width
                        text: root.notifBody
                        wrapMode: Text.WordWrap
                        maximumLineCount: root.notifExpanded ? 0 : 1
                        elide: root.notifExpanded ? Text.ElideNone : Text.ElideRight
                        color: Colors.subtext1
                        font.family: Fonts.text
                        font.pixelSize: Math.round(11 * root.notifUiScale)
                    }

                    ScrollBar.vertical: ScrollBar {
                        policy: root.notifExpanded && bodyContainer.bodyOverflow ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                        width: Math.max(4, Math.round(4 * root.notifUiScale))
                        contentItem: Rectangle {
                            implicitWidth: parent.width
                            radius: width / 2
                            color: Colors.overlay1
                            opacity: 0.75
                        }
                        background: Rectangle {
                            radius: width / 2
                            color: Colors.surface1
                            opacity: 0.35
                        }
                    }
                }
            }
        }
    }

    Text {
        id: expandToggle
        anchors.top: parent.top
        anchors.topMargin: Math.round(8 * root.notifUiScale)
        anchors.right: parent.right
        anchors.rightMargin: Math.round(10 * root.notifUiScale)
        text: "expand_more"
        color: Colors.subtext0
        font.family: Fonts.symbols
        font.pixelSize: Math.round(15 * root.notifUiScale)
        font.weight: 600
        rotation: root.notifExpanded ? 180 : 0
        transformOrigin: Item.Center

        Behavior on rotation {
            NumberAnimation {
                duration: Metrics.animDurationMid
                easing.type: Easing.InOutCubic
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggleRequested(root.notifIndex, !root.notifExpanded)
        }
    }

    Row {
        id: actionsRow
        visible: root.notifExpanded
        spacing: Math.round(8 * root.notifUiScale)
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.round(8 * root.notifUiScale)
        anchors.horizontalCenter: parent.horizontalCenter

        Rectangle {
            implicitWidth: Math.round(94 * root.notifUiScale)
            implicitHeight: Math.round(24 * root.notifUiScale)
            radius: Math.round(12 * root.notifUiScale)
            color: root.notifHasPrimaryAction ? Colors.blue : Colors.surface1
            opacity: root.notifHasPrimaryAction ? 1 : 0.6

            Text {
                anchors.centerIn: parent
                text: "Open"
                color: root.notifHasPrimaryAction ? Colors.base : Colors.text
                font.family: Fonts.text
                font.pixelSize: Math.round(11 * root.notifUiScale)
            }

            MouseArea {
                anchors.fill: parent
                enabled: root.notifHasPrimaryAction
                hoverEnabled: true
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.activateRequested(root.notifIndex)
            }
        }

        Rectangle {
            implicitWidth: Math.round(62 * root.notifUiScale)
            implicitHeight: Math.round(24 * root.notifUiScale)
            radius: Math.round(12 * root.notifUiScale)
            color: Colors.red

            Text {
                anchors.centerIn: parent
                text: "Close"
                color: Colors.base
                font.family: Fonts.text
                font.pixelSize: Math.round(11 * root.notifUiScale)
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.dismissRequested(root.notifIndex)
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        onEntered: root.hoverChanged(root.notifIndex, true)
        onExited: root.hoverChanged(root.notifIndex, false)
    }
}
