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
    required property color chromeColor
    required property bool sessionOpen
    required property bool notificationOpen

    signal toggleSession()
    signal closeSession()
    signal toggleNotification()
    signal closeNotification()

    readonly property alias bar: bar
    readonly property alias session: session
    readonly property alias notifications: notifications

    anchors.fill: parent

    BarWrapper {
        id: bar

        screenModel: root.screenModel
        resolutionScale: root.resolutionScale
        inset: root.inset
        cornerRadius: root.cornerRadius
        barCornerRadius: root.barCornerRadius
        barColor: root.chromeColor
        sessionOpen: root.sessionOpen
        notificationOpen: root.notificationOpen
        onToggleSession: root.toggleSession()
        onToggleNotification: root.toggleNotification()

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

    NotificationDrawer {
        id: notifications
        open: root.notificationOpen
        onCloseRequested: root.closeNotification()
        anchors {
            top: parent.top
            topMargin: root.inset + root.borderWidth + bar.implicitHeight
            right: parent.right
            rightMargin: root.inset + root.borderWidth
        }
    }
}
