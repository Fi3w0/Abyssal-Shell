# Abyssal Shell: to do

Decided with Fiw on 2026-10-21. Discuss the design of each item before
building it. The installer and the settings app are tracked separately.

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
- [ ] **Removable drives.** A notification or popup when a drive is plugged
      in, with open and eject (UDisks over D-Bus, no new packages).
- [ ] **Updates widget.** Portage updates, like Apdatifier in Plasma.
- [ ] **VPN toggle.** NetworkManager VPN connections: a quick-menu tile
      and/or the Wi-Fi page.
- [ ] **Claude Code and Codex usage widget.** A bar widget with a panel
      showing the 5-hour and weekly usage and service status for both.
      Research the data sources first: local session logs
      (`~/.claude/projects`, `~/.codex/sessions`, which records rate-limit
      windows) and the public status pages.

## Later

- [ ] **Night light.** TideWM has `wlr-gamma-control`, but the real colour
      change is unverified on hardware; test it before building a tile and
      a schedule.
- [ ] **Notifications.** Images (screenshots, covers), history that
      survives a shell restart, action buttons on the toasts.
- [ ] **Launcher modes.** A few, not many: candidates are running a shell
      command and actions like lock or reboot from the search field.
- [ ] **Matching app themes in TideWM.** GTK and Qt apps follow the Abyssal
      palette, set only through TideWM's `env {}`, never Plasma's config.
- [ ] **Window switcher (Alt+Tab).** Add it as an option, off for Fiw.
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
