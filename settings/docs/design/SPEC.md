# Abyssal Settings: full spec for Codex

Visual references are boards J, J2, J3 and "Settings map" on the canvas (https://claude.ai/artifact/DivgWSPjsb3tLT5MEUpZZa). The link is private, so export screenshots of those four boards into `settings/docs/design/` before handing this to Codex.

---

## 0. Goal

The settings app should let a normal user change almost everything about the desktop without opening a config file, with AngelOS-level depth (about 400 settings) and its own "drowned archive" personality. The app is built first, and any setting the shell or TideWM can't do yet still gets its row: it shows as unavailable, and the missing feature goes onto the shell or TideWM TODO.

## 1. Hard rules

1. **Nothing hardcoded:** no colours, paths, monitor names, GPU, distro, init system or package manager. Every colour comes from the active theme JSON; every path comes from XDG plus ConfigStore. Detect system backends at runtime (Section 7) and never assume them.
2. **No new packages.** Use only Qt 6 modules the app already links, plus tools already on the system, each detected first. If a backend is missing, its rows show as disabled with "needs ‹tool›"; they don't crash and aren't hidden.
3. **The existing app is the base.** It's the Qt 6 C++/QML app in `settings/` (ConfigStore, Draft/Apply, backups, rollback, external-change and symlink checks, JsonForm). Extend it; don't rewrite it.
4. **Schema-driven.** Pages are generated from a settings registry (Section 6), not hand-written per page, except for special pages (Displays arrangement, Colours, Shortcuts recorder, Panels editor).
5. **Every setting lives on exactly one page.** A test enforces this.
6. **Respect TideWM ownership.** The settings app never rewrites the user's `config.wave`. It writes its own included file (Section 7.2) and adds one `include` line, with confirmation, the first time.
7. **Git:** signed commits, no AI trailers, no push without Fiw's OK. Validate with a nested TideWM run before Fiw relogs.

---

## 2. Window

- **Size:** default 1180×780, minimum 860×560. Remember size and position per output name, but never store an output name as a default.
- **Single instance:** this exists already. A second launch with arguments navigates the running window.
- **Title bar:** client-side, 38 px high.
  - Left: `abyssal · settings — ‹page name›`, where the page name is dimmed.
  - Right: the undo chip (Section 5.3), a pin-on-top toggle, minimize and close.
  - Dragging the bar moves the window and double-clicking it maximizes. Follow TideWM's decoration protocol if TideWM requests server-side decorations.
- **Regions:**
  - Title bar on top.
  - Body underneath: sidebar (262 px, collapsible to a 56 px icon rail below 1000 px wide) plus the content area.
  - Status bar, 24 px, at the bottom of the content area.
- **Content width:**
  - Groups flow into 2 columns when the content area is at least 900 px wide, otherwise 1 column.
  - Column order is the registry order, filled top-to-bottom per column (masonry by height, deterministic).

---

## 3. Visual system

### 3.1 Tokens

The 13 base tokens are read from the active theme JSON: `crust`, `base`, `surface0`, `surface1`, `overlay`, `subtext`, `text`, `accent`, `cyan`, `rose`, `warn`, `danger`, `success`. They're exposed through one QML singleton, `Theme`. Nothing may use a literal colour.

The app's look settings (Section 8, Look › This app) control the following derived tokens:

| Token | Formula |
|---|---|
| `glow` | `cyan`, `accent` or `rose`, per the `app.glow.source` setting (default `cyan`) |
| `edge` (hairlines) | `text` at 9% alpha |
| `glass` (group panels) | `text` at `app.surface.glass` (default 3%, range 0–15%) |
| `deep` (control wells: inputs, segmented, steppers) | `crust` at 70% |
| `bar` (title bar) | `crust` at 80% |
| `side` (sidebar) | `crust` at 40% |
| `glowSoft` (selection fill) | `glow` at `app.surface.glowStrength` (default 15%, range 0–40%) |
| `glowEdge` (selected borders, undo chip border) | `glow` at 33% |
| `backdropTop` | the theme's optional `backdrop.top` key; otherwise `mix(base, glow, 0.14)`, lightened 6% |

- If a theme defines any derived token itself (for example `hairline` or `accentSoft`, as Trench Violet does), the theme wins.
- When the theme changes, every colour animates over 300 ms (Section 9).

### 3.2 Background

The background is a stack of layers, back to front:

1. **Water:** set by `app.background.style`.
   - `theme` (default): a vertical gradient from `backdropTop` at 0%, through `base` at 38%, to `crust` at 100%.
   - `solid`: `base`.
   - `custom`: a gradient from `app.background.top` to `app.background.bottom`. Both default to the theme's values, and a "from theme" link resets them.
   - `wallpaper`: the current wallpaper scaled to fill, blurred about 48 px with MultiEffect (QtQuick.Effects, already in Qt 6), then darkened by a `crust` overlay at 55%.
2. **Window opacity:** `app.window.opacity`, 40–100%, default 100%. Below 100% the window background is translucent (this needs compositor alpha, which TideWM supports).
3. **Light shafts:** two diagonal soft bands at about 104°, in `glow` at 4–6% alpha, plus a radial glow from just above the top edge at about 62% across. Strength is `app.atmosphere.shafts`, 0–100%, default 100%.
4. **Marine snow:** about 40–70 particles of 1–1.8 px. Most are `text` at 20–30% alpha and some are `glow` at 25%. Amount is `app.atmosphere.snow`, 0–100%, default 80%. Use QtQuick.Particles (in qtdeclarative, so no new package). With the amount at 0, don't create the particle system at all.
5. Content on top.

### 3.3 Typography

- One family: JetBrains Mono, the default for `app.font`. The user can pick any installed font, and the "theme UI font" option uses the shell's font.
- If JetBrains Mono isn't installed, fall back to the system monospace font. Never bundle it.
- **Scale:**

| Use | Style |
|---|---|
| Page title | 26 px / 800 / −0.5 letter spacing |
| Breadcrumb, page description | 11 px, `subtext` |
| Group heading | 11 px / 700 / 1.5 px letter spacing, uppercase, `glow` |
| Row label | 12 px / 500, `text` |
| Row hint | 10 px, `subtext` |
| Value readouts | 12 px / 700 |
| Status bar, badges | 10 px |

- **Density:** `app.density` is compact, normal (default) or roomy. Every padding is multiplied by 0.8, 1 or 1.25. Font sizes don't change; text size belongs to Accessibility.

### 3.4 Shape

- **Radii:** group panels 10 px; controls 6–7 px; switch tracks fully round; the sidebar selection is square on the left and 7 px on the right.
- **Theme shape:** if the theme's shape is `square` (Trench Violet), all radii become 3 px; if it's `pill`, keep the values above.
- **Group corners:** each group panel has two L-shaped brackets, top-left and bottom-right, 12×12 px with a 2 px `glow` stroke, following the panel's radius. They can be turned off with `app.surface.corners`.
- **Lines:** 1 px `edge` hairlines between rows and around panels. Dashed `edge` for "add" buttons and the More… fold.

### 3.5 Icons

- Line icons on a 24 px grid with a 1.8–2 px stroke, using `currentColor`, shown at 13–15 px.
- They live as SVG in `settings/icons/`. Use your own icons or ones with a compatible licence, and record the source and licence in `ICON-CREDITS.md`.
- No emoji anywhere.

---

## 4. Layout regions in detail

### 4.1 Sidebar

From top to bottom:

1. **Account card:** a 38 px avatar from the account page (if there's no avatar, a `glowSoft` square with a `glow` border), the display name, and `account · ‹theme name›`. Clicking it opens Account.
2. **Search field:** 32 px, magnifier icon, placeholder `search…`, and a `^F` key hint. Focus gives it a `glow` border and a 14 px `glowSoft` outer glow.
3. **Halls, the sections:**
   - Each hall has a header in uppercase 10 px with 2 px letter spacing in `subtext`, followed by a hairline to the right edge. No diamonds or glyphs.
   - **Section items:** 28 px high, 15 px icon, lowercase label, then on the right a `warn` ★ if anything inside is new and an optional count in 10 px `subtext`. The count is the number of pending updates, unread notifications and similar; it is never a count of settings.
   - **Inactive item:** `subtext` text and a 1 px `edge` line on the left.
   - **Hover:** the text becomes `text` and the background `glass`, over 120 ms.
   - **Active item:** `glow` text at weight 700, a 2 px `glow` left edge, a background gradient from `glowSoft` to transparent at 85%, and a soft `glow` spill of −6 px with 14 px blur to the left. There is only one indicator element in the whole sidebar; it moves between items (Section 9) rather than being drawn per item. The style can be switched to `filled` or `underline` with `app.nav.selectionStyle`.
4. **Footer:** TideWM status, for example `● tidewm 0.9 · ipc connected` with `success`, `warn` or `danger` dots, and `3 outputs · scroll · ws 2/5`. All of these are live values from IPC.

### 4.2 Page header

- **Breadcrumb:** `section › page` in 11 px, with the `›` in `glow`.
- **Title:** 26 px. One word may be tinted `glow`; that's the registry's `titleAccent` field and it's optional.
- **Description:** one line saying what the page controls and how changes apply.
- **Right side:** page actions from the registry, such as `from wallpaper`, `import`, `export`, `reset page`. Some pages show a compact picker here, such as the layout-engine picker: three 64×30 mini-diagrams with labels, where the selected one gets a `glow` border and glow.

### 4.3 Groups

- Each group is a glass panel. The heading row has an optional icon, the TITLE in uppercase, a hairline, and on the far right the config section in brackets, such as `[layout.scroll]`, in `subtext`.
- Clicking the bracket opens that section in the Expert › Config files viewer at the right line.
- Rows sit inside with 8 px vertical padding × density and hairlines between them.

### 4.4 Below the groups

- **Next door:** a row of chips (`label ›`) linking related pages, from the registry's `nextDoor`. Each chip can deep-link to a group or a row.
- **More…:** a dashed fold that reads `more… ‹names of the first 3–4 hidden rows›` with `N ▾` on the right. Opening it shows the page's advanced rows. Search opens it automatically when a match is inside.

### 4.5 Status bar

- **Left:** the save state, which is one of:
  - `✓ saved 2s ago` (with relative time)
  - `● unsaved draft (3)`
  - `⚠ validation failed — details`
  - `↻ external change — reload?`
- **Middle:** the file that was last written, relative to `$HOME`, and `validated · N warnings`.
- **Right:** keyboard hints: `^Z undo · ^F search · esc back`.

---

## 5. Components

Every component reads only `Theme` tokens and has the states default, hover, pressed, focus (a 2 px `glow` focus ring at 2 px offset, always visible on keyboard focus), disabled (50% opacity, no pointer, with a reason tooltip) and the unavailable state (Section 5.14).

1. **Setting row:**
   - The label (with an optional ★ new, a badge and a hint underneath) is on the left and the control on the right.
   - The label column is at most 45% of the row width.
   - The whole row has a hover tint of `glass`, which counts as one extra step of glass.
   - Right-click or the `⋯` that appears on hover opens a menu: reset to default, copy config key, show in config file, and "why is this disabled?".
2. **Switch:** a 34×20 track with a 14 px knob.
   - On: the track is filled `glowSoft` with a `glow` border, and the knob is `glow` with an 8 px glow.
   - Off: the track is `deep` with an `edge` border, and the knob is `subtext`.
3. **Undo chip** in the title bar: `↶ undo ‹last setting label›`, in `glow` with a `glowEdge` border.
   - It's hidden when the undo stack is empty.
   - Hovering shows a dropdown with the last 10 changes, each with old → new.
4. **Segmented control:** a `deep` well with a 2 px inset.
   - Options are 22 px high; the selected one is a `glow` fill with `crust` text at weight 700.
   - One pill element slides between options.
5. **Slider:** a 4 px track, filled with `glow` up to the value, and a 14 px `text` knob ringed in `crust`.
   - The value readout sits on the right, 42 px wide and right-aligned.
   - Arrow keys change it by one step, Page Up/Down by 10 steps, and Home/End jump to the minimum and maximum.
   - Dragging updates the preview live and commits on release (Section 7.1).
6. **Stepper:** `−  value  +` in a `deep` well with 26 px buttons. Holding a button repeats after 400 ms, then every 60 ms.
7. **Dropdown:** a `deep` button at least 150 px wide with a chevron. It opens a popup list in `surface0` with an `edge` border, 8 px radius and a shadow. The current item has the lit-edge mark. Type-ahead filtering works when there are more than 8 items.
8. **Chips and lists:**
   - Value chips (preset widths: 33%, 50%, 67%) with a dashed `+` to add one.
   - Each chip has a hover ✕ to delete it, and chips can be reordered by drag.
9. **Card picker:** for layout engine, background style, theme presets and similar.
   - Each card is a mini-diagram or swatch with a label and a one-line hint.
   - The selected card has a `glow` border and 16 px `glowSoft` glow.
   - Cards are radio buttons: arrow keys move between them and Space selects.
10. **Swatch picker:** 18–22 px circles; the selected one has a 2 px `text` ring and a glow. A custom swatch opens the colour editor popover (H/S/L tracks, hex input, eyedropper if a portal or tool is available).
11. **Row preview:** an inline box 64 px high under a row in a `deep` well. It plays a looping QML scene for the row's current value, such as columns with neighbours peeking in, or an animation curve.
    - The caption at the bottom left reads `preview — ‹what it shows›`, with a ✕ at the bottom right.
    - It opens when the user changes the row's value and closes with ✕ or when they leave the page. Scenes live in `settings/previews/*.qml`.
12. **Badges:**

    | Badge | Look | Meaning |
    |---|---|---|
    | `★` | `warn` | new since last seen |
    | `theme` | `glowSoft` with `glow` text | the value follows the theme |
    | `restart` | `warn` outline | needs a relogin or app restart |
    | `experimental` | `rose` outline | experimental |
    | `needs ‹x›` | `subtext` outline | unavailable |

13. **Toasts:** bottom-right inside the window, `surface0` with an `edge` border, at most 3 stacked. Used for "applied", "reverted", errors with a "details" link, and "external change".
14. **Unavailable row:**
    - The control is disabled, a `needs ‹tidewm feature / shell feature / tool›` badge shows, and the hint explains what's missing.
    - Rows that wait for a TideWM or shell feature show `coming in ‹component›`.
    - These rows are still searchable, so users and developers can see what's planned.
15. **Dialogs:** a centred modal with the backdrop dimmed to `crust` at 60% (no blur), a 12 px radius and the group-corner brackets. Used for discarding changes, confirming display changes (with a countdown) and confirming destructive actions (danger button).

---

## 6. Settings registry

Use one source of truth, like AngelOS's `tree.json`: `settings/registry/*.json`, one file per section.

```json
{
  "id": "desktop",
  "label": "desktop",
  "icon": "windows",
  "pages": [{
    "id": "windows",
    "label": "windows & workspaces",
    "titleAccent": "&",
    "description": "How TideWM lays out your windows. Applied live, validated before it's written.",
    "header": "layout-engine-picker",
    "nextDoor": ["input/shortcuts#scroll", "look/panels#workspaces"],
    "groups": [{
      "id": "scroll",
      "label": "scroll",
      "icon": "columns",
      "configSection": "layout.scroll",
      "rows": [{
        "id": "scroll.columnWidth",
        "label": "column width",
        "hint": "share of the screen a new app gets",
        "keywords": ["width", "column", "size", "new window"],
        "control": {"type": "slider", "min": 10, "max": 100, "step": 1, "unit": "%"},
        "backend": {"kind": "tidewm", "key": "layout.scroll.default-column-width"},
        "default": 94,
        "since": "0.9.0",
        "preview": "scroll-column-width",
        "advanced": false,
        "requires": ["tidewm>=0.9", "layout=scroll"],
        "restart": false
      }]
    }]
  }]
}
```

- **Control types:** `switch`, `slider`, `stepper`, `segmented`, `dropdown`, `cards`, `swatches`, `color`, `chips`, `text`, `path`, `keybind`, `list` (editable rows), `custom:<Component>` (for the special pages).
- **`backend.kind`:** `shell` (Abyssal JSON), `tidewm` (Wave include file), `system` (a detected tool, Section 7.3), `app` (this app's own look), `file` (a raw path).
- **`requires`:** capability checks. When one fails, the row shows as unavailable (Section 5.14).
- **Tests:**
  - every row id is unique;
  - every row is on exactly one page;
  - every `nextDoor` target exists;
  - every `shell` and `tidewm` key is known to the backend schema, or marked `"pending": "shell" | "tidewm"`;
  - every `preview` scene file exists.
- **Search index:** built from labels, hints, keywords, page names and current values, so "94" finds column width. Russian and Spanish keywords may be added later; the index is language-agnostic.

---

## 7. Behaviour

### 7.1 Applying changes

- **Default is live apply plus undo.** A change is validated, written atomically (temp file + rename) and reloaded through IPC within 150 ms. The status bar shows `saved`.
- **Draft rows:** rows with `"draft": true` (raw text, keybind edits, startup apps, anything multi-field) go into the existing Draft/Apply flow. The Apply and Discard buttons show in the status bar while there's a draft.
- **Risky rows:** display resolution, scale, refresh rate, and VRR when it goes black. These apply immediately and then open a dialog: "Keep these display settings? Reverting in 15s", with an animated countdown ring and Keep / Revert. With no answer, it reverts.
- **Undo stack:** 50 entries per session; Ctrl+Z undoes and Ctrl+Shift+Z redoes. Each entry stores row id, old value, new value and time. Undoing scrolls to the row and flashes it (Section 9).
- **Validation:** JSON schema for the shell config, and a Wave syntax check plus `tidewm --validate` (if it exists, otherwise the nested-parse fallback the app already has) for TideWM. If validation fails, nothing is written, the row shakes, and a toast says why.
- **External changes:** keep the existing watcher. A banner offers "reload" or "keep mine (overwrite)", and nothing is overwritten silently.
- **Backups:** keep the existing private backups and manifest; rollback lives in Expert › Config files.

### 7.2 TideWM writes

- The settings app owns `$XDG_CONFIG_HOME/tidewm/settings.wave`. On first use it asks: "Add `include "settings.wave"` to the end of config.wave?". If the user says no, TideWM rows stay read-only with a "connect" button.
- Values in the user's own config.wave that come after the include win. If one overrides a row, that row shows `overridden in config.wave:LINE` and an "open" button.
- Read the live state through TideWM IPC whenever it exists, falling back to parsing.

### 7.3 System backends

Detect each one at startup and recheck when a page opens. Never assume any of them.

| Area | Detected backend |
|---|---|
| Audio | PipeWire via `wpctl`, else `pactl` |
| Network | NetworkManager via `nmcli`, else iwd via `iwctl` |
| Bluetooth | `bluetoothctl` |
| Power | `powerprofilesctl`, else tuned; brightness through the shell's own service |
| Night light | the shell's own service, or a TideWM gamma protocol if added |
| Input and displays | TideWM IPC |
| Default apps | `xdg-mime` |
| GTK, Qt and fonts | writing `gtk-3.0/settings.ini`, `gtk-4.0/settings.ini`, `qt6ct` (if present) and fontconfig user files |
| Init and session | systemd user or OpenRC or plain; only used for autostart, and startup apps go through TideWM `spawn` |

- The detection results show in About → "backends", which lists what was found and what's missing.

### 7.4 Navigation

- **Deep links:** `abyssal-settings ‹section›/‹page›[#group[.row]]`, for example `abyssal-settings desktop/windows#scroll.columnWidth`. The same addresses are used by IPC (`abyssal ipc settings open …`), by next-door chips and by the shell (right-clicking a panel → "panel settings").
- **Back and forward:** Esc goes back; Alt+←/→ go back and forward; the mouse back and forward buttons work too.
- **Restore:** remember the last page and scroll position.

### 7.5 Search

- Ctrl+F or typing anywhere focuses the search.
- Results appear in a dropdown under the field: up to 8 rows, each with `label` and `section › page` underneath and the current value as a chip on the right. Matching characters are tinted `glow`.
- ↑/↓ move through results and Enter jumps. Jumping opens the page, opens More… if needed, scrolls the row to the centre and flashes it twice.
- If nothing matches: "nothing found — try ‹nearest keyword›" plus "search the config files" (a grep through the known config files, read-only).

### 7.6 New stars

- A row's `since` is compared with the stored `lastSeen` version for that row. If it's newer, the row gets a ★, and the ★ also bubbles up to its page and section.
- A row's ★ clears once it has been visible for 2 s. When nothing on a page is new any more, the page's ★ clears.
- "Mark all seen" is in the sidebar right-click menu.

### 7.7 Keyboard

- Tab and Shift+Tab move through the controls. Ctrl+1…9 jump to sections. Ctrl+, opens This app.
- Every control is reachable and works without a mouse.
- Accessible names come from the row label, and descriptions from the hint.

### 7.8 Live state

- Subscribe to TideWM IPC events for outputs, workspaces, layout and the focused window, and to shell IPC for theme, wallpaper and panels.
- When something changes outside the app (for example a keybind switches the layout), the UI updates without a reload and the affected value flashes once.

---

## 8. Settings inventory

Key: **●** exists today, **◐** partial, **+** new, **[W]** needs a TideWM feature, **[S]** needs an Abyssal shell feature, **[T]** uses a detected system tool. Rows marked (adv) go under More….

### HOME
- **Home**
  - Greeting with name and avatar.
  - System status cards: TideWM version and IPC, theme, wallpaper, pending updates, disk free, battery (if there is one).
  - Recently changed (the last 5 from the undo history, persisted).
  - Most opened pages.
  - "What's new" (rows with a ★).
- **Presets** +
  - Save the whole setup (theme, app look, panels, layout, animations, wallpaper) under a name.
  - Built-in presets: calm, focus, gaming, light.
  - Apply with a preview diff ("12 settings will change") and confirmation.
  - Import and export as one `.abyssal-preset.json` file.

### LOOK
- **Colours & theme** ●◐ (board J2)
  - Theme cards for the shipped themes plus custom copies (●).
  - Create a custom copy (●).
  - Edit the 13 tokens in groups (Surfaces, Text, Accents, States), each with swatch, hex, role and the H/S/L editor.
  - Colours from wallpaper ●.
  - Live preview: mini desktop with bar, terminal, notification and quick settings.
  - Contrast table (text/base, subtext/base, crust on accent, glow on surface0) with AA/AAA/low grades.
  - "Apply to" switches: shell, this app, GTK 3/4 [T], Qt/qt6ct [T], TideWM borders [W], terminal [T, kitty/foot/alacritty if detected], lock screen.
  - Panel opacity ●, popup opacity ●, popup radius ●, control radius ●.
  - Shape: pill or square.
  - Import and export.
  - (adv) Monochrome icons ●.
- **This app** + (board J3)
  - `app.background.style` (cards).
  - Gradient top and bottom colours.
  - Window opacity.
  - Light shafts, marine snow, drift.
  - Glass, glow strength, glow source.
  - Selected-page style.
  - Density, font, group corners.
  - Reset to theme; save into the current custom theme.
- **Wallpaper** ●
  - Picker ●, live picker ●, renderer ●, transition preset ●, transition ●, duration ●.
  - Per-monitor wallpaper [S]; fill mode; slideshow folder, interval and shuffle [S]; video wallpaper ◐ (known limitation with transitions).
  - (adv) Pause video on battery or fullscreen [S].
- **Fonts** +
  - UI font, monospace font, size, hinting, antialiasing, subpixel order [T fontconfig].
  - Apply to GTK and Qt [T].
  - Presets: compact, default, large.
- **Icons & cursor** ◐
  - Icon theme (from detected themes) [T]; monochrome ●.
  - Cursor theme, cursor size [W cursor protocol, T for GTK].
  - (adv) Hide the cursor while typing [W].
- **Panels** ◐
  - "Edit panels live" ● (opens the existing editor).
  - Position, shape (full, floating, pill), height, opacity, auto-hide, which monitors.
  - Widget list per panel with left/centre/right slots and drag to reorder [S schema shared with the editor].
  - Clock format; tray; workspace indicator style.
- **Widgets** ◐
  - List of desktop widgets with an add form (type, monitor) and each widget's own settings, generated from the widget's schema [S].
- **Launcher** +
  - Style, size, position; search sources (apps, files, calculator, commands, plugins); recent apps; key to open [S].
- **Lock screen** ◐
  - Lock after ● and blank after ● (these move here from Power).
  - Clock style, blur amount, show avatar, show media.
  - Login screen theme sync [T if the greeter is detected].
- **OSD & popups** +
  - Volume and brightness OSD style, position and duration [S].
  - Popup animation style.

### DESKTOP · TIDEWM
- **Windows & workspaces** (board J)
  - Header: layout-engine cards for classic, ocean and scroll [W ●].
  - **Scroll group:**
    - column width (slider + preview);
    - centre focused (never / if hidden / always);
    - preset widths (chips; "cycled by ‹keybind›" with the binding read live);
    - centre a lone column;
    - (adv) default height presets, empty workspace above first [W].
  - **Classic group:**
    - master ratio, master count, new window position, smart gaps [W].
  - **Ocean group:**
    - zoom limits, pan speed, snap-to-window [W].
  - **Gaps & borders:**
    - inner gaps, outer gaps;
    - focus ring (on/off, swatches from theme tokens, width);
    - border width;
    - corner radius (with a `theme` badge when it follows the theme);
    - (adv) shadows: on, radius, opacity [W].
  - **Motion:**
    - workspace switch animation (dropdown with preview);
    - window open, window close;
    - speed multiplier (0 = off);
    - (adv) curve editor with a bezier preview [W].
  - **Focus behaviour (adv):**
    - focus follows mouse, warp pointer to focused window, raise on focus [W].
- **Window rules** ◐ (raw editor today)
  - A list of rules. Each rule has a match (app-id or title, regex) plus actions: float, size, position, workspace, monitor, opacity, no border, fullscreen, pinned [W].
  - "Pick a window" button [W pick-window, which is on the TODO].
  - Test rule against open windows.
- **Workspaces**
  - Count (fixed or dynamic), names, per-monitor or shared, empty workspace behaviour, workspace switch wraps [W].
- **Alt+Tab & overview**
  - Switcher style (list, previews, icons), which windows (this workspace / all / this monitor), delay before showing, show labels [S].
  - Overview: live previews [W live overview], zoom, gesture.
- **Gestures**
  - Touchpad swipes (3 and 4 fingers × 4 directions), each mapped to an action from a dropdown (workspace next/prev, overview, scroll columns, none) [W].
- **Tides** ★ [W, design pending]
  - Contexts and depth-moods. Rows exist as unavailable with "coming in TideWM".

### INPUT
- **Keyboard** +
  - Layouts (add, remove, reorder), switch shortcut, repeat delay and rate (with a test field), numlock on start, compose key [W].
- **Shortcuts** ◐
  - Searchable table grouped by category: windows, workspaces, layout, apps, shell, media.
  - Record a shortcut by pressing the keys.
  - Conflict detection across scopes, with a `danger` badge and a "swap" or "replace" offer.
  - Reset per row.
  - Complex multi-line bindings open in the raw editor ●.
- **Mouse** +
  - Speed, acceleration profile (flat or adaptive), natural scroll, left-handed, scroll speed, middle-click paste [W].
- **Touchpad** +
  - Tap to click, tap-and-drag, disable while typing, natural scroll, two-finger or edge scrolling, speed, click method [W].
- **Gamepad & tablet** +
  - Detected devices; tablet mapped to a monitor, pressure curve [W]; gamepad test screen [T, detected].

### DISPLAYS
- **Displays** +
  - Drag-to-arrange canvas of outputs (names come from IPC; nothing hardcoded), with snap-to-edge.
  - Per output: resolution, refresh rate, scale (fractional steps), rotation, VRR (off / on / fullscreen only), primary output, enabled.
  - "Identify" flashes big numbers on each screen [S].
  - Risky changes use the revert countdown.
  - (adv) HDR [W, future]; tearing for games [W, hardware half is on the TODO].
- **Night light** +
  - On/off, schedule (sunset–sunrise using a manually entered location, or fixed times), temperature with a live preview, quick toggle in the shell [S or W gamma].

### SOUND
- **Sound** + [T]
  - Output device, volume, balance; input device, input level meter.
  - Per-app volumes with app icons; mute toggles.
  - (adv) Over-amplification to 150%.
- **System sounds** + [S]
  - Event sounds on/off, volume, sound pack (folder), preview button per event.

### NETWORK & DEVICES
- **Wi-Fi & Ethernet** + [T]
  - List of networks with signal, connect with a password dialog, forget, hidden network, metered, IP details (adv).
- **VPN** + [T]
  - Profiles (WireGuard/OpenVPN through NetworkManager if detected), connect toggle, import file.
- **Bluetooth** + [T]
  - Power, discoverable, nearby and paired lists, pair, connect, battery levels shown on the panel [S].
- **Quick share** + [T, LocalSend if detected]
  - Receive on/off, folder, device name.

### SYSTEM
- **Notifications** ◐
  - Duration ●, max visible ●, start in DND ●.
  - Position, history length, per-app rules (mute, no popup, priority), sounds, DND schedule [S].
- **Power & idle** ◐
  - Power profile [T]; suspend after; lid action; power button action; low-battery warning and action [S/T].
  - Blank and lock timers move to Lock screen and are linked from here with next door.
- **Screenshots & recording** + [S]
  - Folder, file name pattern, format, include cursor [W cursor capture bug is on the TODO], copy to clipboard, recorder quality, audio source.
- **Startup apps** ●
  - List with add, remove and a "test now" button (+).
- **Default apps** + [T xdg-mime]
  - Browser, files, terminal, text editor, images, video, music, PDF, mail, archives. Each row has an app picker with icons.
- **Updates** ●
  - All existing rows ●, plus "check now" and the last-check time.
- **Plugins** + [S]
  - Installed plugins with enable/disable, each plugin's own settings page listed under this section, and a catalog (later).
- **Accessibility** +
  - Text size (scales the whole shell and this app).
  - Reduce motion (sets every animation in this spec to its reduced form).
  - High contrast (switches the derived tokens: edge 25%, glass 0, glow at full alpha).
  - Magnifier [W], sticky keys [W], focus highlight size.
- **Account** ●
  - Avatar ●, display name ●, change password ●, home folder ●.
- **About** +
  - System info (CPU, GPU, RAM, kernel, distro: all detected), TideWM version, shell version, detected backends list, "copy system info", "report a problem" (opens the repo issue page with the info prefilled).

### EXPERT
- **Config files** ●
  - Backups list with dates, diff view, rollback ●; external-change log; open in editor.
- **TideWM config** ◐
  - The current included-file editor ●, with Wave syntax highlighting and validation on save.
- **IPC & scripts** +
  - Event log viewer (live).
  - Custom commands bound to events (e.g. "on output connected run …") [S].
- **Gaming mode** ★ [S/W]
  - Toggle and auto-enable for listed apps.
  - What it turns off: animations, blur, atmosphere, popups.
  - Tearing [W].
  - Tuner (later).
- **Developer**
  - Debug overlay [S], reload shell, open logs, show row ids (shows the registry id next to every row, for bug reports).

---

## 9. Animation

Durations are in milliseconds. "Out" means OutCubic unless stated otherwise.

| What | Animation |
|---|---|
| Window open | opacity 0→1 and scale 0.98→1, 200, Out |
| Page switch | the old page fades out 90, the new page fades in and slides up 8→0 px, 180, Out; the header comes in first and groups follow with a 25 ms stagger (at most 6 groups) |
| Sidebar selection | one indicator moves to the new item, y and height, 220, OutQuint; the gradient fades in behind it |
| Hover (rows, items, buttons) | colour 120, Linear |
| Switch | knob x 160, OutBack (overshoot 1.2); track colour 160 |
| Segmented | the pill slides 200, Out |
| Slider | value follows the pointer with no delay; on release the knob glow pulses once (glow alpha 0→40%→0, 300) |
| Stepper | the value flips: old slides up and fades, new slides in from below, 120 |
| More… fold | height 240, Out; chevron rotates 0→180, 240; rows fade in with a 30 ms stagger (at most 8) |
| Row preview | height 0→64, 220, Out; the scene loops at its own speed and pauses when off-screen |
| Search dropdown | opacity plus scale 0.98→1 from the top, 140; results re-sort with a 120 move |
| Jump to row (search, undo, deep link) | smooth scroll 260, OutQuint; the row then flashes twice (background `glowSoft` 0→100%→0, 300 each) |
| Undo chip | appears by sliding in from the right 10 px plus a fade, 180; the label cross-fades 120 when it changes |
| Validation error | the row shakes ±4 px three times, 240 total; the `danger` hairline under the row fades out over 1200 |
| Toast | slides up 12 px with a fade, 200; auto-dismisses after 4000 (errors stay until dismissed) |
| ★ new | on first view: scale 1→1.25→1 and a glow pulse, 400, once |
| Theme change | every token ColorAnimation 300, Linear (`Behavior on color` in the Theme singleton) |
| Display revert countdown | a ring stroke draws 15000, Linear; the number ticks every second |
| Marine snow | particles fall 6–14 px/s with a 3 px sine sway (6–10 s period) and respawn at the top; lifetime equals one window height |
| Light shafts | opacity breathes ±15% over 12 s, InOutSine, looping |
| Live value change from IPC | the value flashes once in `glow`, 300 |

**Reduce motion** (Accessibility or the system setting):
- Every slide, scale, stagger and shake is off.
- Fades of 100 ms or less stay.
- Snow and shafts become static. Snow is drawn once as a texture with no particle system.

**Performance:**
- Pause the particles and the shaft breathing when the window is unfocused for 10 s, minimized or hidden.
- Cap atmosphere repaints at 30 fps.
- An idle window must use 0% CPU.

---

## 10. Accessibility

- Text contrast is at least 4.5:1. The Colours page warns when a custom theme fails, and This app does too.
- The focus ring is always visible on keyboard focus.
- Every icon-only button has an accessible name.
- Every row exposes label, hint, value and state to AT-SPI through Qt Accessible.
- Touch targets are at least 24 px in compact density and at least 32 px in normal.
- Text size scales everything without clipping. Layout uses implicit sizes, never fixed heights for text.

---

## 11. Tests and acceptance

1. Registry tests from Section 6.
2. ConfigStore tests (existing), plus: settings.wave include handling, override detection, atomic write, refused write on a validation error.
3. QML tests:
   - every page loads with each of the 4 shipped themes and a custom theme;
   - at 860×560 and 1920×1080;
   - in compact and roomy density;
   - with reduce motion on;
   - with no warnings in the log.
4. A backend-missing simulation: hide `nmcli` and `bluetoothctl`. Those pages must show unavailable rows, not crash.
5. A nested TideWM run, where Codex must:
   - change layout, gaps, column width and focus ring, and see each one apply live;
   - undo all four;
   - make a display change and let the revert dialog expire.
6. A grep check: no `#xxxxxx` colour literals in `settings/qml` outside the Theme singleton, and no `/home/`, output names or distro names anywhere.

---

## 12. Build order

1. Theme singleton with the derived tokens, the atmosphere background, the window chrome, sidebar, page header, group, row, and all the controls from Section 5. Rebuild the existing 11 pages on top of them without losing any feature.
2. Registry, renderer, search, undo, new stars, deep links, next door, More….
3. The TideWM settings.wave pipeline, then Desktop · TideWM pages (Windows & workspaces first: it's board J), then Input and Displays.
4. Colours & theme (J2) and This app (J3).
5. System pages through detected backends: Sound, Network, Bluetooth, Power, Default apps, Notifications.
6. Home, Presets, About, Expert pages.
7. Every row still marked [S] or [W] stays visible as unavailable, and each one becomes a line in the Abyssal and TideWM TODO.md under "settings app needs:".

Do one phase per commit series, with tests passing at each step. Don't start a phase before the previous one is verified in a nested TideWM run.

---

Before you give this to Codex, check two things against your own decisions:

- **Live apply vs. Draft/Apply:** the current app uses Draft/Apply for everything. This spec makes simple settings apply live with undo and keeps Draft/Apply for multi-field edits.
- **The `settings.wave` include:** the app writes its own file instead of editing your `config.wave`. If you'd rather it edit `config.wave` directly, Section 7.2 needs changing.

The TideWM and shell keys named in Section 6 and the inventory are proposals; Codex should map them to the real ones.