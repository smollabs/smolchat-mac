pragma Singleton
import QtQuick

// Design tokens for SmolChat. Neutral greys, one restrained accent,
// macOS system typography. `dark` is bound to the user's setting in main.qml.
QtObject {
    id: theme

    property bool dark: true

    // Surfaces
    readonly property color bg:            dark ? "#212121" : "#ffffff"
    readonly property color sidebar:       dark ? "#171717" : "#f9f9f9"
    readonly property color surface:       dark ? "#2a2a2a" : "#f4f4f4"
    readonly property color surfaceRaised: dark ? "#2f2f2f" : "#ffffff"
    readonly property color popup:         dark ? "#262626" : "#ffffff"
    readonly property color userBubble:    dark ? "#303030" : "#f1f1f1"
    readonly property color codeBg:        dark ? "#171717" : "#f6f7f8"
    readonly property color codeHeader:    dark ? "#232323" : "#eceef0"
    readonly property color hover:         dark ? "#2a2a2a" : "#ececec"
    readonly property color hoverStrong:   dark ? "#333333" : "#e3e3e3"
    readonly property color selected:      dark ? "#2f2f2f" : "#e8e8e8"
    readonly property color overlay:       dark ? "#99000000" : "#40000000"
    readonly property color splashBg:      "#0e0e10"

    // Lines
    readonly property color border:        dark ? "#33ffffff" : "#1f000000"
    readonly property color borderSubtle:  dark ? "#1affffff" : "#14000000"

    // Text
    readonly property color text:          dark ? "#ececec" : "#0d0d0d"
    readonly property color textSecondary: dark ? "#b4b4b4" : "#5d5d5d"
    readonly property color textTertiary:  dark ? "#8e8e8e" : "#8f8f8f"
    readonly property color textOnAccent:  dark ? "#0d0d0d" : "#ffffff"

    // Accents
    readonly property color accent:        dark ? "#ececec" : "#0d0d0d"   // primary buttons
    readonly property color accentMuted:   dark ? "#676767" : "#d7d7d7"
    readonly property color brand:         "#7aa2ff"                       // focus/progress
    readonly property color success:       dark ? "#4ade80" : "#16a34a"
    readonly property color warning:       dark ? "#fbbf24" : "#b45309"
    readonly property color danger:        dark ? "#f87171" : "#dc2626"
    readonly property color dangerBg:      dark ? "#2a1515" : "#fdecec"

    // Typography
    readonly property string fontFamily: Qt.platform.os === "osx" ? ".AppleSystemUIFont" : "Helvetica Neue"
    readonly property string monoFamily: Qt.platform.os === "osx" ? "Menlo" : "monospace"
    readonly property int fontXs: 11
    readonly property int fontSm: 12
    readonly property int fontMd: 14
    readonly property int fontLg: 16
    readonly property int fontXl: 22
    readonly property int fontHero: 28

    // Shape & spacing
    readonly property int radiusSm: 6
    readonly property int radiusMd: 10
    readonly property int radiusLg: 16
    readonly property int radiusXl: 24
    readonly property int contentWidth: 768
    readonly property int sidebarWidth: 260

    // Motion
    readonly property int fast: 120
    readonly property int normal: 200
    readonly property int slow: 350
}
