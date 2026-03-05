import Quickshell
import Quickshell.Wayland

// qmllint disable uncreatable-type
Scope {
    id: root

    required property var screenModel
    required property int topReserved
    required property int leftReserved
    required property int rightReserved
    required property int bottomReserved

    // Top reserved area (bar region)
    PanelWindow {
        screen: root.screenModel
        color: "transparent"
        implicitHeight: 1
        exclusiveZone: root.topReserved
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
        exclusiveZone: root.leftReserved
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
        exclusiveZone: root.rightReserved
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
        exclusiveZone: root.bottomReserved
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
