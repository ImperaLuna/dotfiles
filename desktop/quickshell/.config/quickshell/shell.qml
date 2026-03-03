import Quickshell
import Quickshell.Io
import "./bar"
import "./launcher"

ShellRoot {
    Launcher { id: launcher }

    IpcHandler {
        target: "launcher"
        function toggle() {
            launcher.visible = !launcher.visible
        }
    }

    Variants {
        model: Quickshell.screens
        Bar {
            required property var modelData
            screen: modelData
        }
    }
}
