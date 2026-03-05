pragma Singleton
import QtQuick

QtObject {
    // Base sizing tokens for shell UI.
    readonly property int barHeightBase: 26
    readonly property int barPaddingBase: 12
    readonly property int sectionGapBase: 4
    readonly property int workspacePillHeightBase: 20
    readonly property int workspacePillMinWidthBase: 28
    readonly property int workspacePillPadXBase: 14
    readonly property int workspaceFontBase: 10
    readonly property int scratchpadGlyphNudgeX: 0

    // Launcher
    readonly property int launcherWidthBase: 640
    readonly property int launcherRowHeightBase: 56
    readonly property int launcherMaxVisibleRowsBase: 7
    readonly property int launcherFrameMarginsBase: 24
    readonly property int launcherColumnGapBase: 8
    readonly property int launcherSearchHeightBase: 42
    readonly property int launcherRadiusBase: 12
    readonly property int launcherInnerRadiusBase: 8
    readonly property int launcherIconSizeBase: 36
    readonly property int launcherTitleFontBase: 14
    readonly property int launcherSubtitleFontBase: 11

    // Notifications
    readonly property int notifWidthBase: 360
    readonly property int notifOuterPaddingBase: 12
    readonly property int notifCardGapBase: 10

    // Settings / panels
    readonly property int settingsWidthBase: 360
    readonly property int panelOuterPaddingBase: 12
    readonly property int panelCornerRadiusBase: 16
    readonly property int panelRowGapBase: 10

    // Power menu
    readonly property int powerMenuWidthBase: 176

    // Animation timings (ms)
    readonly property int animDurationFast: 120
    readonly property int animDurationButton: 140
    readonly property int animDurationMid: 170
    readonly property int animDurationPanel: 180
    readonly property int animDurationLayout: 210
    readonly property int animDurationRebound: 220
    readonly property int animDurationSlow: 420
    readonly property int animDurationItemIn: 130
    readonly property int animDurationItemOut: 110
    readonly property int animDurationItemSettle: 150
}
