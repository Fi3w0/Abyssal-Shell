# Settings audit and implementation — 2026-10-22

The rule is that ordinary pages offer choices and actions; raw file contents,
commands and configuration diagnostics belong in Expert › Config files.

| Area | Decision | Current behaviour and storage |
| --- | --- | --- |
| Colours & theme | Keep, connect to shell | Active wallpaper themes resolve correctly. One `colors.accent` drives the shell and settings glow. Editing it creates a custom copy when needed and updates that theme's active border/shadow. |
| This app | Keep, simplify | Remove the independent cyan/accent/rose selector. Atmosphere, background and density stay adjustable in `abyssal/settings.json`; the colour button edits the actual theme. |
| Wallpaper | Keep | Detected output picker, image/video picker, transition presets. Uses `abyssal/wallpaper.json`. |
| Panels | Replace summary with controls | Display/panel selectors, shape, edge, size, length, surface, floating and visibility, with a preview. Preserves widget options and unknown fields in version 2 `abyssal/layout.json`. The graphical live editor arranges widgets and upgrades older layouts. |
| Windows & workspaces | Replace raw editor | Classic/Scroll/Ocean cards; classic layouts, gaps, borders, rounding, shadows, column width/centring/width presets and Ocean choices. |
| Motion & effects | Add controls | Animation presets, durations, slowdown, workspace style, water effects, drag softness. Preset values and precedence follow the existing TideWM implementation. |
| Keyboard & touchpad | Add controls | Installed XKB layout picker, repeat settings/test field, focus behaviour and touchpad controls. Unspecified touchpad switches use an explicit “keep existing” state, not a guessed hardware default. |
| Shortcuts | Replace command fields | Record keys and choose an action or installed application. Existing custom actions are retained without exposing their command text. Duplicate chords are rejected. |
| Startup apps | Replace command fields | Installed-app picker, enable/disable and remove. Existing commands are retained. Writes additional startup entries through the existing autostart pipeline. |
| Notifications | Keep, improve units | Duration slider in seconds, visible count and DND. Stored in existing `notifications.json` units. |
| Power & idle | Keep | Existing blank/lock timers; no claim that blanking powers displays off. |
| Account | Keep | Rounded avatars in both sidebar and Account, display name, existing password action. |
| Expert | Consolidate | All raw JSON/Wave editors, file paths and advanced configuration explanations. Ordinary group headings no longer expose config keys. |
| Header/footer | Replace | Small icon window controls, back navigation, consistent save/discard actions. Layout gutters live in one place; controls are tested for horizontal overflow. |

## Desktop persistence

The registry is `settings/registry/desktop.json`; it is shared by the controls
and typed backend validation. It contains existing TideWM capabilities only.
No TideWM code changes are required by this implementation.

TideWM resolves included files first and then overlays the including file's own
entries, irrespective of the location of its include lines. The app follows that
rule. If the parent owns a key or its top-level block, it surgically changes the
selected value there, retaining comments, binds, includes and unrelated settings.
Otherwise it uses `abyssal-settings.wave` and a static include. Repeated animation
blocks/presets are resolved before displaying values; a late overriding block is
handled when necessary. Parent device overrides have a persisted reversible
baseline in `settings.json` so “restore existing” also works after reopening.

QML objects and arrays are normalized before serialization, so nested panel,
widget, wallpaper and startup data remain structured rather than becoming null.

All writes stay in drafts until Save. The original Wave syntax check, atomic
writes, private backups, symlink checks and rollback remain. The complete loaded
Wave dependency graph is checked for external edits before saving Wave changes.
External file changes reload automatically without a draft; otherwise the draft
is retained and a reload notice appears.

## Reference

Studied the [AngelOS settings tree](https://github.com/MixaDoDs/AngelOS-Dotfiles/blob/main/.config/quickshell/angelos/modules/settings/tree.json),
`WindowsPage.qml`, `SettingRow.qml` and its Niri service from the local reference
checkout. Useful patterns: labelled controls with real backends, contextual hints,
inline previews and a category tree. No AngelOS implementation was copied.

## Validation and limits

The C++ tests cover include precedence, comments/unknown settings, typed writes,
malformed/range/injection rejection, presets and reset, external conflicts and
existing save protections. UI tests visit all fourteen pages under four themes,
three densities and two sizes, check control bounds, exercise save through actual
controls, record shortcuts and preserve existing panel/widget data.

The installed TideWM is tested in a private nested session: GUI engine/column/gap/
border changes are saved and observed through its live IPC. Physical touchpad
behaviour is not exercised by that nested backend. The Wave reader intentionally
does not evaluate arbitrary Lua or custom expressions; those remain in Expert.
The shortcut recorder cannot override shortcuts already intercepted by the
compositor. Global search/recent searches, full window-rule/display editors,
per-app GTK/Qt theme propagation and further detected system backends remain
separate work; the app does not pretend those are implemented.
