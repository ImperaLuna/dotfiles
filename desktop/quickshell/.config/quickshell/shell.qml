import Quickshell
import Quickshell.Io
import "./drawers"
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
        Drawers {
            required property var modelData
            screenModel: modelData
            screen: modelData
        }

    }

}
