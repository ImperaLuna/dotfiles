import Quickshell
import Quickshell.Wayland
import QtQuick
import "./"
import "../theme"

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
    property color borderColor: Colors.base

    Exclusions {
        screenModel: root.screenModel
        topReserved: root.inset + bar.implicitHeight
        sideReserved: root.inset + root.borderWidth
        bottomReserved: root.inset + root.borderWidth
    }

    // Caelestia-like composition: one window that owns bar + border.
    // This makes future top-edge dashboard slide panels straightforward.
    mask: Region {
        x: 0
        y: 0
        width: root.width
        height: root.height

        Region {
            x: root.inset + root.borderWidth
            y: root.inset + bar.implicitHeight
            width: Math.max(0, root.width - (root.inset + root.borderWidth) * 2)
            height: Math.max(0, root.height - root.inset - bar.implicitHeight - root.borderWidth)
            intersection: Intersection.Subtract
        }

        Region {
            x: root.inset
            y: root.inset
            width: Math.max(0, root.width - root.inset * 2)
            height: bar.implicitHeight
            intersection: Intersection.Combine
        }
    }

    BarWrapper {
        id: bar
        z: 2

        screenModel: root.screenModel
        resolutionScale: root.resolutionScale
        inset: root.inset
        cornerRadius: root.cornerRadius
        barCornerRadius: root.barCornerRadius

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: root.inset
            leftMargin: root.inset
            rightMargin: root.inset
        }
    }

    Border {
        id: border
        z: 1

        anchors.fill: parent
        anchors.margins: root.inset

        borderWidth: root.borderWidth
        cornerRadius: root.cornerRadius
        barHeight: bar.implicitHeight
        inset: root.inset
        borderColor: root.borderColor
    }
}
