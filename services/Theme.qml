pragma Singleton

import QtQuick
import Quickshell

// Shared roles for Trench / Violet and the original Abyssal Tide palette.
Singleton {
    id: root

    // ── Neutrals (navy slate pulled from the wallpapers) ────────────────
    readonly property bool trench: Appearance.preset === "trench-violet"
    readonly property color crust:    trench ? "#0e0917" : "#080b17"
    readonly property color base:     trench ? "#1b1328" : "#0c1020"
    readonly property color surface0: trench ? "#291c3b" : "#161b2e"
    readonly property color surface1: trench ? "#342447" : "#212841"
    readonly property color overlay:  trench ? "#a18bb5" : "#525c7e"
    readonly property color subtext:  trench ? "#c3b2d2" : "#9aa3c4"
    readonly property color text:     trench ? "#f1eaf7" : "#dde3f6"

    // ── Accents ─────────────────────────────────────────────────────────
    // violet: primary (active, selected, sliders, focus)
    // cyan:   connectivity, info, the logo
    // rose:   badges, highlights, live indicators
    readonly property color accent:  trench ? "#c5a5ef" : "#a98bff"
    readonly property color cyan:    trench ? "#94dbd7" : "#7fd6e6"
    readonly property color rose:    trench ? "#eea2c5" : "#f28fb0"
    readonly property color warn:    "#f5c27a"
    readonly property color danger:  "#ff7a95"
    readonly property color success: "#8be0b0"

    // ── Glass ───────────────────────────────────────────────────────────
    // Island fill; TideWM's layer_rule blur frosts what is behind it.
    readonly property real  glassOpacity: trench ? 0.94 : 0.72
    readonly property color glass:        alpha(base, glassOpacity)
    readonly property color glassStrong:  alpha(base, trench ? 0.98 : 0.88)
    readonly property color hairline:     trench ? "#574067" : alpha(text, 0.08)
    readonly property color hover:        trench ? "#3a2950" : alpha(text, 0.07)
    readonly property color accentSoft:   trench ? "#46305f" : alpha(accent, 0.16)
    readonly property color chip:         trench ? "#120d1c" : alpha(crust, 0.5)
    readonly property color controlEdge:  trench ? "#604678" : hairline
    readonly property int popupRadius: trench ? 12 : 22
    readonly property int controlRadius: trench ? 8 : 16

    // ── Type ────────────────────────────────────────────────────────────
    readonly property var availableFonts: Qt.fontFamilies()
    readonly property string monoFont: ["JetBrains Mono", "Noto Sans Mono", "DejaVu Sans Mono"].find(f => availableFonts.includes(f)) || "monospace"
    readonly property string font: Appearance.mono ? monoFont
        : availableFonts.includes("Noto Sans") ? "Noto Sans" : Qt.application.font.family
    readonly property int controlHeight: 32
    readonly property int controlFontSize: 12

    readonly property int anim: 160

    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a)
    }
}
