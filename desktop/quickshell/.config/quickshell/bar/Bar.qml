import Quickshell
import QtQuick
import QtQuick.Layouts
import "../theme"

// qmllint disable uncreatable-type
PanelWindow {
    id: root

    // Keep in sync with border/ScreenBorder.qml borderWidth.
    property int frameInset: 8

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 36 + frameInset
    exclusiveZone: implicitHeight
    color: "transparent"

    Rectangle {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: root.frameInset
            leftMargin: root.frameInset
            rightMargin: root.frameInset
        }
        height: 36
        color: Colors.base

        RowLayout {
            anchors {
                fill: parent
                leftMargin: 12
                rightMargin: 12
            }

            // ── Left: workspaces ──────────────────────────────────────────────
            Workspaces {
                monitorName: root.screen.name
            }

            Scratchpad {
                Layout.leftMargin: 4
            }

            // ── Center: clock ─────────────────────────────────────────────────
            Item { Layout.fillWidth: true }
            Clock {}
            Item { Layout.fillWidth: true }

            // ── Right: system tray ────────────────────────────────────────────
            SysTray {}
        }
    }
}
