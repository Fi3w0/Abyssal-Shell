# Working handoff — 2026-10-22

The Drowned archive foundation is implemented on top of the existing application.
All eleven original pages remain, plus Look › This app. Theme colours now drive
all settings QML, including the palette, controls, glass groups and background.
The four shipped themes have optional backdrop colours matching the approved J
mock-up. The sidebar has a moving lit-edge indicator and collapses to icons at
narrow widths. There are shared buttons, switches, sliders, steppers, text fields,
dropdowns, group panels, line icons and page fades. JetBrains Mono uses an
installed font with a monospace fallback; no fonts or packages were installed.

This app previews theme/solid/custom/blurred-image backgrounds, window opacity,
shafts, marine snow, drift, glass, glow, selection style, density, font, group
corners and reduced motion. Snow repaints at most every 33 ms, is not instantiated
at zero amount, and stops with reduced motion/disabled drift, when hidden or
minimized, or after ten seconds without focus. Light breathing follows the same
lifecycle. Video wallpaper backgrounds currently fall back to the theme gradient.
The image background uses the first detected output; per-output window matching
is deferred. Window geometry persistence and the pin-on-top action are deferred.

Preferences are drafts in `$XDG_CONFIG_HOME/abyssal/settings.json`, using the
existing validation, atomic writes, external-change checks, symlink protection,
backups and rollback. Live preview does not imply a disk write. Reload discards
the preview with the existing confirmation. Custom themes can store settingsLook;
app overrides win, and reset removes known overrides while retaining unknown
keys. Malformed raw JSON is not replaced by reset. The live-apply/undo backend
and managed settings.wave include have not been implemented yet.

Validation: settings-store covers existing protections plus appearance draft
persistence, invalid values, external edits and reset. settings-ui loads all 12
pages under 4 shipped themes × 3 densities × 2 sizes (860×560 and 1920×1080),
checks live theme changes and discard, and exercises slider, switch, dropdown and
stepper keyboard interactions. Nested TideWM validation uses a private virtual
host and temporary runtime/config directories, with rendered captures of the four
themes and four background modes; no native compositor restart or user config
changes. Captures and logs are kept outside the repo in the local review cache.
The complete expanded settings inventory and registry are still future work.

Approved canvas sources and the full specification are archived in docs/design/.
Do not overwrite the user's unrelated shell changes in this worktree.

---

# Previous handoff — 2026-10-21

First native Qt 6 C++/Quick settings app built and installed locally, with a
.desktop launcher and shell quick-menu gear / app-launcher action / IPC entry.
A running app is reused through a lock and local socket. Native preview was
verified on HDMI-A-2, floating; machine-specific rules stay in the local config.

Implemented: themes/custom copies/colours/opacity/radii, wallpapers/transitions,
panel summary + existing live editor, single-line shortcut addition/editing,
TideWM included-file editor, startup apps, profile name/avatar, passwd terminal,
update settings, notifications and idle. Draft/Apply, JSON checks, wavefmt syntax
validation, external-change and symlink checks, private backups with manifest,
rollback and discard confirmation are present. Tests use temporary configs.
Config tests and all eleven QML pages passed; existing shell regressions pass.

Next: dedicated graphical TideWM display/input/animation/window-rule pages;
embed the panel/widget editor using a shared schema; scope-aware keybind conflict
detection and shortcut recording; default apps and matching GTK/Qt/font settings.
Current keybind matching handles single lines, not a full semantic Wave/Lua AST.

Five wallpaper script recipes: dissolve, undertow, current, bloom, sink. Static
awww images use recipe flags; native image/outgoing video snapshots use the Qt
shader. Incoming videos intentionally bypass overlays: a nested test found a
first-frame callback stall when a video starts under the transition. This remains
a known limitation, documented rather than claimed fixed in the compositor.

No commits or publication were made. The active repo has earlier user/session
changes; do not reset them. Full scope/build instructions are in ../README.md.
