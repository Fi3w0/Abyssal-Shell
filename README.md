# Abyssal Shell

A configurable Quickshell desktop shell for TideWM.

Run with `qs -c abyssal` when this directory is linked to
`~/.config/quickshell/abyssal`.

If all panels are deleted, an **Add panel** button remains available on the
desktop. You can also reopen editing at any time with
`qs -c abyssal ipc call shell edit`.

## Appearance

Trench / Violet is the default palette and control style. The original
Abyssal Tide palette remains selectable in **Edit panels → Appearance**.
The adjacent UI font setting switches between Sans and Mono. These are
shell-wide settings; panel layout presets remain separate.

Appearance choices are stored in `$XDG_CONFIG_HOME/abyssal/appearance.json`
(normally `~/.config/abyssal/appearance.json`). No appearance file is needed
to use the defaults. Unknown settings are retained when saving; an invalid
file is left untouched and appearance controls are disabled until it is fixed.

Existing panels, widget options, pinned applications, and monitor layouts
remain in `~/.config/abyssal/layout.json`. Appearance changes do not replace
this layout or remove widgets.

## Logo

`assets/abyssal.svg` is the Trench currents mark, used by `builtin:logo`.
Its amethyst, lilac, and muted cyan come from the shell's palette.
Logo and Launcher widget options also offer the Manta, original line waves
(`builtin:logo-line`), the earlier Undertow study (`builtin:undertow`), and
the grid. Existing theme-icon and image-file support remains available.

The shell uses the system icon theme. Icon
providers are requested at the screen's physical pixel size. OBS uses its
installed PNG export to avoid clipping artifacts in Qt's SVG rendering,
with normal theme resolution as a fallback if that PNG is unavailable.

## Widget inspector

Click any widget in edit mode to select it in the shared inspector. New
widgets are selected automatically. The Panel tab keeps layout settings
available; the Widget tab follows the last selection. Each widget has its
own applicable settings, including icon images, clock formats, battery
thresholds, temperatures, readouts and visibility. Numeric options support
both sliders and direct input.

GPU usage and temperature widgets offer a detected device selector. GPU
IDs use PCI addresses rather than driver card numbers. The collector uses
read-only DRM/sysfs telemetry and optional `nvidia-smi`; unsupported readings
show a dash. Intel usage is unavailable when its driver exposes no readable
usage counter. Suspended devices are not woken for monitoring.

Runtime dependencies include Python 3 (standard library only), Qt Quick
Controls and Qt Quick Dialogs. Layout and appearance follow XDG config
paths; optional raster assets follow XDG data paths. Fonts fall back to
installed families. No monitor name, user home or GPU model is embedded in
the runtime defaults.

## Update checks

Open Updates → Settings, or select an Updates widget in the panel editor.
These controls share `~/.config/abyssal/updates.json`: check interval in
minutes (0 means manual only), login and transaction checks, package
manager and Flatpak. Existing ignore/important package rules are retained.
Only installed managers are offered. Arch users can include AUR packages
and choose paru or yay. Fedora users can select among enabled repositories,
including already configured COPR and RPM Fusion repositories. The same
manager/repository choices govern checks and upgrades.

## Wallpapers

The wallpaper picker supports static images and videos per monitor. Its
sliders button opens renderer, fill/fit, transition and duration settings.
Both duration controls (slider and number) save to the XDG config file
`abyssal/wallpaper.json`; existing folders and monitor choices are retained.

Install `awww` and `awww-daemon` for image transitions such as fade, wave,
wipe and grow. Abyssal owns a separate `abyssal` daemon namespace and starts
it automatically. Without awww, the built-in Qt image renderer supports
static wallpapers and fades. Videos use `mpvpaper`, with one owned player
per configured output. Changes involving videos animate a captured wallpaper
frame into the new background using the selected transition recipe. These captures contain only the wallpaper,
and are temporary. No additional wallpaper application is required.

The visual study in `design/` includes sample data and illustrates a broader
direction; its sample layout is not installed over your actual panels.

## Settings app

The standalone Qt application opens from the quick menu gear, the launcher,
or `scripts/abyssal-settings`. Theme edits, keybinds, configuration files,
startup apps, Account, updates, notifications and idle controls share the
shell configuration. See [settings/README.md](settings/README.md) for building,
backup behaviour and the current scope.

Named transition scripts live in `scripts/wallpaper-transitions/`. For example,
`undertow /path/to/wallpaper.png --output OUTPUT` applies a wallpaper with the
wave recipe; omit the path to select that recipe for future changes.

Incoming videos currently switch when ready, without an overlay transition,
to avoid a first-frame callback stall observed in TideWM. Image changes,
including changes from a video snapshot, support the transition recipes.
