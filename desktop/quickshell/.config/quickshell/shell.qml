pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import "./drawers"
import "./launcher"
import "./notifications"

ShellRoot {
    id: root

    readonly property string runtimeScriptPath: Qt.resolvedUrl("./launcher/runtime-config.py").toString().replace(/^file:\/\//, "")

    QtObject {
        id: uiSettings
        property real scale: 1.0
    }

    property bool uiScaleLoaded: false

    Launcher {
        id: launcher
        globalUiScale: uiSettings.scale
    }
    NotificationService { id: notifService }
    PlacementConfig { id: notifPlacement }

    Process {
        id: uiScaleLoad
        command: ["python3", root.runtimeScriptPath, "--get-ui-scale"]

        stdout: SplitParser {
            onRead: function (line) {
                const parsed = Number(line.trim());
                if (!Number.isFinite(parsed))
                    return;
                uiSettings.scale = Math.max(0.75, Math.min(2.5, parsed));
            }
        }

        onRunningChanged: {
            if (!running)
                root.uiScaleLoaded = true;
        }
    }

    Timer {
        id: uiScaleSaveDebounce
        interval: 160
        repeat: false
        onTriggered: Quickshell.execDetached(["python3", root.runtimeScriptPath, "--set-ui-scale", String(uiSettings.scale)])
    }

    Connections {
        target: uiSettings
        function onScaleChanged() {
            if (root.uiScaleLoaded)
                uiScaleSaveDebounce.restart();
        }
    }

    Component.onCompleted: uiScaleLoad.running = true

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

        function setPlacementMode(mode: string): void {
            notifPlacement.mode = String(mode).toLowerCase();
        }

        function setPlacementScreen(screenName: string): void {
            notifPlacement.screenName = String(screenName);
        }

        function getPlacementMode(): string {
            return notifPlacement.normalizedMode();
        }

        function getPlacementScreen(): string {
            return notifPlacement.screenName;
        }
    }

    Variants {
        model: Quickshell.screens
        Drawers {
            required property var modelData
            screenModel: modelData
            screen: modelData
            uiSettings: uiSettings
            notificationService: notifService
            notificationPlacement: notifPlacement
            allScreens: Quickshell.screens
            notificationHost: root.isNotificationHost(modelData)
        }

    }

}
