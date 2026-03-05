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
    required property color barColor

    readonly property int barHeight: Math.max(20, Math.round(Metrics.barHeightBase * resolutionScale))
    readonly property int barPadding: Math.max(6, Math.round(Metrics.barPaddingBase * resolutionScale))
    readonly property int sectionGap: Math.max(2, Math.round(Metrics.sectionGapBase * resolutionScale))
    property bool powerMenuOpen: false
    property bool notificationOpen: false
    signal togglePowerMenu()
    signal toggleNotification()

    implicitHeight: barHeight

    Rectangle {
        id: bar
        anchors.fill: parent
        color: root.barColor
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
            spacing: root.sectionGap

            Workspaces {
                monitorName: root.screenModel.name
                uiScale: root.resolutionScale
            }

            Scratchpad {
                Layout.leftMargin: root.sectionGap
                uiScale: root.resolutionScale
            }

            Item { Layout.fillWidth: true }

            Clock {
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            SysTray {
                Layout.alignment: Qt.AlignVCenter
                powerMenuOpen: root.powerMenuOpen
                notificationOpen: root.notificationOpen
                onTogglePowerMenu: root.togglePowerMenu()
                onTriggerTest: root.toggleNotification()
            }
        }
    }
}
