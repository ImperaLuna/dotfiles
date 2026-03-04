import QtQuick
import "./"

Item {
    id: root

    required property var screenModel
    required property real resolutionScale
    required property int inset
    required property int cornerRadius
    required property int barCornerRadius
    required property int borderWidth
    required property bool sessionOpen

    signal toggleSession()
    signal closeSession()

    readonly property alias bar: bar
    readonly property alias session: session

    anchors.fill: parent

    BarWrapper {
        id: bar

        screenModel: root.screenModel
        resolutionScale: root.resolutionScale
        inset: root.inset
        cornerRadius: root.cornerRadius
        barCornerRadius: root.barCornerRadius
        sessionOpen: root.sessionOpen
        onToggleSession: root.toggleSession()

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: root.inset
            leftMargin: root.inset
            rightMargin: root.inset
        }
    }

    SessionDrawer {
        id: session
        open: root.sessionOpen
        onCloseRequested: root.closeSession()
        anchors {
            right: parent.right
            rightMargin: root.inset + root.borderWidth
            verticalCenter: parent.verticalCenter
        }
    }
}
