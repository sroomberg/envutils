# Omarchy machine config — ThinkPad X1 Carbon Gen 3 (`omarchy`)

Living reference for how **Steven Roomberg’s** Omarchy 4 (Quattro) / Hyprland laptop is customized after install, and how to **recreate** that environment from scratch. Written for humans and agents. No secrets — use local `.env` (gitignored) for bootstrap credentials.

| Item | Value |
|------|-------|
| Hostname | `omarchy` |
| User | `sroomberg` |
| Shell | zsh (+ Powerlevel10k from envutils backup) |
| OS | Omarchy 4.0.x, Hyprland (Lua config) |
| Model | Lenovo ThinkPad X1 Carbon Gen 3 (20BSCTO1WW) |
| CPU / RAM | Intel Core i7-5600U, ~7.6 GiB |
| GPU | Intel HD 5500 (i915) |
| Storage | 256 GB Samsung SSD, full-disk LUKS |
| Display | 2560×1440, scale **1.25** (Settings → Display) |
| Wi-Fi | Intel 7265 — prefer ethernet during install |
| Fingerprint | Validity VFS 5011 (138a:0017) — **abandoned**; passwords only |
| Firmware | UEFI; Secure Boot OFF |
| Prior migration | Ubuntu 24.04.5 LTS (`sroomberg-ubuntu`) → Omarchy 4 |

**Related envutils paths**

| Path | Purpose |
|------|---------|
| `linux/omarchy/CONFIG.md` | This document — desired state + recreate |
| `linux/omarchy/bootstrap.sh` | Post-install bootstrap (packages, SSH restore, reminders) |
| `linux/omarchy/.env.example` | Template for local `.env` (never commit `.env`) |
| `linux/omarchy/window-switcher/` | All-workspace Alt+Tab + macOS-style HUD |
| `env-setup/python/setup.sh` | Python via pyenv (after migration; prefer mise on Omarchy when possible) |
| `env-setup/ruby/setup.sh` | Ruby via RVM (legacy; prefer mise/pacman on Omarchy) |
| `zsh/setup.sh` | Powerlevel10k restore |

---

## Agent preferences (do / don’t)

- **Floating-first UX** on a small laptop: avoid auto-tiling that shrinks windows when more apps open; user resizes with the mouse or tiles deliberately (`Super+T`).
- **Left dock** always visible with Hyprland **exclusive zone** (`-x`) so windows do not overlap the dock.
- **Never edit** `/usr/share/omarchy` — Omarchy updates overwrite it. Overrides live under `~/.config/hypr` and `~/.config/omarchy`.
- **`.env` and secrets** stay gitignored; do not commit tokens or keys.
- **GitHub:** `sroomberg`; this repo: `envutils`.
- **Package management:** prefer `omarchy update`, `omarchy pkg add`, `omarchy install app`; toolchains via **mise** / pacman — not wholesale restore of old rvm/pyenv/snap/AppImage trees from Ubuntu.
- **Backup restore:** selective merge — never clobber `~/.config/omarchy` from an old Ubuntu backup.

---

## Window management (Hyprland)

Config files are under `~/.config/hypr/` (Lua). Omarchy merges personal overrides from `apps.lua`, `looknfeel.lua`, `autostart.lua`, `input.lua`, etc.

### Float by default

`~/.config/hypr/apps.lua`:

- `o.window(".*", { float = true })` — all windows float unless explicitly tiled.
- **Super+T** still tiles when Omarchy layout behavior is wanted.
- **Move / resize:** Super+left-drag move, Super+right-drag resize (Omarchy defaults).
- Helper terminals must not steal focus on output: `org.omarchy.terminal`, `org.omarchy.bash`, `TUI.float`, `com.mitchellh.ghostty` → `focus_on_activate = false`.
- **Chromium-based browsers:** override Omarchy’s force-tile tag so new browser windows stay on top of other floats:

  ```lua
  o.window({ tag = "chromium-based-browser" }, { tile = false, float = true })
  ```

### Look and feel

`~/.config/hypr/looknfeel.lua`:

- `border_size = 0` — no visible focus border.
- **`resize_on_border`:** keep **`false`** while the **left-edge dock** is in use. If `true` with an extended grab area, edge resize can fight the dock hover zone on the left. Optional edge resize (no Super) is possible only if the dock moves away from the left edge.
- Historically, maximize-on-title-bar-double-click was removed from Omarchy default `windows.lua` behavior on this machine (prefer manual sizing).

---

## Input (ThinkPad X1 Carbon Gen 3)

`~/.config/hypr/input.lua` — ThinkPad-specific profile. Edit via **Super+Space → Setup → Input** or the file directly.

| Setting | Value / notes |
|---------|----------------|
| `kb_options` | **`caps:capslock`** — sticky Caps Lock (overrides Omarchy/fcitx default `compose:caps`) |
| Compose / XCompose | No longer on Caps; personal sequences live in `~/.XCompose` (Multi_key). Use `compose:ralt` if you want XCompose on a modifier again. |
| Pointer | `sensitivity = 0.25` |
| Scroll | `natural_scroll = true`; touchpad `scroll_factor = 0.7` (snappier than Omarchy 0.4 default) |
| Touchpad | `clickfinger_behavior`, `tap_to_click`, `disable_while_typing`, **no** `middle_button_emulation` |
| TrackPoint | Device `tpps/2-ibm-trackpoint`: classic (non-natural) scroll, `sensitivity = 0.35` |
| Synaptics TM3072 | Per-device block matching clickpad name (`synaptics-tm3072-003`) |
| Gestures | 3-finger horizontal swipe → workspace change |
| Misc | `middle_click_paste = false` — reduces accidental primary-selection paste on ThinkPads |
| Terminals | Ghostty calmer scroll: `scroll_touchpad = 0.3`; other terminals 1.5 |

### Caps Lock bar indicator

macOS-style **⇪** when Caps is ON (hidden when off):

- `~/.config/omarchy/bar/modules/caps-lock.qml`
- Helper script (if present): `~/.config/omarchy/bar/scripts/caps-lock`
- Register in `~/.config/omarchy/shell.json` bar layout: `{ "id": "caps-lock", "type": "qml" }` (after keyboard layout module).
- Watches `/sys/class/leds/*capslock*/brightness` so it tracks real lock state including sticky Caps.

---

## Dock (nwg-dock-hyprland)

Always-visible **left** dock; **no auto-hide** (no `-d` hotspot).

### Start script

`~/.local/bin/start-nwg-dock`:

```bash
#!/bin/bash
if pgrep -f 'nwg-dock-hyprland -p' >/dev/null; then
  exit 0
fi
exec nwg-dock-hyprland \
  -p left \
  -i 32 \
  -f \
  -a start \
  -x \
  -l top \
  -lp start \
  -c "$HOME/.local/bin/nwg-dock-apps-launcher"
```

- **`-x`:** exclusive zone — windows layout beside the dock.
- **Grid / launcher button:** `nwg-dock-apps-launcher` → Omarchy apps menu (`omarchy-menu` toggle apps).
- **Guard:** use `pgrep -f 'nwg-dock-hyprland -p'` — `pgrep -x` truncates at 15 characters and misses the process.

### Autostart + systemd

- Hyprland: `~/.config/hypr/autostart.lua` → `o.launch_on_start("start-nwg-dock")`.
- User unit: `~/.config/systemd/user/nwg-dock.service` — `Restart=always`, `ExecStart=/home/sroomberg/.local/bin/start-nwg-dock`, `WantedBy=default.target`.

Enable if needed: `systemctl --user enable --now nwg-dock.service`.

### Pinned apps

Pin file: `~/.cache/nwg-dock-pinned` (Hyprland **class** names). Typical pins:

Nautilus, Ghostty, Chromium, grok-bot, Cursor, `com.anthropic.Claude`, Zed, 1Password, Obsidian — plus Discord / WhatsApp / X as added later.

**Known gap:** opening an already-pinned app sometimes spawns a **second dock icon** — still desired to fix.

---

## Shell and terminal

- **Default terminal:** [Ghostty](https://ghostty.org/) (not Foot).
- **Shell:** zsh with Powerlevel10k — restore from backup via `envutils/zsh/setup.sh` and merged rc snippets (do not replace Omarchy zsh defaults blindly).

---

## Apps and packages

| Area | Choice |
|------|--------|
| Editors | Zed, Cursor (`Super+Space → Install → Editor → Cursor` or `yay -S cursor-bin`) |
| AI | Claude Desktop (`com.anthropic.Claude`), Claude Code CLI |
| Passwords | 1Password app + CLI |
| Notes | Obsidian (AUR / menu — not Ubuntu snap) |
| Browser | Chromium (primary); register Claude **NativeMessagingHosts** for Chromium/Chrome → `/usr/lib/claude-desktop/resources/chrome-native-host`, then restart Chromium |
| Files | Nautilus |
| Trading | Zulu OpenJDK 21 for thinkorswim — install/launcher **incomplete** |
| Docker | Shipped with Omarchy; `Super+Shift+D` Lazydocker; default needs `sudo docker ps` unless sudoless Docker enabled in Setup → Security |

After bootstrap, re-auth: `gh auth login`, AWS CLI, Docker registries, 1Password browser extension.

---

## Display

- **2560×1440 @ 1.25** scale on this machine (readable without everything at 2×).
- Bootstrap log also mentions 2× as an Omarchy-friendly alternative if UI feels too small.

---

## Restore rules (from Ubuntu / Samsung backup)

**Restore (selective):**

- `~/.ssh`, `~/.gnupg`
- zsh / Powerlevel10k, Ghostty config
- `~/Documents`, `~/dev`, `~/src`, project trees
- Grok Bot data
- Optional: MesloLGS NF fonts, `~/.config/gh`, secret-broker

**Skip / do not wholesale restore:**

- Old Cursor / VS Code / Claude configs from Ubuntu
- rvm, pyenv, Ghostty AppImage, snap trees
- Entire `~/.config/omarchy` overwrite from backup

**Staging layout for bootstrap** (`BACKUP_ROOT`, default `~/Backups/omarchy-restore/`):

```text
~/Backups/omarchy-restore/
├── .ssh/
├── Documents/
└── …
```

Or mount external media (e.g. `/mnt/backup/omarchy-restore/`) and set `BACKUP_ROOT` in `.env`.

---

## Incomplete / queued

- thinkorswim + Zulu JDK 21 launcher polish
- Dock: dedupe icon when focusing an already-running pinned app
- Fingerprint enrollment abandoned intentionally

---

## Recreate from scratch (install + bootstrap)

> **WARNING:** Full-disk LUKS install **erases the entire SSD**. Back up home data (~42 GB+) first.

### Phase 0 — Backup

1. Copy to external drive or another machine:
   - `~/.ssh/`, `~/.gnupg/`
   - `~/Documents`, `~/projects`, `~/dev`, `~/src`
   - Selective `~/.config/` (Obsidian, etc.) — **not** all of `~/.config`
   - Export project `.env` files and tokens separately (never into git)
2. Note Ubuntu **Snaps** do not carry over (Firefox, Obsidian, 1Password, …).
3. Stage under `~/Backups/omarchy-restore/` or external mount for `BACKUP_ROOT`.

### Phase 1 — BIOS (before Omarchy ISO)

| Setting | Action | Reason |
|---------|--------|--------|
| **TPM** | **Disable** | Required before Omarchy install on this machine |
| **Virtualization (VT-x)** | **Enable** | Docker / VMs |
| **Secure Boot** | OFF | Keep disabled |
| Boot order | USB first (temporary) | Installer |

### Phase 2 — Install Omarchy 4

1. Download Omarchy 4 (Quattro) ISO; write to USB.
2. Prefer **ethernet** for install (Intel 7265 Wi-Fi usually works post-install).
3. Boot UEFI; run installer with **full-disk LUKS**.
4. Username `sroomberg`, hostname `omarchy` (or your choice).
5. LUKS unlock: wired USB keyboard helps at early boot if built-in is awkward.

### Phase 3 — First boot

1. Unlock LUKS, log in, connect network.
2. Omarchy essentials:
   - Menu: **Super+Space**
   - Updates: **`omarchy update`** (not raw `pacman -Syu` / `yay -Syu`)
   - Packages: **`omarchy pkg add`**
   - AUR: Install → AUR / `yay`

### Phase 4 — Run bootstrap

```bash
git clone https://github.com/sroomberg/envutils.git ~/envutils
cd ~/envutils/linux/omarchy
chmod +x bootstrap.sh
cp .env.example .env
# Edit GIT_NAME, GIT_EMAIL, BACKUP_ROOT, SSH_ADD_KEYS
# Quote names with spaces: GIT_NAME="Steven Roomberg"

./bootstrap.sh --dry-run
./bootstrap.sh
```

- Log: `~/omarchy-bootstrap.log`
- `.env` search order: `<script-dir>/.env`, then `$PWD/.env`; shell exports override `.env`.
- Bootstrap: Omarchy detection, `omarchy update -y`, git identity, SSH restore, CLI packages, Cursor/Obsidian/1Password guidance, Docker check, HiDPI/fingerprint/safe-restore reminders.

### Phase 5 — Personalization (this CONFIG)

Reapply Hyprland / Omarchy overrides documented above:

1. Copy or recreate `~/.config/hypr/{input,apps,looknfeel,autostart}.lua` per sections above.
2. Install `nwg-dock-hyprland`; deploy `start-nwg-dock`, `nwg-dock-apps-launcher`, systemd unit, autostart line.
3. Caps Lock bar module + `shell.json` layout entry.
4. Ghostty default, zsh/p10k from envutils backup.
5. Install apps (Cursor, Zed, Claude Desktop, Chromium, 1Password, Obsidian, …) and re-pin dock.
6. Optional: `linux/omarchy/window-switcher/` for Alt+Tab HUD.

### Phase 6 — Post-install checklist

- [ ] 1Password sign-in + browser extension
- [ ] Obsidian, Cursor, Claude Desktop, Chromium + native messaging
- [ ] Docker: `sudo docker ps` or enable sudoless Docker
- [ ] Display scale 1.25 (or adjust)
- [ ] VT-x: `grep -E '(vmx|svm)' /proc/cpuinfo` if VMs fail
- [ ] Restore Documents/projects selectively
- [ ] `gh auth login`, cloud CLIs
- [ ] Reinstall remaining apps from old Snap list via AUR/Flatpak/`omarchy install`

### Troubleshooting

| Issue | Check |
|-------|-------|
| Bootstrap refuses to run | Must be Omarchy (`omarchy` CLI or `~/.config/omarchy`) |
| SSH keys missing | `BACKUP_ROOT/.ssh/` before bootstrap |
| Docker permission denied | `sudo docker ps` or Setup → Security → sudoless Docker |
| Wi-Fi missing | `ip link`; Intel 7265 firmware usually in kernel |
| UI scale wrong | Settings → Display |
| Dock not starting | `systemctl --user status nwg-dock`; `pgrep -af nwg-dock-hyprland` |

### Optional — Realtek headphone pop (X1C3)

Some units pop the speaker on headphone insert/remove. **Only if confirmed Realtek + issue exists:**

```bash
# echo "options snd-hda-intel model=thinkpad" | sudo tee /etc/modprobe.d/snd-hda-intel.conf
# sudo reboot
```

---

## Key path index

```text
~/.config/hypr/hyprland.lua          # includes apps, looknfeel, input, autostart, bindings, monitors
~/.config/hypr/input.lua
~/.config/hypr/apps.lua
~/.config/hypr/looknfeel.lua
~/.config/hypr/autostart.lua
~/.config/hypr/bindings.lua
~/.config/hypr/monitors.lua
~/.local/bin/start-nwg-dock
~/.local/bin/nwg-dock-apps-launcher
~/.config/systemd/user/nwg-dock.service
~/.cache/nwg-dock-pinned
~/.config/omarchy/shell.json
~/.config/omarchy/bar/modules/caps-lock.qml
~/.config/omarchy/bar/scripts/caps-lock
~/.XCompose
~/envutils/linux/omarchy/bootstrap.sh
~/envutils/linux/omarchy/.env          # gitignored locally
```
