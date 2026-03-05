pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "./drawers"
import "./launcher"
import "./notifications"

ShellRoot {
    id: root

    Launcher { id: launcher }
    NotificationService { id: notifService }
    PlacementConfig { id: notifPlacement }

    function isNotificationHost(screenModel) {
        const mode = notifPlacement.normalizedMode();

        if (mode === "all")
            return true;

        if (mode === "focused") {
            const focusedName = String(Hyprland.focusedMonitor?.name ?? "");
            if (focusedName.length > 0)
                return screenModel.name === focusedName;
        } else if (mode === "single") {
            const targetName = notifPlacement.screenName.trim();
            if (targetName.length > 0)
                return screenModel.name === targetName;
        }

        return Quickshell.screens.length > 0 && screenModel === Quickshell.screens[0];
    }

    IpcHandler {
        target: "launcher"
        function toggle() {
            launcher.visible = !launcher.visible
        }
    }

    IpcHandler {
        target: "notifications"

        function setPlacementMode(mode) {
            notifPlacement.mode = String(mode ?? "single").toLowerCase();
        }

        function setPlacementScreen(screenName) {
            notifPlacement.screenName = String(screenName ?? "");
        }

        function getPlacementMode() {
            return notifPlacement.normalizedMode();
        }

        function getPlacementScreen() {
            return notifPlacement.screenName;
        }
    }

    Variants {
        model: Quickshell.screens
        Drawers {
            required property var modelData
            screenModel: modelData
            screen: modelData
            notificationService: notifService
            notificationPlacement: notifPlacement
            allScreens: Quickshell.screens
            notificationHost: root.isNotificationHost(modelData)
        }

    }

}
