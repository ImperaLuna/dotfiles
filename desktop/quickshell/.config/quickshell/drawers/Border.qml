pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import "../theme"

Item {
    id: root

    required property var geometry
    required property int cornerRadius
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
            anchors.leftMargin: root.geometry.borderWidth
            anchors.rightMargin: root.geometry.borderWidth
            anchors.bottomMargin: root.geometry.borderWidth
            anchors.topMargin: root.geometry.barHeight
            radius: Math.max(0, root.cornerRadius)
            color: Colors.crust
        }
    }
}
