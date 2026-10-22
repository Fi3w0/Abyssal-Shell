# Abyssal Shell: to do

## Current fixes — ordered queue

New issues join this queue; finish the whole queue before stopping.

1. [x] Restore the crashed shell through `abyssal-session`; inspect the core.
   Qt crashed in context-menu event delivery (`QQuickItem::mapToScene`).
   Clipboard drag changes were rolled back, tested separately, then restored.
   The underlying Qt fault is diagnosed, not patched in Qt itself.
2. [x] Constrain widget hitboxes to their slots and size them from content;
   preserve the whole update count as its number of digits changes.
3. [x] Centre the Wi-Fi icon when its text is hidden.
4. [x] Render screenshot notification previews sharply.
5. [x] Centre the calendar's empty notification state.
6. [x] Make the clipboard popup draggable by its header; test separately
   before putting it back into the live shell.
7. [x] After reboot: remove the obsolete kernels after verifying Nyx and NVIDIA.
8. [x] Fix Quick Settings opening away from its panel/button (reported after reboot).
9. [x] Update settings: interval, manual package manager, Arch AUR helper,
   Fedora repository selection, and Flatpak toggle.
10. [x] Static/animated wallpapers with awww transitions integrated into the picker.
    Native image fallback, duration slider/input and fill/fit per output.
    Tested in nested TideWM; preview windows stay floating on HDMI locally.

11. [x] Named wallpaper transition scripts: dissolve, undertow, current, bloom, sink.
    Incoming videos switch directly: covering first frames can stall TideWM
    callbacks. Image transitions and outgoing video snapshots are supported.
12. [x] First standalone Qt settings app: themes, wallpapers, shortcuts, TideWM
    files, updates, notifications, idle, Account and startup apps. See settings/README.md
    for the working scope and the remaining dedicated compositor/widget forms.

Decided with Fiw on 2026-10-21. Discuss the design of each item before
building it. The installer and the settings app are tracked separately.

## Roadmap — layer by layer (2026-10-22)

Build one layer at a time; discuss every design with Fiw before building UI
(an artifact mock-up first). Abyssal is TideWM's test bench: every TideWM
bug or missing protocol it runs into goes to TideWM's own TODO, never worked
around with compositor knowledge in the shell. Reference for ideas (not
looks): AngelOS-Dotfiles `modules/settings` (category tree in `tree.json`,
pages built from small groups, search with synonyms, setup wizard in the
same app).

### TideWM side — what TideWM builds vs what Abyssal builds

TideWM's own queue is `~/Documents/Proyects/TideWM/TODO.md`. This mirror
says, per TideWM item, whether Abyssal needs any work. "TideWM only" means
the shell builds nothing (binds go in the user's TideWM config, not here).

| TideWM layer | TideWM builds | Abyssal builds |
| --- | --- | --- |
| 1 · niri column/window actions (set width/height, presets back, wrap focus, move column to index/workspace, floating↔tiling focus, urgent/inhibit/touchpad toggles, reload) | the actions | nothing; settings app may later offer a keybind editor that writes them |
| 2 · monitor actions (focus/move window/column/workspace between monitors) | the actions | nothing (bind them in TideWM config) |
| 3 · `pick-window`, `pick-color` | IPC requests | a colour-picker widget/launcher action using `tidectl pick-color`; window info in the switcher or a debug page via `pick-window` |
| 4 · dynamic screencast target | portal source + actions | optional quick-settings tile to switch the shared window |
| 5 · live overview | the overview itself | nothing; the panel's workspace widget can open it with `toggle-overview` |
| 6 · more workspace animations | the styles | a picker in the settings app (Layer 1 step 5) |
| Already shipped (0.90.166) · IPC geometry, `layers`, `focused-output`, output/mode/engine/scroll events | done | replace polling with `tidectl subscribe` (outputs, modes, Scroll strip); show a mode indicator; use `layers` in diagnostics |
| Known TideWM bugs (screenshot cursor, `wl_surface.enter`) | the fixes | nothing; report anything else Abyssal hits to TideWM's TODO |

### Layer 1 — settings app rework (start here)

Goal: a real settings app a user can live in instead of editing config,
good-looking, following the active theme, without the odd options.
1. [ ] Audit the current app: every option, where it writes, keep / merge /
       drop. Show Fiw the list.
2. [ ] Propose the structure (category tree like System, Devices, Network,
       Personalisation, Windows & workspaces, Apps, Updates, About) and a
       look; mock-up for Fiw to approve.
3. [ ] Rebuild on the approved design; theme from the active Abyssal theme.
4. [ ] Search across every setting, with synonyms and recent searches.
5. [ ] Window and workspace pages drive TideWM through Wave/IPC (engine,
       Scroll widths/presets/centering, animations, binds), validated before
       writing, never Plasma config.

### Layer 2 — system pieces

- [ ] Polkit authentication dialog (Quickshell PolkitAgent), themed
- [ ] Alt+Tab styles (the current switcher plus alternatives)
- [ ] Workspace-switch animation picker (the styles themselves live in TideWM)
- [ ] More panel customisation: new bar shapes (island, dock, capsules…) and
      finer per-panel options

### Layer 3 — first run and extensibility

- [ ] Setup wizard on first login (look, theme, wallpaper, panels, apps)
- [ ] Installer script (distro-agnostic, init-agnostic, asks before installing)
- [ ] Plugin system (sandboxed widgets/pages, a template, docs)

### Layer 4 — integrations

- [ ] Voice input (VoxType or similar, optional)
- [ ] Gaming tuner (per-game profiles; only generic, portable knobs)

### Layer 5 — fun

- [ ] Achievements, Steam-style toasts and a gallery ("installed Abyssal",
      first theme, first plugin…); off switch in settings

## Next

- [x] **Crash recovery.** `scripts/abyssal-session` on TideWM's spawn line:
      restarts after a crash (1, 2, 4, 8 s), gives up with a notification
      after 5 crashes in 2 minutes, keeps `last-crash.log`, toasts after a
      recovery; `ipc call shell restart` restarts on purpose.
- [x] **Feedback popups for keys.** The OSD shows the new keyboard layout
      ("RU  Russian") on every switch, and the mic state on any mute change
      (rose while muted). No mic keybind, on purpose.
- [x] **Wallpaper picker.** Looping coverflow on the monitor it opens on
      (Super+Shift+K, quick-menu tile, bar widget), momentum on hold,
      live video preview, / search, W = theme from wallpaper (k-means
      palette in `scripts/wall-index`). Themes are JSON files now; a
      theme editor waits for the settings app.
- [x] **Removable drives.** udisks2 (lsblk + gdbus monitor + udisksctl, polkit
      allows it without an agent): toast on plug-in (click opens the panel),
      bar widget shown while a drive is in, quick-menu tile, panel with
      partitions, free space, Open (mounts first) and Eject (power-off).
      Toasts are clickable now (default action).
- [x] **Updates widget.** `scripts/updates`: Portage (private shallow repo
      copies + emerge -puDNv, from Apdatifier Gentoo, sharing its copy),
      pacman + AUR, DNF, APT, XBPS, Flatpak. Bar widget, quick-menu tile,
      panel with important / selected / dependency, Update all and Sync in
      a terminal (`scripts/terminal`), toast once per batch, busy guard.
- [x] **VPN toggle.** NetworkManager VPN/WireGuard via nmcli (+ nmcli monitor):
      quick-menu tile toggles the last used one, VPN section with switches
      on the Wi-Fi page, shield badge on the network widget while one is up.
      Hidden while none are set up.
- [x] **Claude Code and Codex usage widget.** Claude: `scripts/claude-statusline`
      as Claude Code's status line saves its rate_limits (no token use).
      Codex: newest rate_limits in ~/.codex/sessions. Status pages of
      Claude and OpenAI. Bar widget (two rings), quick-menu tile, panel
      with 5-hour / weekly bars and reset times.

## Later

- [ ] **Night light.** TideWM has `wlr-gamma-control`, but the real colour
      change is unverified on hardware; test it before building a tile and
      a schedule.
- [x] **Notifications.** Pictures apps attach (toast and centre), up to three
      action buttons on toasts, clickable toasts, history saved for a week
      and restored after a restart or reload (without duplicates).
- [x] **Launcher modes.** Shell actions by name (lock, log out, sleep, reboot,
      shut down, wallpaper, updates, clipboard, edit panels, "theme <name>")
      and `>command` to run in a terminal.
- [ ] **Matching app themes in TideWM.** GTK and Qt apps follow the Abyssal
      palette, set only through TideWM's `env {}`, never Plasma's config.
- [x] **Window switcher (Alt+Tab).** Off unless bound:
      `bind Alt+Tab { "spawn:qs -c abyssal ipc call shell switcher" }`.
      Recent windows first, previous one picked, Tab moves, releasing Alt
      / Enter / click switches, Esc cancels. Not bound for Fiw.
- [ ] **Real screen power-off on idle,** once TideWM's DPMS works on the
      RTX 3060 (idle blanking is a black overlay until then).

## Undecided

- [ ] Lock screen extras: media controls, notification count, battery,
      keyboard layout.

## Not Abyssal's job

- **Autostart:** TideWM has its own startup list (`spawn`), separate from
  Plasma's `~/.config/autostart` on purpose.
- **Polkit agent:** belongs to TideWM.

## Leftovers from earlier sessions

- [ ] Tune the window shadow and check the ripple effect.
- [ ] Pick a window animation preset (`look.wave` is on `tide`).
- [ ] Super+Shift+Q (quit TideWM) sits one Shift away from Super+Q (kitty);
      maybe move it.
- [ ] Push the TideWM commits `e5f9bcf` and `c833b99` when ready.
