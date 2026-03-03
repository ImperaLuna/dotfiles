import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import "../bar"
import "../theme"

PanelWindow {
    id: root

    required property var screenModel

    // Keep this as an independent layer entity so interactivity
    // (hover/click behaviors) can be added later.
    color: "transparent"
    exclusiveZone: 0

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    // Keep the frame above other shell surfaces (like the bar),
    // but mask it to a ring so center clicks still pass through.
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    focusable: false

    // Per-monitor sizing so mixed-resolution setups keep similar proportions.
    property real resolutionScale: Math.max(0.75, Math.min(1.5, screenModel.height / 1080))
    property int borderWidth: Math.max(1, Math.round(8 * resolutionScale))
    property int cornerRadius: Math.max(1, Math.round(12 * resolutionScale))
    // Outer frame offset from screen edge. Keep at 0 for full-screen margin.
    property int inset: 0
    property color borderColor: Colors.base
    property int barHeight: Math.max(24, Math.round(36 * resolutionScale))
    property int barInset: inset
    property int barPadding: Math.max(6, Math.round(12 * resolutionScale))
    property int sectionGap: Math.max(2, Math.round(4 * resolutionScale))

    mask: Region {
        x: 0
        y: 0
        width: root.width
        height: root.height

        // Keep edge ring clickable/visible and explicitly include the top bar strip.
        Region {
            // No top border: subtract from y=0 so only left/right/bottom remain.
            x: root.inset + root.borderWidth
            y: root.inset
            width: Math.max(0, root.width - (root.inset + root.borderWidth) * 2)
            height: Math.max(0, root.height - root.inset * 2 - root.borderWidth)
            intersection: Intersection.Subtract
        }

        Region {
            x: root.barInset
            y: root.inset
            width: Math.max(0, root.width - root.barInset * 2)
            height: root.barHeight
            intersection: Intersection.Combine
        }
    }

    Rectangle {
        id: bar
        z: 1
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: root.inset
            leftMargin: root.barInset
            rightMargin: root.barInset
        }
        height: root.barHeight
        color: Colors.base
        radius: 0
        bottomLeftRadius: root.cornerRadius
        bottomRightRadius: root.cornerRadius
        clip: true

        RowLayout {
            anchors {
                fill: parent
                leftMargin: root.barPadding
                rightMargin: root.barPadding
            }

            Workspaces {
                monitorName: root.screenModel.name
            }

            Scratchpad {
                Layout.leftMargin: root.sectionGap
            }

            Item { Layout.fillWidth: true }
            Clock {}
            Item { Layout.fillWidth: true }

            SysTray {}
        }

    }

    Item {
        id: frame
        z: 2
        anchors.fill: parent
        anchors.margins: root.inset

        Rectangle {
            id: borderFill
            anchors.fill: parent
            radius: 0
            color: root.borderColor
            antialiasing: true

            layer.enabled: true
            layer.effect: MultiEffect {
                maskSource: innerMask
                maskEnabled: true
                maskInverted: true
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1
            }
        }

        Item {
            id: innerMask
            anchors.fill: parent
            visible: false
            layer.enabled: true

            Rectangle {
                anchors.fill: parent
                anchors.leftMargin: root.borderWidth
                anchors.rightMargin: root.borderWidth
                anchors.bottomMargin: root.borderWidth
                anchors.topMargin: 0
                radius: Math.max(0, root.cornerRadius)
                color: "black"
            }
        }
    }
}
