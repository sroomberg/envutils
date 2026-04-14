#!/bin/bash

set -e

PYTHON_VERSION="3.13"
SHELL_RC="$HOME/.zshrc"
[ -n "$BASH_VERSION" ] && SHELL_RC="$HOME/.bashrc"

# ── pyenv ────────────────────────────────────────────────────────────────────

if command -v pyenv &>/dev/null; then
  echo "pyenv already installed, skipping."
else
  if [[ "$OSTYPE" == "darwin"* ]]; then
    if ! command -v brew &>/dev/null; then
      echo "Error: Homebrew is required on macOS. Run osx/osx_setup.sh first." >&2
      exit 1
    fi
    brew install pyenv
  else
    curl -fsSL https://pyenv.run | bash
  fi
fi

# Add pyenv init to shell rc if not already present
PYENV_MARKER="# pyenv init (envutils)"
if ! grep -qF "$PYENV_MARKER" "$SHELL_RC"; then
  cat >> "$SHELL_RC" <<EOF

$PYENV_MARKER
export PYENV_ROOT="\$HOME/.pyenv"
export PATH="\$PYENV_ROOT/bin:\$PATH"
eval "\$(pyenv init -)"
EOF
  echo "pyenv init added to $SHELL_RC."
fi

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# ── Python ───────────────────────────────────────────────────────────────────

if pyenv versions --bare | grep -q "^${PYTHON_VERSION}"; then
  echo "Python $PYTHON_VERSION already installed, skipping."
else
  echo "Installing Python $PYTHON_VERSION..."
  pyenv install "$PYTHON_VERSION"
fi

pyenv global "$PYTHON_VERSION"
echo "Python $(python --version) set as global."

# ── pip ──────────────────────────────────────────────────────────────────────

echo "Upgrading pip..."
python -m ensurepip --upgrade
python -m pip install --upgrade pip
echo "pip $(pip --version | awk '{print $2}') ready."

# ── uv ───────────────────────────────────────────────────────────────────────

if command -v uv &>/dev/null; then
  echo "uv already installed, skipping."
else
  echo "Installing uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  echo "uv installed."
fi

echo ""
echo "Done. Reload your shell or run: source $SHELL_RC"
