import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Shapes
import "./"
import "../theme"

// qmllint disable uncreatable-type
PanelWindow {
    id: root

    required property var screenModel

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
    property color chromeColor: "#ffffff"
    property bool sessionOpen: false
    property bool notificationOpen: false
    readonly property real rightPanelWidth: Math.max(panels.session.width, panels.notifications.visible ? panels.notifications.width : 0)

    Exclusions {
        screenModel: root.screenModel
        topReserved: root.inset + panels.bar.implicitHeight
        leftReserved: root.inset + root.borderWidth
        rightReserved: root.inset + root.borderWidth
        bottomReserved: root.inset + root.borderWidth
    }

    // Caelestia-like composition: one window that owns bar + border.
    mask: Region {
        x: 0
        y: 0
        width: root.width
        height: root.height

        Region {
            x: root.inset + root.borderWidth
            y: root.inset + panels.bar.implicitHeight
            width: Math.max(0, root.width - (root.inset + root.borderWidth) * 2 - root.rightPanelWidth)
            height: Math.max(0, root.height - root.inset - panels.bar.implicitHeight - root.borderWidth)
            intersection: Intersection.Subtract
        }

        Region {
            x: root.inset
            y: root.inset
            width: Math.max(0, root.width - root.inset * 2)
            height: panels.bar.implicitHeight
            intersection: Intersection.Combine
        }
    }

    Panels {
        id: panels
        z: 2

        screenModel: root.screenModel
        resolutionScale: root.resolutionScale
        inset: root.inset
        cornerRadius: root.cornerRadius
        barCornerRadius: root.barCornerRadius
        borderWidth: root.borderWidth
        chromeColor: root.chromeColor
        sessionOpen: root.sessionOpen
        notificationOpen: root.notificationOpen
        onToggleSession: root.sessionOpen = !root.sessionOpen
        onCloseSession: root.sessionOpen = false
        onToggleNotification: root.notificationOpen = !root.notificationOpen
        onCloseNotification: root.notificationOpen = false
    }

    Shape {
        id: panelBackgrounds
        z: 1.5

        anchors.fill: parent
        anchors.margins: root.inset + root.borderWidth
        preferredRendererType: Shape.CurveRenderer

        SessionBackground {
            wrapper: panels.session
            rounding: Math.round(root.cornerRadius * 1.8)

            startX: panelBackgrounds.width
            startY: (panelBackgrounds.height - wrapper.height) / 2 - rounding
        }

        NotificationBackground {
            wrapper: panels.notifications
            rounding: Math.round(root.cornerRadius * 1.5)

            startX: panelBackgrounds.width
            startY: panels.notifications.y - (root.inset + root.borderWidth) - rounding
        }
    }

    Border {
        id: border
        z: 1

        anchors.fill: parent
        anchors.margins: root.inset

        borderWidth: root.borderWidth
        cornerRadius: root.cornerRadius
        barHeight: panels.bar.implicitHeight
        inset: root.inset
        borderColor: root.chromeColor
    }
}
