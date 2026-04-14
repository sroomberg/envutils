#!/bin/bash

set -e

SHELL_RC="$HOME/.zshrc"
[ -n "$BASH_VERSION" ] && SHELL_RC="$HOME/.bashrc"

if [[ "$OSTYPE" == "darwin"* ]]; then
  echo "macOS detected — pbcopy/pbpaste are available natively, nothing to install."
  exit 0
fi

if ! command -v apt-get &>/dev/null; then
  echo "Error: unsupported Linux distro (apt not found)." >&2
  exit 1
fi

echo "Ubuntu/Linux detected — installing xclip..."
sudo apt-get update -qq && sudo apt-get install -y xclip

MARKER="# pbcopy/pbpaste aliases (envutils)"
if grep -qF "$MARKER" "$SHELL_RC"; then
  echo "Aliases already present in $SHELL_RC, skipping."
else
  cat >> "$SHELL_RC" <<EOF

$MARKER
alias pbcopy='xclip -selection clipboard'
alias pbpaste='xclip -selection clipboard -o'
EOF
  echo "Aliases added to $SHELL_RC."
fi

echo "Done. Reload your shell or run: source $SHELL_RC"
