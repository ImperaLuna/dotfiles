import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "../theme"

PanelWindow {
    id: root

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 36
    exclusiveZone: implicitHeight
    color: "transparent"

    Rectangle {
        anchors.fill: parent
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
