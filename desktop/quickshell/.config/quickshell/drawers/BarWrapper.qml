import QtQuick
import QtQuick.Layouts
import "../bar"
import "../theme"

Item {
    id: root

    required property var screenModel
    required property real resolutionScale
    required property int inset
    required property int cornerRadius
    required property int barCornerRadius

    readonly property int barHeight: Math.max(24, Math.round(36 * resolutionScale))
    readonly property int barPadding: Math.max(6, Math.round(12 * resolutionScale))
    readonly property int sectionGap: Math.max(2, Math.round(4 * resolutionScale))

    implicitHeight: barHeight

    Rectangle {
        id: bar
        anchors.fill: parent
        color: Colors.base
        radius: 0
        topLeftRadius: root.barCornerRadius
        topRightRadius: root.barCornerRadius
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
}
