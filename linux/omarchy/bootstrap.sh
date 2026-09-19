#!/usr/bin/env bash
#
# omarchy-bootstrap.sh — Post-install bootstrap for Omarchy 4 (Quattro)
#
# Run once after first login on a fresh Omarchy install (e.g. ThinkPad X1 Carbon Gen 3).
# Idempotent-ish: safe to re-run; skips steps already completed.
#
# Usage:
#   ./bootstrap.sh [--dry-run]
#   BACKUP_ROOT=~/Backups/omarchy-restore GIT_NAME="Steven Roomberg" GIT_EMAIL="you@example.com" ./bootstrap.sh
#
# Options:
#   --dry-run   Print actions without executing (still logs to ~/omarchy-bootstrap.log)
#
# Environment:
#   BACKUP_ROOT   Directory containing backed-up ~/.ssh, Documents, etc. (default below)
#   GIT_NAME      Git user.name (prompted if unset)
#   GIT_EMAIL     Git user.email (prompted if unset)
#   SSH_ADD_KEYS  Set to 1 to run ssh-add on restored private keys (default: 1)
#
# Log: ~/omarchy-bootstrap.log

set -euo pipefail

readonly SCRIPT_NAME="${0##*/}"
readonly LOG_FILE="${HOME}/omarchy-bootstrap.log"
readonly DEFAULT_BACKUP_ROOT="${HOME}/Backups/omarchy-restore"

DRY_RUN=0
BACKUP_ROOT="${BACKUP_ROOT:-$DEFAULT_BACKUP_ROOT}"
SSH_ADD_KEYS="${SSH_ADD_KEYS:-1}"

# ── logging / dry-run helpers ───────────────────────────────────────────────

log() {
  local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
  echo "$msg" | tee -a "$LOG_FILE"
}

run() {
  log "+ $*"
  if [[ "$DRY_RUN" -eq 0 ]]; then
    "$@"
  fi
}

run_eval() {
  log "+ $*"
  if [[ "$DRY_RUN" -eq 0 ]]; then
    eval "$@"
  fi
}

skip() {
  log "SKIP: $*"
}

warn() {
  log "WARN: $*"
}

# ── argument parsing ─────────────────────────────────────────────────────────

usage() {
  cat <<EOF
Usage: $SCRIPT_NAME [--dry-run]

Post-install bootstrap for Omarchy 4. See script header for environment variables.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

# ── Omarchy detection ───────────────────────────────────────────────────────

is_omarchy() {
  if command -v omarchy &>/dev/null; then
    return 0
  fi
  if [[ -d /etc/omarchy ]] || [[ -f /etc/os-release && $(grep -c 'Omarchy' /etc/os-release 2>/dev/null || true) -gt 0 ]]; then
    return 0
  fi
  if [[ -d "${HOME}/.config/omarchy" ]]; then
    return 0
  fi
  return 1
}

# ── main ─────────────────────────────────────────────────────────────────────

main() {
  mkdir -p "$(dirname "$LOG_FILE")"
  : >"$LOG_FILE"
  log "=== Omarchy bootstrap started (dry_run=$DRY_RUN) ==="

  if ! is_omarchy; then
    log "ERROR: Omarchy not detected. Refusing to run on a non-Omarchy system."
    log "  Expected: 'omarchy' CLI, /etc/omarchy, or ~/.config/omarchy"
    exit 1
  fi
  log "Omarchy detected."

  system_update
  configure_git
  restore_ssh_keys
  install_cli_tools
  install_cursor
  install_snap_standins
  verify_docker
  print_hidpi_notes
  print_fingerprint_reminder
  print_safe_restore_guidance
  print_post_checklist

  log "=== Omarchy bootstrap finished ==="
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "Dry run complete — no changes were made."
  else
    log "Review ${LOG_FILE} for details."
  fi
}

# ── system update ─────────────────────────────────────────────────────────────

system_update() {
  log "--- System update via omarchy update ---"
  if ! command -v omarchy &>/dev/null; then
    warn "omarchy CLI not found; skipping omarchy update."
    return
  fi
  run omarchy update
}

# ── git identity ──────────────────────────────────────────────────────────────

configure_git() {
  log "--- Git identity ---"
  local name="${GIT_NAME:-}"
  local email="${GIT_EMAIL:-}"

  if [[ -z "$name" ]]; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      log "Would prompt for GIT_NAME (dry run)."
      name="DRY_RUN_NAME"
    elif [[ -t 0 ]]; then
      read -rp "Git user.name: " name
    else
      warn "GIT_NAME not set and no TTY; skipping git user.name."
    fi
  fi

  if [[ -z "$email" ]]; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      log "Would prompt for GIT_EMAIL (dry run)."
      email="dry-run@example.com"
    elif [[ -t 0 ]]; then
      read -rp "Git user.email: " email
    else
      warn "GIT_EMAIL not set and no TTY; skipping git user.email."
    fi
  fi

  if [[ -n "$name" && "$name" != "DRY_RUN_NAME" ]]; then
    if git config --global user.name &>/dev/null && [[ "$(git config --global user.name)" == "$name" ]]; then
      skip "git user.name already set to '$name'"
    else
      run git config --global user.name "$name"
    fi
  fi

  if [[ -n "$email" && "$email" != "dry-run@example.com" ]]; then
    if git config --global user.email &>/dev/null && [[ "$(git config --global user.email)" == "$email" ]]; then
      skip "git user.email already set to '$email'"
    else
      run git config --global user.email "$email"
    fi
  fi
}

# ── SSH key restore ───────────────────────────────────────────────────────────

restore_ssh_keys() {
  log "--- SSH key restore from ${BACKUP_ROOT} ---"
  local src="${BACKUP_ROOT}/.ssh"
  local dst="${HOME}/.ssh"

  if [[ ! -d "$src" ]]; then
    warn "No SSH backup at ${src}; skipping key restore."
    warn "  Copy your Ubuntu ~/.ssh into ${BACKUP_ROOT}/.ssh before running."
    return
  fi

  run mkdir -p "$dst"
  if [[ "$DRY_RUN" -eq 0 ]]; then
    run chmod 700 "$dst"
  else
    log "+ chmod 700 $dst"
  fi

  # Copy keys and config; do not overwrite existing private keys without warning
  local restored=0
  shopt -s nullglob
  for f in "$src"/*; do
    local base="${f##*/}"
    local target="${dst}/${base}"
    if [[ -e "$target" ]]; then
      skip "SSH file already exists: ${target}"
      continue
    fi
    run cp -a "$f" "$target"
    restored=1
  done
  shopt -u nullglob

  if [[ "$restored" -eq 0 && "$DRY_RUN" -eq 0 ]]; then
    skip "No new SSH files copied (all present or backup empty)."
  fi

  if [[ "$DRY_RUN" -eq 0 ]]; then
    find "$dst" -type f -name 'id_*' ! -name '*.pub' -exec chmod 600 {} + 2>/dev/null || true
    find "$dst" -type f -name '*.pub' -exec chmod 644 {} + 2>/dev/null || true
    [[ -f "$dst/config" ]] && chmod 600 "$dst/config" || true
  fi

  if [[ "$SSH_ADD_KEYS" == "1" ]]; then
    if command -v ssh-add &>/dev/null; then
      shopt -s nullglob
      for key in "$dst"/id_* "$dst"/id_*_*; do
        [[ -f "$key" && "$key" != *.pub ]] || continue
        run ssh-add "$key" 2>/dev/null || warn "Could not add key: $key (agent may not be running)"
      done
      shopt -u nullglob
    else
      skip "ssh-add not available"
    fi
  fi
}

# ── official-repo CLI tools ───────────────────────────────────────────────────

install_cli_tools() {
  log "--- CLI tools via omarchy pkg add ---"
  if ! command -v omarchy &>/dev/null; then
    warn "omarchy CLI not found; skipping omarchy pkg add."
    return
  fi

  local pkgs=(jq ripgrep fd curl base-devel)
  local to_install=()

  for pkg in "${pkgs[@]}"; do
    if pacman -Qi "$pkg" &>/dev/null; then
      skip "package already installed: $pkg"
    else
      to_install+=("$pkg")
    fi
  done

  if [[ ${#to_install[@]} -eq 0 ]]; then
    skip "All CLI packages already installed."
    return
  fi

  run omarchy pkg add "${to_install[@]}"
}

# ── Cursor editor ─────────────────────────────────────────────────────────────

install_cursor() {
  log "--- Cursor editor ---"
  if command -v cursor &>/dev/null || [[ -x /opt/Cursor/cursor ]] || [[ -d "${HOME}/.local/share/applications" && -n $(find "${HOME}/.local/share/applications" -name '*cursor*' 2>/dev/null | head -1) ]]; then
    skip "Cursor appears already installed."
    log "  Preferred install path: Super+Space → Install → Editor → Cursor"
    return
  fi

  log "Cursor not detected."
  log "  Preferred: Super+Space → Install → Editor → Cursor"
  log "  CLI fallback: yay -S --needed cursor-bin"

  if command -v yay &>/dev/null; then
    if pacman -Qi cursor-bin &>/dev/null; then
      skip "cursor-bin already installed via pacman."
    else
      run yay -S --needed --noconfirm cursor-bin
    fi
  else
    warn "yay not found; install Cursor manually via the Omarchy menu."
  fi
}

# ── Snap stand-ins (AUR / Flatpak) ─────────────────────────────────────────────

install_snap_standins() {
  log "--- Snap stand-ins (Obsidian, 1Password, browser) ---"
  log "Snap packages from Ubuntu will NOT carry over. Install equivalents:"

  # Obsidian
  if command -v obsidian &>/dev/null || flatpak list 2>/dev/null | grep -q obsidian; then
    skip "Obsidian already installed."
  else
    log "  Obsidian: Super+Space → Install → AUR → obsidian (or: yay -S obsidian)"
    if command -v yay &>/dev/null && [[ "$DRY_RUN" -eq 0 ]]; then
      read -rp "Install Obsidian via yay now? [y/N] " ans || ans=""
      if [[ "${ans,,}" == "y" ]]; then
        run yay -S --needed --noconfirm obsidian
      fi
    fi
  fi

  # 1Password
  if command -v 1password &>/dev/null || command -v 1Password &>/dev/null; then
    skip "1Password already installed."
  else
    log "  1Password: https://1password.com/downloads/linux/ or AUR 1password"
    log "            Super+Space → Install → AUR → 1password"
  fi

  # Browser — Omarchy ships Firefox; document alternatives
  log "  Browser: Omarchy includes Firefox. Chromium/Brave via Install → AUR if preferred."
  if command -v firefox &>/dev/null; then
    skip "Firefox present (default Omarchy browser)."
  fi
}

# ── Docker verification ───────────────────────────────────────────────────────

verify_docker() {
  log "--- Docker verification ---"
  if ! command -v docker &>/dev/null; then
    warn "docker not found — Omarchy normally includes Docker; check install."
    return
  fi

  log "Omarchy ships Docker + Compose. Lazydocker: Super+Shift+D"
  log "Default: sudoless Docker is OFF. To enable (optional):"
  log "  Setup → Security → Sudoless Docker"
  log "  or: omarchy-setup-security-sudoless-docker"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "+ sudo docker ps"
    return
  fi

  if sudo docker ps &>/dev/null; then
    log "Docker OK: sudo docker ps succeeded."
  else
    warn "sudo docker ps failed — ensure Docker service is running and your user has sudo."
    warn "  systemctl status docker"
  fi
}

# ── HiDPI / X1 Carbon Gen 3 notes ───────────────────────────────────────────

print_hidpi_notes() {
  log "--- HiDPI / ThinkPad X1 Carbon Gen 3 notes ---"
  cat <<'NOTES' | while IFS= read -r line; do log "  $line"; done
Display: 2560×1440 — Omarchy 2× scaling is a good default (Settings → Display).
Intel HD 5500 (i915): no proprietary GPU driver needed.
Wi-Fi: Intel 7265 — prefer ethernet during install; Wi-Fi works post-install.
Virtualization: enable VT-x in BIOS if you use Docker/VMs (was disabled on Ubuntu).
Power/suspend: test lid-close and resume after install; adjust in Settings → Power.

Optional Realtek headphone pop mitigation (DO NOT apply blindly — verify your audio chip):
  # Some X1C3 units use Realtek; if you hear speaker pop on headphone plug/unplug:
  # echo "options snd-hda-intel model=thinkpad" | sudo tee /etc/modprobe.d/snd-hda-intel.conf
  # Then reboot. Only apply if you confirm Realtek + the issue exists.
NOTES
}

# ── fingerprint reminder ──────────────────────────────────────────────────────

print_fingerprint_reminder() {
  log "--- Fingerprint (Validity VFS 5011, 138a:0017) ---"
  log "  Enroll after install: Super+Space → Setup → Security → Fingerprint"
  log "  Not configured during ISO install — enroll on first boot."
}

# ── safe restore guidance ─────────────────────────────────────────────────────

print_safe_restore_guidance() {
  log "--- Safe restore guidance ---"
  cat <<'GUIDE' | while IFS= read -r line; do log "  $line"; done
NEVER clobber ~/.config/omarchy wholesale — it holds Omarchy-specific settings.

Safe to restore from backup (copy selectively, merge configs):
  ~/Documents, ~/projects, ~/src, ~/dev
  ~/.ssh (via this script from BACKUP_ROOT)
  ~/.gnupg
  Individual app configs you recognize (e.g. ~/.config/obsidian)

Restore manually after reviewing diffs:
  git config (this script sets name/email; restore ~/.gitconfig extras if needed)
  Shell rc: merge aliases/functions into ~/.bashrc or ~/.zshrc — do not replace Omarchy defaults blindly.

Backup root default: ~/Backups/omarchy-restore
  Expected layout: BACKUP_ROOT/.ssh/, BACKUP_ROOT/home/Documents/, etc.
GUIDE
}

# ── post checklist ────────────────────────────────────────────────────────────

print_post_checklist() {
  log "--- Post-bootstrap checklist ---"
  cat <<'CHECK' | while IFS= read -r line; do log "  [ ] $line"; done
Log into 1Password and re-enable browser extension
Re-clone or restore git repos (envutils, projects)
Re-authenticate gh, aws, docker registries as needed
Test Wi-Fi (Intel 7265) if you used ethernet for install
Enroll fingerprint: Setup → Security → Fingerprint
Optional: enable sudoless Docker in Setup → Security
Reinstall any remaining AUR/Flatpak apps from Ubuntu Snap list
CHECK
}

main "$@"
