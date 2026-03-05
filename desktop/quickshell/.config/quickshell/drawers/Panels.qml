import QtQuick
import "./"
import "../notifications" as Notifications
import "../powermenu" as PowerMenu
import "../settings" as Settings

Item {
    id: root

    required property var screenModel
    required property var notificationService
    required property var notificationPlacement
    required property var allScreens
    required property bool notificationHost
    required property real resolutionScale
    required property int inset
    required property int cornerRadius
    required property int barCornerRadius
    required property int borderWidth
    required property color chromeColor
    required property bool powerMenuOpen
    required property bool notificationOpen
    required property bool settingsOpen

    signal togglePowerMenu()
    signal closePowerMenu()
    signal toggleNotification()
    signal closeNotification()
    signal toggleSettings()
    signal closeSettings()

    readonly property alias bar: bar
    readonly property alias powerMenu: powerMenu
    readonly property alias notifications: notifications
    readonly property alias settings: settings

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
        settingsOpen: root.settingsOpen
        onTogglePowerMenu: root.togglePowerMenu()
        onToggleSettings: root.toggleSettings()

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
        notificationService: root.notificationService
        notificationHost: root.notificationHost
        open: root.notificationOpen
        onCloseRequested: root.closeNotification()
        anchors {
            top: parent.top
            topMargin: root.inset + bar.implicitHeight
            right: parent.right
            rightMargin: root.inset + root.borderWidth
        }
    }

    Settings.Wrapper {
        id: settings
        open: root.settingsOpen
        placementConfig: root.notificationPlacement
        allScreens: root.allScreens
        onCloseRequested: root.closeSettings()
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
    }
}
