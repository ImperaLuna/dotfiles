pragma Singleton
import QtQuick

// Catppuccin Mocha
// To add a new theme: duplicate this file, swap the hex values,
// then update the singleton Colors.qml to point at the new palette.
QtObject {

    // ── Base ──────────────────────────────────────────────────────────────────
    readonly property color base:     "#1e1e2e"
    readonly property color mantle:   "#181825"
    readonly property color crust:    "#11111b"

    // ── Surface ───────────────────────────────────────────────────────────────
    readonly property color surface0: "#313244"
    readonly property color surface1: "#45475a"
    readonly property color surface2: "#585b70"

    // ── Overlay ───────────────────────────────────────────────────────────────
    readonly property color overlay0: "#6c7086"
    readonly property color overlay1: "#7f849c"
    readonly property color overlay2: "#9399b2"

    // ── Text ──────────────────────────────────────────────────────────────────
    readonly property color subtext0: "#a6adc8"
    readonly property color subtext1: "#bac2de"
    readonly property color text:     "#cdd6f4"

    // ── Accents ───────────────────────────────────────────────────────────────
    readonly property color rosewater: "#f5e0dc"
    readonly property color flamingo:  "#f2cdcd"
    readonly property color pink:      "#f5c2e7"
    readonly property color mauve:     "#cba6f7"
    readonly property color red:       "#f38ba8"
    readonly property color maroon:    "#eba0ac"
    readonly property color peach:     "#fab387"
    readonly property color yellow:    "#f9e2af"
    readonly property color green:     "#a6e3a1"
    readonly property color teal:      "#94e2d5"
    readonly property color sky:       "#89dceb"
    readonly property color sapphire:  "#74c7ec"
    readonly property color blue:      "#89b4fa"
    readonly property color lavender:  "#b4befe"

    readonly property color test:      "#ffffff"
}
