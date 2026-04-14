# envutils

Personal environment setup utilities for a new machine.

## Structure

```
envutils/
├── osx/
│   └── osx_setup.sh       # Homebrew + core CLI tools + apps
├── iterm2/
│   ├── setup.sh           # Installs powerlevel10k theme + p10k config
│   ├── .p10k.zsh          # Powerlevel10k prompt configuration
│   ├── profile.json       # iTerm2 profile
│   └── sr.zsh-theme       # Legacy custom zsh theme
└── bash/
    ├── merge_master.sh    # Shell function: commit, pull, and merge default branch
    ├── pbcopy_setup.sh    # Installs pbcopy/pbpaste support (macOS native, xclip on Linux)
    └── ssh_keygen.sh      # Shell function: generate and store a new OpenSSH key
```

## Setup

### 1. macOS dependencies

```bash
cd osx && ./osx_setup.sh
```

Installs Homebrew, then: `curl`, `wget`, `ack`, `pyenv`, `awscli`, Docker, and iTerm2.

### 2. iTerm2 / zsh theme

Requires [Oh My Zsh](https://ohmyz.sh/) to be installed first.

```bash
cd iterm2 && ./setup.sh
```

Installs the [Powerlevel10k](https://github.com/romkatv/powerlevel10k) theme, sets it in `.zshrc`, and copies the p10k prompt config to `~/`.

To import the iTerm2 profile: **iTerm2 → Preferences → Profiles → Other Actions → Import JSON Profiles** → select `iterm2/profile.json`.

### 3. Shell utilities

Source `merge_master.sh` in your `.zshrc` to get the `merge_master` function:

```bash
source /path/to/envutils/bash/merge_master.sh
```

#### `pbcopy_setup.sh`

Sets up `pbcopy` / `pbpaste` clipboard commands cross-platform:

```bash
bash /path/to/envutils/bash/pbcopy_setup.sh
```

- **macOS**: no-op — `pbcopy`/`pbpaste` are available natively.
- **Linux (Ubuntu)**: installs `xclip` via `apt` and appends aliases to `.zshrc`/`.bashrc`.

#### `create_ssh_key`

Generates an OpenSSH key pair and stores it in `~/.ssh/`, then adds it to the running ssh-agent.

```
Usage: create_ssh_key -n <name> [-c <comment>] [-t <key_type>]

Options:
  -n <name>      Key filename (stored as ~/.ssh/<name>)
  -c <comment>   Key comment (default: <name>)
  -t <type>      Key type: ed25519, rsa (default: ed25519)
  -h             Show help
```

#### `merge_master`

Commits current changes, pulls the default branch, and merges it into your current branch.

```
Usage: merge_master [-d <branch>] [-m <message>]

Options:
  -d <branch>   Default branch to merge from (default: master)
  -m <message>  Commit message for current changes
  -h            Show help
```
