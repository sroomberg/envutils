create_ssh_key() {
  local name=""
  local comment=""
  local key_type="ed25519"
  local opt

  while getopts "n:c:t:h" opt; do
    case $opt in
      n) name="$OPTARG" ;;
      c) comment="$OPTARG" ;;
      t) key_type="$OPTARG" ;;
      h)
        echo "Usage: new_ssh_key -n <name> [-c <comment>] [-t <key_type>]"
        echo ""
        echo "Options:"
        echo "  -n <name>      Key filename (stored as ~/.ssh/<name>)"
        echo "  -c <comment>   Key comment (default: <name>)"
        echo "  -t <type>      Key type: ed25519, rsa (default: ed25519)"
        echo "  -h             Show this help message"
        echo ""
        echo "Examples:"
        echo "  new_ssh_key -n github                    # ~/.ssh/github"
        echo "  new_ssh_key -n work -c 'work laptop'     # with comment"
        echo "  new_ssh_key -n legacy -t rsa             # RSA key"
        return 0
        ;;
    esac
  done

  if [[ -z "$name" ]]; then
    echo "Error: key name is required (-n <name>)" >&2
    return 1
  fi

  local key_path="$HOME/.ssh/$name"
  local comment="${comment:-$name}"

  if [[ -f "$key_path" ]]; then
    echo "Error: key already exists at $key_path" >&2
    return 1
  fi

  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"

  if [[ "$key_type" == "rsa" ]]; then
    ssh-keygen -t rsa -b 4096 -C "$comment" -f "$key_path"
  else
    ssh-keygen -t ed25519 -C "$comment" -f "$key_path"
  fi

  chmod 600 "$key_path"
  chmod 644 "$key_path.pub"

  # Add to ssh-agent if running
  if ssh-add -l &>/dev/null || [[ "$SSH_AUTH_SOCK" ]]; then
    ssh-add "$key_path"
  fi

  echo ""
  echo "Key created: $key_path"
  echo ""
  echo "Public key:"
  cat "$key_path.pub"
}
