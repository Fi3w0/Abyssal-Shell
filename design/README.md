# Trench / Violet

Run `bash design/preview.sh` from the repository. This standalone Qt Quick window
is a visual study with in-memory sample data. It does not load shell services,
change the active theme, or control the network, audio, power or compositor.

The user chose Trench, requested darker purple, slightly rounder elements and
Porthole's app icons, and asked for one focused revision after revisiting AngelOS.
The previous studies felt too similar. This version changes the shared material
and control language as well as the palette:

- Purple-black bodies, warmer header strips, recessed input fields, raised
  controls, subdued separators and a lavender selection state have distinct roles.
- The cut-corner frame remains, with rounded transitions, softer ordinary corners,
  a subtle vertical surface tone and a small offset shadow to establish elevation.
- Panels use flat idle controls; action buttons use raised faces, and active states
  use an inset violet face. Hover, press and keyboard focus are separate states.
- Full-color native app icons appear in the launcher, rail and dock. The existing
  Abyssal line icons cover system actions, with consistent size and stroke.
- The launcher, session controls, app context menu and notification share those
  rules. They are deliberately shown together for visual review.
- Label typography can be compared using the button above the study. It defaults
  to Noto Sans labels with JetBrains Mono readouts. `--labels=mono` retains the
  originally selected mono labels throughout. No fonts are installed.

## Reference inspection

I revisited AngelOS's two screenshots and read the original implementations for
theme roles, buttons, window framing, icon resolution, typography and menus:

- [GoldenGate.qml](https://github.com/MixaDoDs/AngelOS-Dotfiles/blob/main/.config/quickshell/angelos/services/GoldenGate.qml)
- [PxButton.qml](https://github.com/MixaDoDs/AngelOS-Dotfiles/blob/main/.config/quickshell/angelos/widgets/PxButton.qml)
- [PxWindow.qml](https://github.com/MixaDoDs/AngelOS-Dotfiles/blob/main/.config/quickshell/angelos/widgets/PxWindow.qml)
- [AppIcon.qml](https://github.com/MixaDoDs/AngelOS-Dotfiles/blob/main/.config/quickshell/angelos/widgets/AppIcon.qml)
- [MacText.qml](https://github.com/MixaDoDs/AngelOS-Dotfiles/blob/main/.config/quickshell/angelos/widgets/MacText.qml)

The design interpretation is role-based surfaces and consistent control states,
with different treatment for application and system icons. No AngelOS code,
graphics, pixel styling or global theming scripts were copied.

## Trying the study

Search the sample applications; use arrows and Enter to select. Right-click a
result to open its app menu. Its pin state is local and its window actions only
report the selection. Rail buttons show/hide the launcher and controls. Header
close buttons and notification dismissal work locally. Reset samples restores
everything. Mute buttons and sliders update sample values only. Power actions
only report the selection. Tab, Space and arrow keys use Qt Controls behavior.

```sh
bash design/preview.sh --wallpaper=file:///absolute/path/to/image.jpg
bash design/preview.sh --labels=mono
bash design/preview.sh --capture=/tmp/abyssal-trench-violet.png
bash design/preview.sh --width=1080 --height=760
```

The board is a 1440 × 850 composition scaled to fit the window, not the shell's
production layout. App icons reference installed files. The wallpaper argument
is optional. The mock clock, network and notification are sample content.

The real shell now has an additive Trench / Violet appearance preset, the
original Abyssal Tide palette, and selectable Sans/Mono labels. Shared colours
and control shapes are applied without installing this sample layout. The
default logo is now Trench currents; the manta and original waves remain selectable.
The shell was loaded in a nested installed TideWM instance before launching
in the native session. The full study geometry and the overlay exclusivity /
click-through issue remain separate work: the launcher/quick-settings toggles
still do not clear power-menu state.
