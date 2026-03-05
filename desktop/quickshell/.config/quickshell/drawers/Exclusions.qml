import Quickshell
import Quickshell.Wayland

// qmllint disable uncreatable-type
Scope {
    id: root

    required property var screenModel
    required property var geometry

    // Top reserved area (bar region)
    PanelWindow {
        screen: root.screenModel
        color: "transparent"
        implicitHeight: 1
        exclusiveZone: root.geometry.topReserved
        anchors {
            top: true
            left: true
            right: true
        }
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        focusable: false
    }

    // Left reserved area (frame width)
    PanelWindow {
        screen: root.screenModel
        color: "transparent"
        implicitWidth: 1
        exclusiveZone: root.geometry.leftReserved
        anchors {
            top: true
            bottom: true
            left: true
        }
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        focusable: false
    }

    // Right reserved area (frame width)
    PanelWindow {
        screen: root.screenModel
        color: "transparent"
        implicitWidth: 1
        exclusiveZone: root.geometry.rightReserved
        anchors {
            top: true
            bottom: true
            right: true
        }
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        focusable: false
    }

    // Bottom reserved area (frame width)
    PanelWindow {
        screen: root.screenModel
        color: "transparent"
        implicitHeight: 1
        exclusiveZone: root.geometry.bottomReserved
        anchors {
            bottom: true
            left: true
            right: true
        }
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        focusable: false
    }
}
