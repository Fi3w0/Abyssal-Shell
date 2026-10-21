# Working handoff — 2026-10-21

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
