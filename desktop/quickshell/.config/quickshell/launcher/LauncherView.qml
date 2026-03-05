pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Item {
    id: viewRoot

    property var results: []
    property alias currentIndex: listView.currentIndex
    property alias queryText: searchField.text
    readonly property bool listHasActiveFocus: listView.activeFocus
    readonly property int listViewportHeight: listView.height
    readonly property int rowHeight: 56
    readonly property int maxVisibleRows: 7
    readonly property int frameMargins: 24
    readonly property int columnSpacing: 8
    readonly property int searchHeight: 42
    readonly property int maxListHeight: rowHeight * maxVisibleRows
    readonly property int targetListHeight: Math.min(maxListHeight, Math.max(0, results.length) * rowHeight)
    property real animatedListHeight: targetListHeight
    readonly property int preferredHeight: Math.round(frameMargins + columnSpacing + searchHeight + animatedListHeight)
    readonly property int maxHeight: Math.round(frameMargins + columnSpacing + searchHeight + maxListHeight)

    Behavior on animatedListHeight {
        NumberAnimation {
            duration: 210
            easing.type: Easing.OutCubic
        }
    }

    signal launchRequested(var entry)
    signal escapeRequested()
    signal stepRequested(int direction, bool keepInputFocus)
    signal pageRequested(int direction)
    signal queryChanged(string text)

    property point lastPointerGlobalPos: Qt.point(-1, -1)

    function pointerActuallyMoved(globalPos) {
        if (globalPos.x !== viewRoot.lastPointerGlobalPos.x || globalPos.y !== viewRoot.lastPointerGlobalPos.y) {
            viewRoot.lastPointerGlobalPos = globalPos
            return true
        }
        return false
    }

    function shouldSelectFromHover(globalPos, fullyVisible) {
        return pointerActuallyMoved(globalPos) && !listView.moving && fullyVisible
    }

    function focusList() {
        listView.forceActiveFocus()
    }

    function focusSearch() {
        searchField.forceActiveFocus()
    }

    function resetPointerTracking() {
        viewRoot.lastPointerGlobalPos = Qt.point(-1, -1)
    }

    function positionAtIndex(index, mode) {
        listView.positionViewAtIndex(index, mode)
    }

    function ensureIndexVisible(index) {
        if (index < 0)
            return

        const itemHeight = rowHeight
        const top = listView.contentY
        const bottom = top + listView.height
        const itemTop = index * itemHeight
        const itemBottom = itemTop + itemHeight

        if (itemTop < top) {
            listView.positionViewAtIndex(index, ListView.Beginning)
        } else if (itemBottom > bottom) {
            listView.positionViewAtIndex(index, ListView.End)
        }
    }

    Rectangle {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: viewRoot.preferredHeight
        color: Colors.base
        radius: 12
        border.color: Colors.surface1
        border.width: 1

        ColumnLayout {
            anchors {
                fill: parent
                margins: 12
            }
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: viewRoot.searchHeight
                color: Colors.mantle
                radius: 8

                TextField {
                    id: searchField
                    anchors {
                        fill: parent
                        leftMargin: 12
                        rightMargin: 12
                    }
                    placeholderText: "Search applications or type math…"
                    background: null
                    color: Colors.text
                    placeholderTextColor: Colors.overlay0
                    font.pixelSize: 14
                    font.family: Fonts.text

                    onTextChanged: viewRoot.queryChanged(text)

                    Keys.onUpPressed: viewRoot.stepRequested(-1, true)
                    Keys.onDownPressed: viewRoot.stepRequested(1, true)

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            viewRoot.escapeRequested()
                            event.accepted = true
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            if (listView.currentIndex >= 0 && listView.currentIndex < viewRoot.results.length)
                                viewRoot.launchRequested(viewRoot.results[listView.currentIndex])
                            else if (viewRoot.results.length > 0)
                                viewRoot.launchRequested(viewRoot.results[0])
                            event.accepted = true
                        } else if (event.modifiers & Qt.ControlModifier) {
                            if (event.key === Qt.Key_J) {
                                viewRoot.stepRequested(1, true)
                                event.accepted = true
                            } else if (event.key === Qt.Key_K) {
                                viewRoot.stepRequested(-1, true)
                                event.accepted = true
                            } else if (event.key === Qt.Key_D) {
                                viewRoot.pageRequested(1)
                                event.accepted = true
                            } else if (event.key === Qt.Key_U) {
                                viewRoot.pageRequested(-1)
                                event.accepted = true
                            } else {
                                event.accepted = false
                            }
                        } else {
                            event.accepted = false
                        }
                    }
                }
            }

            ListView {
                id: listView
                Layout.fillWidth: true
                Layout.preferredHeight: Math.round(viewRoot.animatedListHeight)
                model: viewRoot.results
                clip: true
                boundsBehavior: Flickable.DragAndOvershootBounds
                maximumFlickVelocity: 3000
                flickDeceleration: 8500
                keyNavigationEnabled: false
                keyNavigationWraps: false
                reuseItems: true
                cacheBuffer: 560
                preferredHighlightBegin: 0
                preferredHighlightEnd: height
                highlightRangeMode: ListView.NoHighlightRange
                highlightFollowsCurrentItem: false
                highlightMoveDuration: 90
                highlightResizeDuration: 90

                rebound: Transition {
                    NumberAnimation {
                        properties: "x,y"
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    id: scrollBar
                    property bool showWhileScrolling: false

                    visible: listView.contentHeight > listView.height
                    policy: ScrollBar.AsNeeded
                    active: showWhileScrolling || pressed
                    width: 10
                    padding: 2

                    Connections {
                        target: listView

                        function onMovingChanged() {
                            if (listView.moving) {
                                fadeOutTimer.stop()
                                scrollBar.showWhileScrolling = true
                            } else {
                                fadeOutTimer.restart()
                            }
                        }
                    }

                    Timer {
                        id: fadeOutTimer
                        interval: 650
                        onTriggered: scrollBar.showWhileScrolling = false
                    }

                    background: Rectangle {
                        radius: 999
                        color: Colors.surface0
                        opacity: (scrollBar.size < 1 && scrollBar.showWhileScrolling) ? 0.4 : 0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 420
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    contentItem: Rectangle {
                        radius: 999
                        color: Colors.overlay0
                        opacity: {
                            if (scrollBar.size >= 1)
                                return 0
                            if (scrollBar.pressed)
                                return 0.95
                            if (scrollBar.showWhileScrolling)
                                return 0.8
                            return 0
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 420
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }

                add: Transition {
                    NumberAnimation {
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: 130
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        property: "y"
                        from: 10
                        duration: 130
                        easing.type: Easing.OutCubic
                    }
                }

                remove: Transition {
                    NumberAnimation {
                        property: "opacity"
                        from: 1
                        to: 0
                        duration: 110
                        easing.type: Easing.InOutCubic
                    }
                    NumberAnimation {
                        property: "scale"
                        from: 1
                        to: 0.985
                        duration: 110
                        easing.type: Easing.InOutCubic
                    }
                }

                move: Transition {
                    NumberAnimation {
                        property: "y"
                        duration: 170
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        property: "opacity"
                        to: 1
                        duration: 120
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        property: "scale"
                        to: 1
                        duration: 150
                        easing.type: Easing.OutCubic
                    }
                }

                addDisplaced: Transition {
                    NumberAnimation {
                        property: "y"
                        duration: 170
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        property: "opacity"
                        to: 1
                        duration: 120
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        property: "scale"
                        to: 1
                        duration: 150
                        easing.type: Easing.OutCubic
                    }
                }

                displaced: Transition {
                    NumberAnimation {
                        property: "y"
                        duration: 170
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        property: "opacity"
                        to: 1
                        duration: 120
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        property: "scale"
                        to: 1
                        duration: 150
                        easing.type: Easing.OutCubic
                    }
                }

                Keys.onUpPressed: viewRoot.stepRequested(-1, false)
                Keys.onDownPressed: viewRoot.stepRequested(1, false)

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        viewRoot.escapeRequested()
                        event.accepted = true
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        if (currentIndex >= 0 && currentIndex < viewRoot.results.length)
                            viewRoot.launchRequested(viewRoot.results[currentIndex])
                        event.accepted = true
                    } else if (event.modifiers & Qt.ControlModifier) {
                        if (event.key === Qt.Key_J) {
                            viewRoot.stepRequested(1, false)
                            event.accepted = true
                        } else if (event.key === Qt.Key_K) {
                            viewRoot.stepRequested(-1, false)
                            event.accepted = true
                        } else if (event.key === Qt.Key_D) {
                            viewRoot.pageRequested(1)
                            event.accepted = true
                        } else if (event.key === Qt.Key_U) {
                            viewRoot.pageRequested(-1)
                            event.accepted = true
                        } else {
                            event.accepted = false
                        }
                    } else {
                        event.accepted = false
                    }
                }

                delegate: Rectangle {
                    id: appItem
                    required property var modelData
                    required property int index

                    property var entry: modelData

                    function fullyVisibleInList() {
                        const viewportY = appItem.y - listView.contentY
                        return viewportY >= 0 && (viewportY + appItem.height) <= listView.height
                    }

                    width: listView.width
                    height: viewRoot.rowHeight
                    color: "transparent"
                    radius: 6

                    Rectangle {
                        anchors.fill: parent
                        radius: 6
                        color: Colors.surface0
                        opacity: listView.currentIndex === appItem.index ? 1 : 0
                    }

                    Row {
                        anchors {
                            verticalCenter: parent.verticalCenter
                            left: parent.left
                            leftMargin: 8
                            right: parent.right
                            rightMargin: 8
                        }
                        spacing: 12

                        Item {
                            width: 36
                            height: 36
                            anchors.verticalCenter: parent.verticalCenter

                            Image {
                                id: themeIcon
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                mipmap: true
                                source: ((appItem.entry.icon_name ?? "") !== ""
                                    && !(appItem.entry.icon_name ?? "").startsWith("/")
                                    && !((appItem.entry.icon ?? "").startsWith("/")))
                                    ? "image://icon/" + appItem.entry.icon_name
                                    : ""
                                visible: status === Image.Ready
                            }

                            Image {
                                id: fileIcon
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                mipmap: true
                                source: ((appItem.entry.icon ?? "").startsWith("/"))
                                    ? "file://" + appItem.entry.icon
                                    : ""
                                visible: status === Image.Ready
                            }

                            Rectangle {
                                anchors.fill: parent
                                visible: themeIcon.status !== Image.Ready && !fileIcon.visible
                                radius: 6
                                color: Colors.surface1

                                Text {
                                    anchors.centerIn: parent
                                    text: "\u25A1"
                                    color: Colors.overlay0
                                    font.pixelSize: 16
                                }
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            width: parent.width - 48

                            Text {
                                text: appItem.entry.name ?? ""
                                color: Colors.text
                                font.pixelSize: 14
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Text {
                                text: appItem.entry.description ?? ""
                                color: Colors.subtext0
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                width: parent.width
                                visible: (appItem.entry.description ?? "") !== ""
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: {
                            const gpos = mapToGlobal(mouseX, mouseY)
                            if (viewRoot.shouldSelectFromHover(gpos, appItem.fullyVisibleInList()))
                                listView.currentIndex = appItem.index
                        }
                        onPositionChanged: mouse => {
                            const gpos = mapToGlobal(mouse.x, mouse.y)
                            if (viewRoot.shouldSelectFromHover(gpos, appItem.fullyVisibleInList()))
                                listView.currentIndex = appItem.index
                        }
                        onPressed: {
                            viewRoot.lastPointerGlobalPos = mapToGlobal(mouseX, mouseY)
                            listView.currentIndex = appItem.index
                        }
                        onClicked: viewRoot.launchRequested(appItem.entry)
                    }
                }
            }
        }
    }
}
