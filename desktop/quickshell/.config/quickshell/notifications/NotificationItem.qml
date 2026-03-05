import QtQuick
import QtQuick.Layouts
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
    readonly property bool hasBodyText: notifBody.trim().length > 0
    readonly property bool centerCompactContent: !notifExpanded && !hasBodyText
    readonly property int actionRowHeight: notifExpanded ? Math.round(24 * root.notifUiScale) : 0
    readonly property int actionRowGap: notifExpanded ? Math.round(8 * root.notifUiScale) : 0
    readonly property int minContentHeight: Math.round(36 * root.notifUiScale)

    radius: Math.round(16 * root.notifUiScale)
    color: Colors.surface0
    border.width: Math.max(1, Math.round(root.notifUiScale))
    border.color: Colors.overlay0
    implicitHeight: Math.max(Math.max(contentColumn.implicitHeight, avatarFrame.implicitHeight), minContentHeight) + Math.round(16 * root.notifUiScale) + actionRowGap + actionRowHeight

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

            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(6 * root.notifUiScale)
                visible: root.notifExpanded

                Text {
                    text: root.notifAppName
                    color: Colors.subtext0
                    font.family: Fonts.text
                    font.pixelSize: Math.round(10 * root.notifUiScale)
                    font.bold: true
                }

                Text {
                    text: "•"
                    color: Colors.subtext0
                    font.pixelSize: Math.round(10 * root.notifUiScale)
                }

                Text {
                    text: root.notifAgeText
                    color: Colors.subtext0
                    font.family: Fonts.text
                    font.pixelSize: Math.round(10 * root.notifUiScale)
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(6 * root.notifUiScale)

                Text {
                    Layout.fillWidth: true
                    text: root.notifSummary
                    color: Colors.text
                    font.family: Fonts.text
                    font.pixelSize: Math.round(11 * root.notifUiScale)
                    font.bold: true
                    wrapMode: Text.WordWrap
                    maximumLineCount: root.notifExpanded ? 2 : 1
                    elide: Text.ElideRight
                }

                Text {
                    visible: !root.notifExpanded
                    text: "•"
                    color: Colors.subtext0
                    font.pixelSize: Math.round(10 * root.notifUiScale)
                }

                Text {
                    visible: !root.notifExpanded
                    text: root.notifAgeText
                    color: Colors.subtext0
                    font.family: Fonts.text
                    font.pixelSize: Math.round(10 * root.notifUiScale)
                }

            }

            Text {
                Layout.fillWidth: true
                visible: root.hasBodyText
                text: root.notifBody
                wrapMode: Text.WordWrap
                maximumLineCount: root.notifExpanded ? 8 : 1
                elide: Text.ElideRight
                color: Colors.subtext1
                font.family: Fonts.text
                font.pixelSize: Math.round(11 * root.notifUiScale)
            }
        }
    }

    Text {
        id: expandToggle
        anchors.top: parent.top
        anchors.topMargin: Math.round(8 * root.notifUiScale)
        anchors.right: parent.right
        anchors.rightMargin: Math.round(10 * root.notifUiScale)
        text: root.notifExpanded ? "expand_less" : "expand_more"
        color: Colors.subtext0
        font.family: Fonts.symbols
        font.pixelSize: Math.round(15 * root.notifUiScale)
        font.weight: 600

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
            color: root.notifHasPrimaryAction ? Colors.surface2 : Colors.surface1
            opacity: root.notifHasPrimaryAction ? 1 : 0.6

            Text {
                anchors.centerIn: parent
                text: "Go To App"
                color: Colors.text
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
            color: Colors.surface2

            Text {
                anchors.centerIn: parent
                text: "Close"
                color: Colors.text
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
