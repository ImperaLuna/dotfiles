import QtQml

QtObject {
    id: root

    required property int inset
    required property int borderWidth
    required property int barHeight
    required property real rightPanelWidth
    required property real windowWidth
    required property real windowHeight

    readonly property int topReserved: inset + barHeight
    readonly property int leftReserved: inset + borderWidth
    readonly property int rightReserved: inset + borderWidth
    readonly property int bottomReserved: inset + borderWidth

    readonly property int interiorX: inset + borderWidth
    readonly property int interiorY: inset + barHeight
    readonly property real interiorWidth: Math.max(0, windowWidth - (inset + borderWidth) * 2 - rightPanelWidth)
    readonly property real interiorHeight: Math.max(0, windowHeight - inset - barHeight - borderWidth)

    readonly property int barStripX: inset
    readonly property int barStripY: inset
    readonly property real barStripWidth: Math.max(0, windowWidth - inset * 2)
    readonly property int barStripHeight: barHeight
}
