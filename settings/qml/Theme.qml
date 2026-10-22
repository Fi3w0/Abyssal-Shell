pragma Singleton
import QtQuick

QtObject {
    id: root
    property int revision: 0
    property Connections watcher: Connections {
        target: Store
        function onChanged() { root.revision++; }
    }
    function setting(key, fallback) {
        revision;
        return Store.value("settings", key, Store.value("theme:" + themeId, "settingsLook." + key, fallback));
    }
    readonly property string themeId: {
        revision;
        return Store.value("appearance", "theme", "abyssal-tide");
    }
    readonly property var theme: {
        revision;
        return Store.themes.find(t => t.id === themeId) || Store.themes[0] || {};
    }
    readonly property var colors: theme.colors || {}
    // The platform palette is the fallback for incomplete or missing themes.
    property SystemPalette platform: SystemPalette {}
    property color crust: colors.crust || platform.window
    property color base: colors.base || platform.window
    property color surface0: colors.surface0 || platform.base
    property color surface1: colors.surface1 || platform.alternateBase
    property color overlay: colors.overlay || platform.mid
    property color subtext: colors.subtext || platform.placeholderText
    property color text: colors.text || platform.windowText
    property color accent: colors.accent || platform.highlight
    property color cyan: colors.cyan || accent
    property color rose: colors.rose || accent
    property color warn: colors.warn || accent
    property color danger: colors.danger || accent
    property color success: colors.success || accent
    property color glow: ({cyan: cyan, accent: accent, rose: rose})[setting("glowSource", "cyan")] || cyan
    readonly property color edge: colors.hairline || alpha(text, 0.09)
    readonly property color glass: alpha(text, setting("glass", 3) / 100)
    readonly property color deep: colors.chip || alpha(crust, 0.7)
    readonly property color bar: alpha(crust, 0.8)
    readonly property color side: alpha(crust, 0.4)
    readonly property color glowSoft: colors.accentSoft || alpha(glow, setting("glowStrength", 15) / 100)
    readonly property color glowEdge: colors.controlEdge || alpha(glow, 0.33)
    readonly property color backdropTop: {
        revision;
        return Store.value("theme:" + themeId, "backdrop.top", colors.backdropTop || Qt.lighter(mix(base, glow, 0.14), 1.06));
    }
    readonly property real density: ({compact: 0.8, normal: 1, roomy: 1.25})[setting("density", "normal")] || 1
    readonly property bool square: {
        revision;
        return Store.value("theme:" + themeId, "shape", "pill") === "square";
    }
    readonly property real radius: square ? 3 : 7
    readonly property real groupRadius: square ? 3 : 10
    readonly property bool corners: setting("corners", true)
    readonly property bool reduceMotion: setting("reduceMotion", false)
    readonly property int duration: reduceMotion ? 80 : 160
    readonly property var fonts: Qt.fontFamilies()
    readonly property string fontFamily: {
        const preferred = setting("font", "JetBrains Mono");
        return fonts.includes(preferred) ? preferred : "monospace";
    }
    function alpha(value, opacity) {
        const c = Qt.color(value);
        return Qt.rgba(c.r, c.g, c.b, opacity);
    }
    function mix(a, b, amount) {
        return Qt.rgba(a.r * (1 - amount) + b.r * amount,
                       a.g * (1 - amount) + b.g * amount,
                       a.b * (1 - amount) + b.b * amount, 1);
    }
    Behavior on crust { ColorAnimation { duration: root.reduceMotion ? 80 : 300 } }
    Behavior on base { ColorAnimation { duration: root.reduceMotion ? 80 : 300 } }
    Behavior on surface0 { ColorAnimation { duration: root.reduceMotion ? 80 : 300 } }
    Behavior on surface1 { ColorAnimation { duration: root.reduceMotion ? 80 : 300 } }
    Behavior on overlay { ColorAnimation { duration: root.reduceMotion ? 80 : 300 } }
    Behavior on text { ColorAnimation { duration: root.reduceMotion ? 80 : 300 } }
    Behavior on subtext { ColorAnimation { duration: root.reduceMotion ? 80 : 300 } }
    Behavior on accent { ColorAnimation { duration: root.reduceMotion ? 80 : 300 } }
    Behavior on cyan { ColorAnimation { duration: root.reduceMotion ? 80 : 300 } }
    Behavior on rose { ColorAnimation { duration: root.reduceMotion ? 80 : 300 } }
    Behavior on warn { ColorAnimation { duration: root.reduceMotion ? 80 : 300 } }
    Behavior on danger { ColorAnimation { duration: root.reduceMotion ? 80 : 300 } }
    Behavior on success { ColorAnimation { duration: root.reduceMotion ? 80 : 300 } }
    Behavior on glow { ColorAnimation { duration: root.reduceMotion ? 80 : 300 } }
}
