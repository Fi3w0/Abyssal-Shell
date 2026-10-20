pragma Singleton

import QtQuick
import Quickshell

// Abyssal Tide palette and shared look values. Bind to these, never hardcode
// a colour in a widget.
Singleton {
    id: root

    // ── Neutrals (navy slate pulled from the wallpapers) ────────────────
    readonly property color crust:    "#080b17"
    readonly property color base:     "#0c1020"
    readonly property color surface0: "#161b2e"
    readonly property color surface1: "#212841"
    readonly property color overlay:  "#525c7e"
    readonly property color subtext:  "#9aa3c4"
    readonly property color text:     "#dde3f6"

    // ── Accents ─────────────────────────────────────────────────────────
    // violet: primary (active, selected, sliders, focus)
    // cyan:   connectivity, info, the logo
    // rose:   badges, highlights, live indicators
    readonly property color accent:  "#a98bff"
    readonly property color cyan:    "#7fd6e6"
    readonly property color rose:    "#f28fb0"
    readonly property color warn:    "#f5c27a"
    readonly property color danger:  "#ff7a95"
    readonly property color success: "#8be0b0"

    // ── Glass ───────────────────────────────────────────────────────────
    // Island fill; TideWM's layer_rule blur frosts what is behind it.
    readonly property real  glassOpacity: 0.72
    readonly property color glass:        alpha(base, glassOpacity)
    readonly property color glassStrong:  alpha(base, 0.88)
    readonly property color hairline:     alpha(text, 0.08)
    readonly property color hover:        alpha(text, 0.07)
    readonly property color accentSoft:   alpha(accent, 0.16)
    readonly property color chip:         alpha(crust, 0.5)

    // ── Type ────────────────────────────────────────────────────────────
    readonly property string font: "JetBrains Mono"

    readonly property int anim: 160

    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a)
    }
}
