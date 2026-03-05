import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root

    required property int notifIndex
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
    readonly property int actionRowHeight: notifExpanded ? 24 : 0
    readonly property int actionRowGap: notifExpanded ? 8 : 0

    radius: 16
    color: Colors.surface0
    border.width: 1
    border.color: Colors.overlay0
    implicitHeight: Math.max(contentColumn.implicitHeight, avatarFrame.implicitHeight) + 16 + actionRowGap + actionRowHeight

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 30
        anchors.topMargin: 8
        anchors.bottomMargin: 8 + root.actionRowGap + root.actionRowHeight
        spacing: 10

        Rectangle {
            id: avatarFrame
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: root.hasPreviewImage ? 44 : 30
            Layout.preferredHeight: root.hasPreviewImage ? 44 : 30
            radius: root.hasVisualIcon ? 0 : 15
            color: root.hasVisualIcon ? "transparent" : Colors.surface0
            border.width: root.hasVisualIcon ? 0 : 1
            border.color: Colors.overlay0
            clip: !root.hasVisualIcon

            Rectangle {
                anchors.fill: parent
                anchors.margins: 0
                radius: 0
                color: "transparent"
                clip: false
                visible: root.hasVisualIcon

                Image {
                    anchors.fill: parent
                    source: root.hasPreviewImage ? root.notifImageSource : root.notifIconSource
                    asynchronous: true
                    smooth: true
                    mipmap: true
                    fillMode: root.hasPreviewImage ? Image.PreserveAspectCrop : Image.PreserveAspectFit
                    scale: 1.0
                    transformOrigin: Item.Center
                }
            }

            Text {
                anchors.centerIn: parent
                visible: !root.hasVisualIcon
                text: "question_mark"
                color: Colors.text
                font.family: Fonts.symbols
                font.pixelSize: 20
                font.weight: 600
                renderType: Text.NativeRendering
            }
        }

        ColumnLayout {
            id: contentColumn
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                visible: root.notifExpanded

                Text {
                    text: root.notifAppName
                    color: Colors.subtext0
                    font.family: Fonts.text
                    font.pixelSize: 10
                    font.bold: true
                }

                Text {
                    text: "•"
                    color: Colors.subtext0
                    font.pixelSize: 10
                }

                Text {
                    text: root.notifAgeText
                    color: Colors.subtext0
                    font.family: Fonts.text
                    font.pixelSize: 10
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    Layout.fillWidth: true
                    text: root.notifSummary
                    color: Colors.text
                    font.family: Fonts.text
                    font.pixelSize: 11
                    font.bold: true
                    wrapMode: Text.WordWrap
                    maximumLineCount: root.notifExpanded ? 2 : 1
                    elide: Text.ElideRight
                }

                Text {
                    visible: !root.notifExpanded
                    text: "•"
                    color: Colors.subtext0
                    font.pixelSize: 10
                }

                Text {
                    visible: !root.notifExpanded
                    text: root.notifAgeText
                    color: Colors.subtext0
                    font.family: Fonts.text
                    font.pixelSize: 10
                }

            }

            Text {
                Layout.fillWidth: true
                visible: root.notifBody.length > 0
                text: root.notifBody
                wrapMode: Text.WordWrap
                maximumLineCount: root.notifExpanded ? 8 : 1
                elide: Text.ElideRight
                color: Colors.subtext1
                font.family: Fonts.text
                font.pixelSize: 11
            }
        }
    }

    Text {
        id: expandToggle
        anchors.top: parent.top
        anchors.topMargin: 8
        anchors.right: parent.right
        anchors.rightMargin: 10
        text: root.notifExpanded ? "expand_less" : "expand_more"
        color: Colors.subtext0
        font.family: Fonts.symbols
        font.pixelSize: 15
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
        spacing: 8
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter

        Rectangle {
            implicitWidth: 94
            implicitHeight: 24
            radius: 12
            color: root.notifHasPrimaryAction ? Colors.surface2 : Colors.surface1
            opacity: root.notifHasPrimaryAction ? 1 : 0.6

            Text {
                anchors.centerIn: parent
                text: "Go To App"
                color: Colors.text
                font.family: Fonts.text
                font.pixelSize: 11
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
            implicitWidth: 62
            implicitHeight: 24
            radius: 12
            color: Colors.surface2

            Text {
                anchors.centerIn: parent
                text: "Close"
                color: Colors.text
                font.family: Fonts.text
                font.pixelSize: 11
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
