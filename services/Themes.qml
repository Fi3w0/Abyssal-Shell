pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Every theme the shell can wear, and the one it wears now.
//
// A theme is a JSON file: themes/<id>.json in the shell (shipped) or
// ~/.config/abyssal/themes/<id>.json (yours; the same id wins over a
// shipped one). `wallpaper.json` there is written by the wallpaper picker
// from the wallpaper's colours. Shape:
// {
//   "name": "Abyssal Tide", "shape": "pill" | "square", "mono": true,
//   "glass": 0.72, "glassStrong": 0.88, "radius": { "popup": 22, "control": 16 },
//   "colors": { crust, base, surface0, surface1, overlay, subtext, text,
//               accent, cyan, rose, warn, danger, success,
//               optional: hairline, hover, accentSoft, chip, controlEdge },
//   "tidewm": optional { border: [from, to], inactive: [from, to],
//               urgent: [from, to], shadow, shadowInactive, shadowUrgent }
// }
// Anything left out comes from Abyssal Tide or is derived from the colours.
//
// The resolved theme is written to ~/.local/state/abyssal/theme.json (the
// lock screen reads it) and, when ~/.config/tidewm exists, TideWM's window
// borders and shadow to ~/.config/tidewm/theme.wave (include it after your
// own look in config.wave; TideWM reloads it on change).
Singleton {
    id: root

    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config"
    readonly property string userDir: configHome + "/abyssal/themes"
    readonly property string shippedDir: Quickshell.shellPath("themes")
    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/abyssal"
    readonly property string wavePath: configHome + "/tidewm/theme.wave"

    readonly property var fallback: ({
        name: "Abyssal Tide", shape: "pill", mono: true, glass: 0.72, glassStrong: 0.88,
        radius: { popup: 22, control: 16 },
        colors: {
            crust: "#080b17", base: "#0c1020", surface0: "#161b2e", surface1: "#212841",
            overlay: "#525c7e", subtext: "#9aa3c4", text: "#dde3f6",
            accent: "#a98bff", cyan: "#7fd6e6", rose: "#f28fb0",
            warn: "#f5c27a", danger: "#ff7a95", success: "#8be0b0"
        }
    })

    // id -> theme object (with `id` and `user`)
    property var themes: ({})
    readonly property var ids: Object.keys(themes).filter(id => id !== "wallpaper")
        .sort((a, b) => themes[a].name.localeCompare(themes[b].name))

    readonly property string activeId: Appearance.fromWallpaper && themes.wallpaper ? "wallpaper"
        : themes[Appearance.theme] ? Appearance.theme : "abyssal-tide"
    readonly property var active: resolve(themes[activeId] || fallback)

    function name(id) {
        return themes[id] ? themes[id].name : id
    }

    // Fills in what a theme left out.
    function resolve(t) {
        const f = fallback
        const c = Object.assign({}, f.colors, t.colors || {})
        const glass = typeof t.glass === "number" ? t.glass : f.glass
        const square = t.shape === "square"
        c.hairline = c.hairline || rgba(c.text, 0.08)
        c.hover = c.hover || rgba(c.text, 0.07)
        c.accentSoft = c.accentSoft || rgba(c.accent, 0.16)
        c.chip = c.chip || rgba(c.crust, 0.5)
        c.controlEdge = c.controlEdge || c.hairline
        const w = t.tidewm || {}
        return {
            id: t.id || "abyssal-tide",
            name: t.name || "Untitled",
            square: square,
            mono: t.mono === true,
            glass: glass,
            glassStrong: typeof t.glassStrong === "number" ? t.glassStrong : Math.min(1, glass + 0.16),
            popupRadius: t.radius && t.radius.popup !== undefined ? t.radius.popup : square ? 12 : 22,
            controlRadius: t.radius && t.radius.control !== undefined ? t.radius.control : square ? 8 : 16,
            colors: c,
            tidewm: {
                border: w.border || [c.accent, c.cyan],
                inactive: w.inactive || [hexA(mix(c.accent, c.base, 0.7), 0.69), hexA(c.surface0, 0.69)],
                urgent: w.urgent || [c.rose, c.danger],
                shadow: w.shadow || hexA(mix(c.accent, c.crust, 0.7), 0.69),
                shadowInactive: w.shadowInactive || hexA(c.crust, 0.44),
                shadowUrgent: w.shadowUrgent || hexA(c.rose, 0.5)
            }
        }
    }

    // ── Colour helpers (#rrggbb / #rrggbbaa strings) ────────────────────
    function parse(hex) {
        const h = String(hex).replace("#", "")
        return {
            r: parseInt(h.slice(0, 2), 16), g: parseInt(h.slice(2, 4), 16), b: parseInt(h.slice(4, 6), 16),
            a: h.length >= 8 ? parseInt(h.slice(6, 8), 16) : 255
        }
    }
    function hex2(n) {
        return Math.max(0, Math.min(255, Math.round(n))).toString(16).padStart(2, "0")
    }
    function mix(a, b, t) {
        const x = parse(a), y = parse(b)
        return "#" + hex2(x.r + (y.r - x.r) * t) + hex2(x.g + (y.g - x.g) * t) + hex2(x.b + (y.b - x.b) * t)
    }
    function hexA(color, alpha) {
        return String(color).slice(0, 7) + hex2(alpha * 255)
    }
    function rgba(color, alpha) {
        const x = parse(color)
        return Qt.rgba(x.r / 255, x.g / 255, x.b / 255, alpha)
    }
    // TideWM wants RRGGBBAA without the #.
    function wave(color) {
        const x = parse(color)
        return (hex2(x.r) + hex2(x.g) + hex2(x.b) + hex2(x.a)).toUpperCase()
    }

    // ── Loading ─────────────────────────────────────────────────────────
    function reload() {
        if (!loader.running) loader.running = true
    }

    Process {
        id: loader
        command: ["sh", "-c", "for f in \"$1\"/*.json \"$2\"/*.json; do [ -f \"$f\" ] && printf '\\036%s\\037' \"$f\" && cat \"$f\"; done; true",
            "sh", root.shippedDir, root.userDir]
        stdout: StdioCollector {
            onStreamFinished: {
                const next = {}
                for (const chunk of text.split("\x1e")) {
                    const cut = chunk.indexOf("\x1f")
                    if (cut < 0) continue
                    const file = chunk.slice(0, cut)
                    const id = file.replace(/^.*\//, "").replace(/\.json$/, "")
                    try {
                        const t = JSON.parse(chunk.slice(cut + 1))
                        if (!t || typeof t !== "object" || !t.colors) throw new Error("no colors")
                        t.id = id
                        t.user = !file.startsWith(root.shippedDir)
                        t.name = t.name || id
                        next[id] = t
                    } catch (e) {
                        console.warn("abyssal: skipping theme", file + ":", e)
                    }
                }
                root.themes = next
            }
        }
    }

    // Saves a theme to your themes folder and loads it.
    function save(id, theme) {
        pendingSave = { id: id, text: JSON.stringify(theme, null, 2) + "\n" }
        if (!mkdirs.running) mkdirs.running = true
    }
    property var pendingSave: null
    Process {
        id: mkdirs
        command: ["mkdir", "-p", root.userDir, root.stateDir]
        onExited: code => {
            if (code !== 0 || !root.pendingSave) return
            saver.path = root.userDir + "/" + root.pendingSave.id + ".json"
            saver.setText(root.pendingSave.text)
            root.pendingSave = null
        }
    }
    FileView {
        id: saver
        printErrors: false
        onSaved: root.reload()
    }

    // ── Publishing the active theme ─────────────────────────────────────
    onActiveChanged: publish.restart()
    Timer {
        id: publish
        interval: 150
        onTriggered: {
            const a = root.active
            const c = a.colors
            waveCheck.state = JSON.stringify({ id: a.id, name: a.name, mono: a.mono, colors: {
                crust: c.crust, base: c.base, surface0: c.surface0, overlay: c.overlay, subtext: c.subtext,
                text: c.text, accent: c.accent, cyan: c.cyan, rose: c.rose, danger: c.danger } }, null, 2) + "\n"
            const w = a.tidewm
            const text = "# Written by Abyssal from its active theme (" + a.name + "): window\n"
                + "# borders and shadow. Rewritten on every theme change, so edit the\n"
                + "# theme, not this file. Include it after your own look in config.wave.\n"
                + "border {\n"
                + "    active_from = " + wave(w.border[0]) + "\n    active_to = " + wave(w.border[1]) + "\n"
                + "    inactive_from = " + wave(w.inactive[0]) + "\n    inactive_to = " + wave(w.inactive[1]) + "\n"
                + "    urgent_from = " + wave(w.urgent[0]) + "\n    urgent_to = " + wave(w.urgent[1]) + "\n"
                + "}\n"
                + "shadow {\n"
                + "    color = " + wave(w.shadow) + "\n    inactive_color = " + wave(w.shadowInactive) + "\n"
                + "    urgent_color = " + wave(w.shadowUrgent) + "\n"
                + "}\n"
            waveCheck.text = text
            waveCheck.running = false
            waveCheck.running = true
        }
    }
    FileView {
        id: stateFile
        path: root.stateDir + "/theme.json"
        printErrors: false
    }
    // theme.wave only when TideWM is configured here, and only when the text
    // changed (every write makes TideWM reload its config).
    Process {
        id: waveCheck
        property string text: ""
        property string state: ""
        onExited: stateFile.setText(state)
        command: ["sh", "-c", "mkdir -p \"$1\"; [ -d \"$(dirname \"$2\")\" ] && { [ \"$(cat \"$2\" 2>/dev/null)\" = \"$3\" ] || printf '%s\\n' \"$3\" > \"$2\"; }; true",
            "sh", root.stateDir, root.wavePath, text.replace(/\n$/, "")]
    }

    // qs -c abyssal ipc call theme set kelp-forest | list | wallpaper true
    IpcHandler {
        target: "theme"
        function set(id: string): void { Appearance.set("fromWallpaper", false); Appearance.set("theme", id) }
        function wallpaper(on: bool): void { Appearance.set("fromWallpaper", on) }
        function list(): string { return root.ids.map(id => id + "\t" + root.name(id)).join("\n") }
        function reload(): void { root.reload() }
    }

    Component.onCompleted: reload()
}
