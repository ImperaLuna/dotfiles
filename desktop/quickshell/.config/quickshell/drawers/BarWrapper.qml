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

    readonly property int barHeight: Math.max(20, Math.round(Metrics.barHeightBase * resolutionScale))
    readonly property int barPadding: Math.max(6, Math.round(Metrics.barPaddingBase * resolutionScale))
    readonly property int sectionGap: Math.max(2, Math.round(Metrics.sectionGapBase * resolutionScale))
    property bool sessionOpen: false
    signal toggleSession()

    implicitHeight: barHeight

    Rectangle {
        id: bar
        anchors.fill: parent
        color: Colors.base
        radius: 0
        topLeftRadius: root.barCornerRadius
        topRightRadius: root.barCornerRadius
        clip: false

        RowLayout {
            anchors {
                fill: parent
                leftMargin: root.barPadding
                rightMargin: root.barPadding
            }

            Workspaces {
                monitorName: root.screenModel.name
                uiScale: root.resolutionScale
            }

            Scratchpad {
                Layout.leftMargin: root.sectionGap
                uiScale: root.resolutionScale
            }

            Item { Layout.fillWidth: true }
            Clock {}
            Item { Layout.fillWidth: true }

            SysTray {
                sessionOpen: root.sessionOpen
                onToggleSession: root.toggleSession()
                onTriggerTest: console.log("Notification test button pressed")
            }
        }
    }
}
