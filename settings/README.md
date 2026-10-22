# Abyssal Settings

A standalone Qt 6 / C++ settings application with a Qt Quick interface.
It runs independently of Quickshell. Live panel editing and the wallpaper
picker use the running shell's IPC; configuration edits also work offline.

## Build and install

Requires CMake, a C++17 compiler, Qt 6 Quick, Quick Controls 2 and Network.
Qt Test is needed when BUILD_TESTING is enabled. Runtime QML modules include
QtQuick.Dialogs and QtQuick.Effects. TideWM's `wavefmt` must be on PATH to apply Wave edits;
without it the app refuses those writes. It checks syntax, not action semantics.

```sh
cmake -S settings -B build/settings -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$HOME/.local"
cmake --build build/settings -j 4
ctest --test-dir build/settings --output-on-failure
cmake --install build/settings
```

Launch `scripts/abyssal-settings`, or `qs -c abyssal ipc call shell settings`.
The launcher adds the user's local bin directory to PATH. The shell's quick
menu gear and app launcher also open the app. A lock/socket pair reuses the
existing app instead of opening duplicates. No monitor name is compiled in.

## What works

The Drowned archive interface follows the active theme throughout. **Look › This
app** (Ctrl+,) previews the water gradient or blurred image wallpaper, atmosphere,
glass, glow, density, installed font and selection style. Reduced motion freezes
the atmosphere. App preferences use `abyssal/settings.json`; preview changes
stay in a draft until Apply. Reset preserves unknown keys and custom themes can
store an app look. The original features remain available. Desktop has graphical windows, motion
and input pages; raw configuration editors are in Expert. Panels has controls
and a preview, shortcuts record keys and choose actions/apps, and startup apps
uses an installed-app picker. See docs/AUDIT.md for storage and scope.


- Theme selection, automatic editable copies, inline HSV/hex colour editing,
  named theme presets, JSON import/export, contrast checks and a desktop preview.
  Theme opacity and rounding update the preview and saved theme.
- Wallpaper selection per detected output, transition recipes and duration.
- Panel controls and display previews, named layout snapshots, JSON import/export,
  and preview before loading. Widget options and output names survive round trips.
  Widget arrangement remains in the existing live editor.
- Record/change single-line shortcuts from config.wave and static Wave includes.
- Graphical TideWM settings plus Expert file editing, preserving comments and unknown keys.
- Startup apps: add, enable/disable and remove. Additional apps are written to
  `abyssal-autostart.wave`, included from config.wave. Existing startup commands
  are preserved; apps launch on the next login, never when applying settings.
- Account display name and avatar, used in the shell's quick menu. Password
  changes run the system passwd program in a terminal; the app handles no passwords.
- Update checks, manager/AUR options, notification limits and idle/lock timers.

Edits stay in memory until Apply. All changed files are checked before writes.
The app refuses external modifications or retargeted symlinks, preserves symlinks
when saving, uses QSaveFile and creates private backups plus a path manifest
under `$XDG_STATE_HOME/abyssal/settings-backups`. If a later write fails, earlier
writes are rolled back when they still match this app's write. Other edits are
not overwritten during rollback. Reload/close asks before discarding drafts.

The user-provided 47-page coverage reference and current scope are recorded in
[docs/SETTINGS-MAP.md](docs/SETTINGS-MAP.md). Preset creation/loading stays in the
draft until Save changes; Export writes the explicitly selected file immediately.

## Next development

The desktop registry and managed TideWM writes are implemented. Global per-setting
search/recent searches, undo/live apply and the wider system inventory remain.
Window geometry persistence and pin-on-top are not implemented yet.


Build native panel/widget forms around the existing widget schemas; add dedicated
TideWM display, input, animation and window-rule pages; improve keybind recording
and scope-aware conflict detection for submaps. Default apps, fonts and matching
GTK/Qt themes are further system integrations. Multi-line bindings and advanced
Wave/Lua expressions remain available in the file editor. Fedora repository
selection is currently in updates.json and the existing shell update inspector.

The design research is recorded in docs/DESIGN.md. No upstream implementation
was copied into this app.

Incoming videos currently switch when ready, without an overlay transition,
to avoid a first-frame callback stall observed in TideWM. Image changes,
including changes from a video snapshot, support the transition recipes.
