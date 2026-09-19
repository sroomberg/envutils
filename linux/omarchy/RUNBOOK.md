# Omarchy 4 (Quattro) migration — ThinkPad X1 Carbon Gen 3

Migration runbook for **Steven's Lenovo ThinkPad X1 Carbon Gen 3** (20BSCTO1WW) from **Ubuntu 24.04.5 LTS** to **Omarchy 4** with full-disk LUKS.

| Item | Value |
|------|-------|
| CPU | Intel Core i7-5600U |
| RAM | ~7.6 GiB |
| GPU | Intel HD 5500 (i915, no NVIDIA) |
| Storage | 256 GB Samsung SSD, single Ubuntu install (~143 GB free) |
| Display | 2560×1440 HiDPI |
| Wi-Fi | Intel 7265 (prefer ethernet during install) |
| Fingerprint | Validity VFS 5011 (138a:0017) |
| Firmware | UEFI; Secure Boot OFF |
| Prior hostname | `sroomberg-ubuntu` |
| Prior username | `sroomberg` |

**Deliverable:** post-install bootstrap script (`bootstrap.sh`), not cidata/autoinstall.

---

## Phase 0 — Backup (before any wipe)

> **WARNING: Full-disk LUKS install erases the entire SSD. Back up ~42 GB home data first.**

1. Copy to external drive or another machine:
   - `~/.ssh/` (private keys, `config`, `known_hosts`)
   - `~/.gnupg/`
   - `~/Documents`, `~/projects`, `~/dev`, `~/src`, or equivalent
   - Selective `~/.config/` (Obsidian, etc.) — **not** wholesale `~/.config`
   - Export browser bookmarks/passwords (1Password vault syncs separately)
2. Note installed Snaps (they will **not** carry over): Firefox, Obsidian, 1Password, etc.
3. Export any machine-specific env vars, API tokens, `.env` files from projects.
4. Stage backup for restore:

   ```text
   ~/Backups/omarchy-restore/
   ├── .ssh/
   ├── Documents/
   └── …
   ```

   Or mount external media at `/mnt/backup/omarchy-restore/` and set `BACKUP_ROOT` when running bootstrap.

---

## Phase 1 — BIOS (before booting Omarchy ISO)

> **WARNING: Change these in BIOS before installing Omarchy.**

| Setting | Action | Reason |
|---------|--------|--------|
| **TPM** | **Disable** | Required before Omarchy install |
| **Virtualization (VT-x)** | **Enable** | Was disabled; needed for Docker/VMs |
| **Secure Boot** | OFF (already) | Keep disabled |
| Boot order | USB first (temporary) | For installer |

Save and exit.

---

## Phase 2 — Create install media & install Omarchy

1. Download Omarchy 4 (Quattro) ISO from official sources.
2. Write to USB (`dd`, Ventoy, or Etcher).
3. **Prefer ethernet** for install (Intel 7265 Wi-Fi may work but wired is reliable).
4. Boot from USB → UEFI mode.
5. Follow Omarchy installer:
   - Full-disk **LUKS** encryption (single layout; no Windows dual-boot on this machine).
   - Set username (e.g. `sroomberg`) and hostname as desired.
6. LUKS passphrase: use a wired USB keyboard if built-in keyboard is awkward at early boot unlock — both work after install.
7. Complete install and reboot; remove USB when prompted.

---

## Phase 3 — First boot

1. Unlock LUKS at boot (passphrase).
2. Log in to Omarchy desktop.
3. Connect ethernet or Wi-Fi.
4. Open terminal.

Omarchy essentials:

- **Menu:** `Super + Space`
- **Updates:** `omarchy update` (not raw `pacman -Syu` / `yay -Syu`)
- **Packages:** `omarchy pkg add <pkg>`
- **AUR:** Install → AUR / `yay`
- **Docker UI:** `Super + Shift + D` (Lazydocker)

---

## Phase 4 — Run bootstrap

Clone envutils (or copy `bootstrap.sh`) and run:

```bash
git clone <your-envutils-repo> ~/envutils   # or scp bootstrap.sh
cd ~/envutils/linux/omarchy
chmod +x bootstrap.sh

# Preview:
./bootstrap.sh --dry-run

# Run (set identity via env to skip prompts):
export GIT_NAME="Your Name"
export GIT_EMAIL="you@example.com"
export BACKUP_ROOT="${HOME}/Backups/omarchy-restore"   # or /mnt/backup/omarchy-restore

./bootstrap.sh
```

Log: `~/omarchy-bootstrap.log`

The script will:

- Refuse to run if Omarchy is not detected
- Run `omarchy update`
- Configure git identity
- Restore SSH keys from `BACKUP_ROOT/.ssh`
- Install CLI tools via `omarchy pkg add`
- Guide Cursor, Obsidian, 1Password, Docker setup
- Print HiDPI, fingerprint, and safe-restore reminders

---

## Phase 5 — Post-install checklist

Manual steps after bootstrap:

- [ ] **Fingerprint:** Super+Space → Setup → Security → Fingerprint
- [ ] **1Password:** install via AUR/menu; sign in; restore browser extension
- [ ] **Obsidian:** AUR `obsidian` or Flatpak
- [ ] **Cursor:** Install → Editor → Cursor (or `yay -S cursor-bin`)
- [ ] **Docker:** confirm `sudo docker ps`; optionally enable sudoless Docker (Setup → Security)
- [ ] **Display:** verify 2× scaling on 2560×1440
- [ ] **VT-x:** confirm enabled if VMs fail (`grep -E '(vmx|svm)' /proc/cpuinfo`)
- [ ] Restore Documents/projects from backup (selective — see safe restore below)
- [ ] Re-clone repos; run `env-setup/python/setup.sh`, `env-setup/ruby/setup.sh` if needed
- [ ] Re-auth: `gh auth login`, AWS CLI, Docker registries
- [ ] Reinstall remaining apps from old Snap list via AUR/Flatpak

### Safe restore rules

- **Never** overwrite `~/.config/omarchy` from an Ubuntu backup.
- Restore `~/.ssh`, `~/.gnupg`, Documents, projects selectively.
- Merge shell aliases into Omarchy defaults; don't replace entire rc files blindly.

### Optional — Realtek headphone pop (X1C3)

Some units pop the speaker on headphone insert/remove. **Only apply if confirmed:**

```bash
# echo "options snd-hda-intel model=thinkpad" | sudo tee /etc/modprobe.d/snd-hda-intel.conf
# sudo reboot
```

---

## Troubleshooting

| Issue | Check |
|-------|-------|
| Bootstrap refuses to run | Must be on Omarchy (`omarchy` CLI or `~/.config/omarchy`) |
| SSH keys missing | Ensure `BACKUP_ROOT/.ssh/` exists before bootstrap |
| Docker permission denied | Use `sudo docker ps` or enable sudoless Docker |
| Wi-Fi missing | `ip link`; firmware for Intel 7265 usually in kernel |
| HiDPI too small/large | Settings → Display → scale 2× |
| Fingerprint not listed | Enroll via Setup → Security → Fingerprint after boot |

---

## Related envutils paths

| Path | Purpose |
|------|---------|
| `linux/omarchy/bootstrap.sh` | Post-install bootstrap |
| `linux/omarchy/RUNBOOK.md` | This document |
| `env-setup/python/setup.sh` | Python/pyenv after migration |
| `env-setup/ruby/setup.sh` | Ruby/RVM after migration |
| `git/commit-msg` | Git hook for commit messages |
