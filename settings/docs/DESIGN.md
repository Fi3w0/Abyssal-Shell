# Direction and references

The user requested a real Qt application for the entire rice, including themes,
keybinds, TideWM configuration, startup applications and account preferences.
The first implementation is native Qt 6 C++ with Qt Quick, independently launched
and using the same XDG configuration files as the shell. It is not a web wrapper.

References studied on 2026-10-21:

- [AngelOS settings map](https://github.com/MixaDoDs/AngelOS-Dotfiles/blob/main/.config/quickshell/angelos/docs/SETTINGS-MAP.md)
  and [settings window](https://github.com/MixaDoDs/AngelOS-Dotfiles/blob/main/.config/quickshell/angelos/modules/settings/SettingsWindow.qml):
  grouped navigation and a real toplevel settings window.
- [niri-caelestia configuration](https://github.com/AyushKr2003/niri-caelestia-shell/blob/main/config/Config.qml):
  shared configuration sections rather than independent copies of shell settings.
- [Noctalia architecture](https://github.com/noctalia-dev/noctalia/blob/main/ARCHITECTURE.md):
  boundaries between controls, shell features and services.

The current direction is the Drowned archive: theme-driven water gradients,
light shafts and marine snow, glass groups with corner brackets, JetBrains Mono
and a lit-edge sidebar. The approved canvas and specification are archived under
`design/`; implementation scope is recorded in STATUS.md. Settings use drafts and explicit Apply. Preserve existing widgets,
unknown configuration keys, comments, included files and symlink destinations.
Keep machine-specific output placement in local compositor preferences rather
than the application. Previews on this machine belong on HDMI, floating, without
stealing focus. Never restart the compositor to test settings.

Current limitations and next sections are listed in ../README.md. In particular,
TideWM has a syntax-checked file editor today; a full graphical editor for every
compositor option is not claimed.

Incoming videos currently switch when ready, without an overlay transition,
to avoid a first-frame callback stall observed in TideWM. Image changes,
including changes from a video snapshot, support the transition recipes.
