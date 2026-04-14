#!/bin/bash

set -e

RUBY_VERSION="3.3"
SHELL_RC="$HOME/.zshrc"
[ -n "$BASH_VERSION" ] && SHELL_RC="$HOME/.bashrc"

# ── system dependencies ───────────────────────────────────────────────────────

if [[ "$OSTYPE" == "darwin"* ]]; then
  if ! command -v brew &>/dev/null; then
    echo "Error: Homebrew is required on macOS. Run osx/osx_setup.sh first." >&2
    exit 1
  fi
  brew install openssl readline libyaml
else
  sudo apt-get update -qq
  sudo apt-get install -y curl gnupg2 build-essential libssl-dev libreadline-dev \
    zlib1g-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev
fi

# ── rvm ───────────────────────────────────────────────────────────────────────

if command -v rvm &>/dev/null; then
  echo "rvm already installed, skipping."
else
  echo "Installing rvm..."
  gpg --keyserver keyserver.ubuntu.com \
    --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 \
                7D2BAF1CF37B13E2069D6956105BD0E739499BDB
  curl -sSL https://get.rvm.io | bash -s stable

  # Source rvm for the rest of this script
  source "$HOME/.rvm/scripts/rvm"
  echo "rvm installed."
fi

RVM_MARKER="# rvm init (envutils)"
if ! grep -qF "$RVM_MARKER" "$SHELL_RC"; then
  cat >> "$SHELL_RC" <<EOF

$RVM_MARKER
export PATH="\$PATH:\$HOME/.rvm/bin"
[[ -s "\$HOME/.rvm/scripts/rvm" ]] && source "\$HOME/.rvm/scripts/rvm"
EOF
  echo "rvm init added to $SHELL_RC."
fi

source "$HOME/.rvm/scripts/rvm" 2>/dev/null || true

# ── ruby ─────────────────────────────────────────────────────────────────────

if rvm list strings | grep -q "$RUBY_VERSION"; then
  echo "Ruby $RUBY_VERSION already installed, skipping."
else
  echo "Installing Ruby $RUBY_VERSION..."
  rvm install "$RUBY_VERSION"
fi

rvm use "$RUBY_VERSION" --default
echo "Ruby $(ruby --version) set as default."

# ── rails ────────────────────────────────────────────────────────────────────

if gem list rails -i &>/dev/null; then
  echo "Rails already installed, skipping."
else
  echo "Installing Rails..."
  gem install rails
  echo "Rails $(rails --version) installed."
fi

echo ""
echo "Done. Reload your shell or run: source $SHELL_RC"
