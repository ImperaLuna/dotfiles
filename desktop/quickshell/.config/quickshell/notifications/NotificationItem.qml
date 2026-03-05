import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root

    required property int notifIndex
    required property string notifAppName
    required property string notifAgeText
    required property string notifSummary
    required property string notifIconSource
    required property bool notifExpanded
    signal toggleRequested(int idx, bool value)
    signal dismissRequested(int idx)

    radius: 16
    color: Qt.alpha(Colors.mantle, 0.95)
    implicitHeight: contentColumn.implicitHeight + 16

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 8
        anchors.bottomMargin: 8
        spacing: 10

        Rectangle {
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: 30
            Layout.preferredHeight: 30
            radius: 15
            color: Colors.surface0
            clip: true

            Image {
                anchors.fill: parent
                visible: root.notifIconSource.length > 0
                source: root.notifIconSource
                asynchronous: true
                fillMode: Image.PreserveAspectCrop
            }
        }

        ColumnLayout {
            id: contentColumn
            Layout.fillWidth: true
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: root.notifAppName
                    color: Colors.text
                    font.family: Fonts.text
                    font.pixelSize: 11
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

                Item { Layout.fillWidth: true }

                Text {
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
            }

            Text {
                Layout.fillWidth: true
                text: root.notifSummary
                wrapMode: Text.WordWrap
                maximumLineCount: root.notifExpanded ? 8 : 1
                elide: Text.ElideRight
                color: Colors.subtext1
                font.family: Fonts.text
                font.pixelSize: 11
            }

            Rectangle {
                visible: root.notifExpanded
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 62
                implicitHeight: 24
                radius: 12
                color: Qt.alpha(Colors.overlay0, 0.22)

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
    }
}
