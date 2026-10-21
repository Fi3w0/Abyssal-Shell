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

The visual study in `design/` includes sample data and illustrates a broader
direction; its sample layout is not installed over your actual panels.
