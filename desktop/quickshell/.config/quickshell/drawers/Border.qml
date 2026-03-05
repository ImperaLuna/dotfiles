pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects

Item {
    id: root

    required property int borderWidth
    required property int cornerRadius
    required property int barHeight
    required property int inset
    required property color borderColor

    anchors.fill: parent

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
            anchors.topMargin: root.barHeight
            radius: Math.max(0, root.cornerRadius)
            color: "black"
        }
    }
}
