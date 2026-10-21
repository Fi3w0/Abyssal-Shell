# Moonlit Shell releases

Moonlit Shell is no longer maintained; this branch keeps it as it was. The
repository's main branch is now Abyssal Shell. Each release below is still
reachable through its tag (`moonlit-v0.2.0-beta`, `moonlit-v0.0.1-beta`).

## 🌙 Moonlit Shell v0.2.0 (beta)

Tag `moonlit-v0.2.0-beta`, published 2026-07-15.

## Headline: Moonlit Settings

A standalone Go/Fyne app that themes the whole shell live, no QML editing required — accent color, Catppuccin palette (Mocha/Macchiato/Frappé/Latte), wallpaper-driven color via `wallust`, bar layout and position (top/left/right, islands/classic), Hyprland gaps/blur/animations, and a full keybind editor with conflict detection. Ships installed to `~/.local/bin`, shows up in Rofi, opens with `Super`+`,`.

## Also new since v0.0.1-beta

- **Window overview** (`Alt`+`Tab`) — Mission-Control-style live thumbnail grid of every open window
- **Rofi modes** — emoji picker (`Alt`+`.`), keybinds cheatsheet (`Alt`+`/`)
- **Safe updates** — `install.sh --update` refreshes dotfiles without clobbering local edits (pacnew-style `.moonlit-new` merge files)
- Full palette switching across the whole shell, not just Mocha
- Refreshed screenshot gallery and README

## Known gaps

- Window overview is only verified single-monitor so far
- NVIDIA is still untested with these dots

**Beta — expect rough edges.**

## 🌙 Moonlit Shell v0.0.1 (beta)

Tag `moonlit-v0.0.1-beta`, published 2026-07-07 (pre-release).

## 🌙 Moonlit Shell v0.0.1 — first tagged beta

A handcrafted Arch Linux desktop: **Hyprland** + a **custom Quickshell** interface, soaked in Catppuccin Mocha. This is the first tagged snapshot — a daily-driver on a ThinkPad T14, now pinned so people have a stable point to clone from while `main` keeps moving.

### ✅ Verified working stack

These are the exact component versions this release was built and tested against:

| Layer | Component | Version |
|---|---|---|
| Compositor | Hyprland | 0.55.4 |
| Idle / Lock / Night | hypridle · hyprlock · hyprsunset | 0.1.7 · 0.9.5 · 0.3.3 |
| Bar & panels | Quickshell (QML) | 0.3.0 |
| Login | SDDM | 0.21.0 |
| Audio | PipeWire · WirePlumber | 1.6.7 · 0.5.15 |
| Network / BT | NetworkManager · BlueZ | 1.56.1 · 5.87 |
| Terminal · Launcher | Kitty · Rofi | 0.47.4 · 2.0.0 |
| Shell · Editor | Fish · Neovim | 4.8.0 · 0.12.4 |
| Files | Thunar · Ranger | 4.20.8 · 1.9.4 |
| Kernel | linux | 7.1.2 |

### 🧩 What's in the box

- A **custom Quickshell bar** + **11 panels** — Quick Settings, Audio/MPRIS, WiFi connect, Bluetooth pairing, Power, System Monitor, Calendar, Clipboard history, Wallpaper carousel, and OSD/toasts.
- **One coherent Catppuccin Mocha theme** across Hyprland, Kitty, Rofi, Fish, Neovim, Ranger, Fastfetch, GTK, and the SDDM login screen.
- A **616-line automated installer** with Minimal / Developer / Full tiers — shows a full plan before touching anything, backs up overwritten configs, and logs every command.

### 🔧 Under the hood (the interesting bits)

- **No monitoring daemon.** The bar reads CPU/RAM/temp/net straight from `/proc` and `sysfs`. Polling is split into a fast tick (cheap `/proc` reads) and a slow tick (expensive lookups), keeping idle cost around **~5 ms/s** — deliberately light for low-end hardware.
- **Portable CPU temperature.** Temp is resolved by sensor *name* (`k10temp` / `coretemp` / ARM `*_thermal`) with a thermal-zone fallback — works across AMD, Intel, and ARM without hardcoding, and costs ~3 ms vs ~45 ms shelling out to `sensors`.
- **Suspend-aware.** A wake detector notices the post-resume clock jump and refreshes every widget immediately, instead of waiting out each poll interval.
- **Live update count.** A `pacman.log` watcher re-checks pending updates the moment a transaction finishes.
- **Installer verified end-to-end** in a throwaway Arch container — a full `--minimal` run (packages + AUR builds of quickshell/awww/cliphist + dotfile deploy) completed cleanly. It also detects your CPU vendor to load the right temp module, and drops to plain output when piped to a log.

### 🚀 Install

```bash
git clone https://github.com/Fi3w0/Moonlit-shell.git
cd Moonlit-shell
./install.sh            # pick a tier; --minimal / --dev / --full to skip the menu
```

### ⚠️ Known rough edges (it's a beta)

- **AMD / Intel GPUs only** — NVIDIA is untested with these dots.
- Assumes **PipeWire + NetworkManager**; adjust interface names if yours differ.
- A couple of configs still reference an absolute home path — the installer fixes these, but manual installers should check `WallpaperPanel.qml`.
- Expect bugs. This is a snapshot of an actively-developed setup, not a finished product.

*`main` continues to receive fixes and features beyond this tag.* 🌙

