pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../theme"

Item {
    id: root

    property bool open: false
    signal closeRequested()
    readonly property real nonAnimWidth: 320
    readonly property real nonAnimHeight: content.implicitHeight + 24

    function dismissNotification(idx) {
        notifModel.remove(idx, 1)
        if (notifModel.count === 0)
            root.closeRequested()
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

        Repeater {
            model: ListModel {
                id: notifModel

                ListElement {
                    appName: "grimblast"
                    ageText: "now"
                    summary: "Area copied to buffer and saved to /tmp/screenshots/screenshot-2026-03-05.png"
                    iconSource: ""
                    expanded: false
                }
                ListElement {
                    appName: "Discord"
                    ageText: "now"
                    summary: "New direct message from luna: can you review the drawer behavior before merge?"
                    iconSource: ""
                    expanded: true
                }
            }

            delegate: Rectangle {
                required property int index
                required property string appName
                required property string ageText
                required property string summary
                required property string iconSource
                required property bool expanded

                Layout.fillWidth: true
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
                        width: 30
                        height: 30
                        radius: 15
                        color: Colors.surface0
                        clip: true

                        Image {
                            anchors.fill: parent
                            visible: iconSource.length > 0
                            source: iconSource
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
                                text: appName
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
                                text: ageText
                                color: Colors.subtext0
                                font.family: Fonts.text
                                font.pixelSize: 10
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: expanded ? "expand_less" : "expand_more"
                                color: Colors.subtext0
                                font.family: Fonts.symbols
                                font.pixelSize: 15
                                font.weight: 600

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: notifModel.setProperty(index, "expanded", !expanded)
                                }
                            }
                        }

                        Text {
                            id: summaryText
                            Layout.fillWidth: true
                            text: summary
                            wrapMode: Text.WordWrap
                            maximumLineCount: expanded ? 8 : 1
                            elide: Text.ElideRight
                            color: Colors.subtext1
                            font.family: Fonts.text
                            font.pixelSize: 11
                        }

                        Rectangle {
                            visible: expanded
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
                                onClicked: root.dismissNotification(index)
                            }
                        }
                    }
                }
            }
        }
    }
}
