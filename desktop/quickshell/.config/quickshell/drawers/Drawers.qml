import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Shapes
import "./"
import "../notifications" as Notifications
import "../powermenu" as PowerMenu
import "../theme"

// qmllint disable uncreatable-type
PanelWindow {
    id: root

    required property var screenModel
    required property var notificationService
    required property var notificationPlacement
    required property var allScreens
    required property bool notificationHost

    color: "transparent"
    exclusiveZone: 0

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    focusable: false

    // Keep proportions consistent across mixed-resolution monitors.
    property real resolutionScale: Math.max(0.75, Math.min(1.5, screenModel.height / 1080))
    property int borderWidth: Math.max(1, Math.round(8 * resolutionScale))
    property int cornerRadius: Math.max(1, Math.round(12 * resolutionScale))
    // Lower = sharper corner attack angle, higher = rounder.
    property real barCornerFactor: 0.75
    property int barCornerRadius: Math.max(1, Math.round(cornerRadius * barCornerFactor))
    property int inset: 0
    property color chromeColor: Colors.base
    property bool powerMenuOpen: false
    property bool notificationOpen: false
    property bool settingsOpen: false
    readonly property real rightPanelWidth: Math.max(panels.powerMenu.width, panels.notifications.visible ? panels.notifications.width : 0)

    ChromeGeometry {
        id: geometry
        inset: root.inset
        borderWidth: root.borderWidth
        barHeight: panels.bar.implicitHeight
        rightPanelWidth: root.rightPanelWidth
        windowWidth: root.width
        windowHeight: root.height
    }

    Exclusions {
        screenModel: root.screenModel
        geometry: geometry
    }

    // Caelestia-like composition: one window that owns bar + border.
    mask: Region {
        x: 0
        y: 0
        width: root.width
        height: root.height

        Region {
            x: geometry.interiorX
            y: geometry.interiorY
            width: geometry.interiorWidth
            height: geometry.interiorHeight
            intersection: Intersection.Subtract
        }

        Region {
            x: geometry.barStripX
            y: geometry.barStripY
            width: geometry.barStripWidth
            height: geometry.barStripHeight
            intersection: Intersection.Combine
        }

        Region {
            x: panels.settings.x
            y: panels.settings.y
            width: panels.settings.visible ? panels.settings.width : 0
            height: panels.settings.visible ? panels.settings.height : 0
            intersection: Intersection.Combine
        }
    }

    Panels {
        id: panels
        z: 2

        screenModel: root.screenModel
        notificationService: root.notificationService
        notificationPlacement: root.notificationPlacement
        allScreens: root.allScreens
        notificationHost: root.notificationHost
        resolutionScale: root.resolutionScale
        inset: root.inset
        cornerRadius: root.cornerRadius
        barCornerRadius: root.barCornerRadius
        borderWidth: root.borderWidth
        chromeColor: root.chromeColor
        powerMenuOpen: root.powerMenuOpen
        notificationOpen: root.notificationOpen
        settingsOpen: root.settingsOpen
        onTogglePowerMenu: root.powerMenuOpen = !root.powerMenuOpen
        onClosePowerMenu: root.powerMenuOpen = false
        onToggleNotification: root.notificationOpen = !root.notificationOpen
        onCloseNotification: root.notificationOpen = false
        onToggleSettings: root.settingsOpen = !root.settingsOpen
        onCloseSettings: root.settingsOpen = false
    }

    Shape {
        id: panelBackgrounds
        z: 1.5

        anchors.fill: parent
        anchors.margins: root.inset + geometry.borderWidth
        preferredRendererType: Shape.CurveRenderer

        PowerMenu.Background {
            wrapper: panels.powerMenu
            rounding: Math.round(root.cornerRadius * 1.8)

            startX: panelBackgrounds.width
            startY: (panelBackgrounds.height - wrapper.height) / 2 - rounding
        }

        Notifications.Background {
            wrapper: panels.notifications
            rounding: Math.round(root.cornerRadius * 1.5)

            startX: panelBackgrounds.width
            startY: panels.notifications.y - (root.inset + geometry.borderWidth)
        }
    }

    Border {
        id: border
        z: 1

        anchors.fill: parent
        anchors.margins: root.inset

        geometry: geometry
        cornerRadius: root.cornerRadius
        borderColor: root.chromeColor
    }
}
