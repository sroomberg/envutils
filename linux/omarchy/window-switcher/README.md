# window-switcher

Replaces Omarchy/Hyprland's stock Alt+Tab (which only cycles windows on the
*current* workspace) with one that:

- cycles across **all** workspaces, following to whichever workspace the
  target window lives on
- shows a macOS Cmd+Tab-style HUD in the center of the screen while Alt is
  held, highlighting the current selection

## Why this needs a workaround

Omarchy runs a patched/forked Hyprland with a Lua dispatch layer. Every
`hl.dsp.*` dispatcher acts on the *currently focused* window, or targets by
direction/workspace/monitor — there's no dispatcher to focus an arbitrary
window by address or class directly (confirmed by probing the Lua API; see
commit history / PR description for the exact errors). `nwg-dock-hyprland`'s
click-to-focus has the same problem, for the same reason — it assumes
vanilla Hyprland's classic `hyprctl dispatch focuswindow address:...` syntax,
which this fork's daemon rejects even over the raw IPC socket.

So `hypr-cycle-window.sh`, once it's switched to the right workspace, nudges
focus in-workspace with `cycle_next()` (bounded to 8 attempts) until it lands
on the exact target window.

## Files

- `hypr-cycle-window.sh [next|prev]` — the actual cycling logic. Bind to
  Alt+Tab / Alt+Shift+Tab.
- `hypr-cycle-window-end.sh` — ends the current cycling "session" (clears the
  snapshotted window order, hides the HUD). Bind to the *release* of the Alt
  key itself (`Alt_L` / `Alt_R`, `{ release = true }`) — Hyprland's Lua
  binding API supports binding a bare modifier key's release, which is what
  makes a real hold-Alt-tap-Tab-release-to-commit interaction possible.
- `plugin/` — an Omarchy Quickshell overlay plugin (`kinds: ["overlay"]`)
  that watches `~/.local/state/omarchy/window-switcher/state.json` (written
  by `hypr-cycle-window.sh` on every Tab press) and renders the HUD. It's
  purely passive — no keyboard focus, no click handling — the bash scripts do
  all the actual switching.

## Install

```bash
cp hypr-cycle-window.sh hypr-cycle-window-end.sh ~/.local/bin/
chmod +x ~/.local/bin/hypr-cycle-window ~/.local/bin/hypr-cycle-window-end
mv hypr-cycle-window.sh ~/.local/bin/hypr-cycle-window       # drop the .sh
mv hypr-cycle-window-end.sh ~/.local/bin/hypr-cycle-window-end
mkdir -p ~/.config/omarchy/plugins/window-switcher
cp plugin/* ~/.config/omarchy/plugins/window-switcher/
```

Then in `~/.config/hypr/bindings.lua`:

```lua
hl.unbind("ALT + TAB")
hl.unbind("ALT + SHIFT + TAB")
o.bind("ALT + TAB", "Cycle window (all workspaces)", "hypr-cycle-window next")
o.bind("ALT + SHIFT + TAB", "Cycle window backward (all workspaces)", "hypr-cycle-window prev")
o.bind("Alt_L", "End window-switcher session", "hypr-cycle-window-end", { release = true })
o.bind("Alt_R", "End window-switcher session (right alt)", "hypr-cycle-window-end", { release = true })
```

## Known limitations

- Window order is snapshotted fresh at the start of each Alt-held session
  (first Tab press after the previous session ended). This matches real
  Alt+Tab UX, but means the order can differ slightly from a naive
  most-recently-used sort if you cycle back and forth a lot within one hold.
- Icon resolution (`resolve_icon()` in `hypr-cycle-window.sh`) looks up each
  window's `.desktop` file by `StartupWMClass` or filename match; apps
  without a matching desktop entry fall back to the raw window class as the
  icon name, which the HUD then further falls back from (via
  `Quickshell.iconPath`) to a generic executable icon if that name isn't in
  the icon theme either.
