pragma Singleton

import QtQuick
import Quickshell

// Colour and shape roles, from the active theme (services/Themes.qml).
Singleton {
    id: root

    readonly property var t: Themes.active
    readonly property var c: t.colors
    // Square, solid controls (Trench / Violet) instead of glass pills.
    readonly property bool square: t.square

    // ── Neutrals ────────────────────────────────────────────────────────
    readonly property color crust:    c.crust
    readonly property color base:     c.base
    readonly property color surface0: c.surface0
    readonly property color surface1: c.surface1
    readonly property color overlay:  c.overlay
    readonly property color subtext:  c.subtext
    readonly property color text:     c.text

    // ── Accents ─────────────────────────────────────────────────────────
    // accent: primary (active, selected, sliders, focus)
    // cyan:   connectivity, info, the logo
    // rose:   badges, highlights, live indicators
    readonly property color accent:  c.accent
    readonly property color cyan:    c.cyan
    readonly property color rose:    c.rose
    readonly property color warn:    c.warn
    readonly property color danger:  c.danger
    readonly property color success: c.success

    // ── Glass ───────────────────────────────────────────────────────────
    // Island fill; TideWM's layer_rule blur frosts what is behind it.
    readonly property real  glassOpacity: t.glass
    readonly property color glass:        alpha(base, glassOpacity)
    readonly property color glassStrong:  alpha(base, t.glassStrong)
    readonly property color hairline:     c.hairline
    readonly property color hover:        c.hover
    readonly property color accentSoft:   c.accentSoft
    readonly property color chip:         c.chip
    readonly property color controlEdge:  c.controlEdge
    readonly property int popupRadius: t.popupRadius
    readonly property int controlRadius: t.controlRadius

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
