pragma ComponentBehavior: Bound

import QtQuick

QtObject {
    id: root

    // Modes: "single" | "focused" | "all"
    property string mode: "single"
    // Used when mode === "single". Matches ShellScreen.name.
    property string screenName: ""

    function normalizedMode() {
        if (mode === "all" || mode === "focused" || mode === "single")
            return mode;
        return "single";
    }
}
