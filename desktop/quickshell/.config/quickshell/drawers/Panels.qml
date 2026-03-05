import QtQuick
import "./"
import "../notifications" as Notifications
import "../powermenu" as PowerMenu

Item {
    id: root

    required property var screenModel
    required property real resolutionScale
    required property int inset
    required property int cornerRadius
    required property int barCornerRadius
    required property int borderWidth
    required property color chromeColor
    required property bool powerMenuOpen
    required property bool notificationOpen

    signal togglePowerMenu()
    signal closePowerMenu()
    signal toggleNotification()
    signal closeNotification()

    readonly property alias bar: bar
    readonly property alias powerMenu: powerMenu
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
        powerMenuOpen: root.powerMenuOpen
        notificationOpen: root.notificationOpen
        onTogglePowerMenu: root.togglePowerMenu()
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

    PowerMenu.Wrapper {
        id: powerMenu
        open: root.powerMenuOpen
        onCloseRequested: root.closePowerMenu()
        anchors {
            right: parent.right
            rightMargin: root.inset + root.borderWidth
            verticalCenter: parent.verticalCenter
        }
    }

    Notifications.Wrapper {
        id: notifications
        open: root.notificationOpen
        onCloseRequested: root.closeNotification()
        anchors {
            top: parent.top
            topMargin: root.inset + bar.implicitHeight
            right: parent.right
            rightMargin: root.inset + root.borderWidth
        }
    }
}
