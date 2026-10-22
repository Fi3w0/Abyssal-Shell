# Settings coverage map

Fiw supplied “Settings map — what Abyssal should cover@2x.png” on 2026-10-22.
This is the intended two-level navigation and coverage reference: section → page.
It describes 47 pages, not 47 implemented pages. Keep configuration text editing
under Expert; ordinary settings need controls connected to their real storage.

| Section | Intended pages |
| --- | --- |
| Home | Home; Presets |
| Look | Colours & theme; Wallpaper; Fonts; Icons & cursor; Panels; Widgets; Launcher; Lock screen; OSD & popups |
| Desktop · TideWM | Layout; Windows; Window rules; Workspaces; Animations; Alt+Tab & overview; Gestures; Tides |
| Input | Keyboard; Shortcuts; Mouse; Touchpad; Gamepad & tablet |
| Displays | Displays; Night light |
| Sound | Sound; System sounds |
| Network & devices | Wi-Fi & Ethernet; VPN; Bluetooth; Quick share |
| System | Notifications; Power & idle; Screenshots & recording; Startup apps; Default apps; Updates; Plugins; Accessibility; Account; About |
| Expert | Config files; TideWM Config; IPC & scripts; Gaming mode; Developer |

## Implemented in this pass

Colours & theme: all 13 palette roles, saturation/value plane, hue/saturation/value
sliders, validated hex entry, named theme copies, theme selection, JSON import
and export, desktop sample preview, contrast ratios, opacity and corner controls.
The primary accent also drives Settings' glow; there is no independent glow theme.
Shipped and generated wallpaper palettes are copied before editing. Drafts become
persistent through Save changes. Export explicitly writes a portable JSON file.

Panels: named snapshots of the entire v2 layout, preview before loading,
import/export, current-display preview, edge/shape/alignment/length/thickness,
floating/surface/visibility. Snapshots retain output names, widget order, widget
objects and options, plus unknown layout fields. Loading replaces the layout
draft; Save changes applies it. Widget arrangement still opens the live editor.

Theme JSON lives under `$XDG_CONFIG_HOME/abyssal/themes`; named panel snapshots
under `$XDG_CONFIG_HOME/abyssal/panel-presets`. Active settings continue to use the
existing appearance.json and layout.json files. The settings store validates,
checks external modifications, backs up and atomically saves these documents.

## Remaining coverage

The current app has 14 pages. Several map pages remain combined in Windows &
workspaces, Motion & effects, and Keyboard & touchpad; many system pages are not
yet implemented. This map must not be represented by inert controls or links.
Home and whole-setup Presets are distinct from the theme/panel snapshots above.
Global search/history and per-setting discovery still need work.

GTK, Qt/Kvantum and terminal palette application remain unimplemented. The theme
preview and page do not advertise working switches for these integrations.
Saving currently reaches Abyssal and its lock screen through the shell theme
service, this settings app, and the compositor's existing included theme file.
No TideWM source changes are part of this work.
