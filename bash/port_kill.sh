port_kill() {
  local port=""
  local opt

  while getopts "h" opt; do
    case $opt in
      h)
        echo "Usage: port_kill <port>"
        echo ""
        echo "Examples:"
        echo "  port_kill 3000"
        echo "  port_kill 8080"
        return 0
        ;;
    esac
  done

  port="${1}"

  if [[ -z "$port" ]]; then
    echo "Error: port number is required" >&2
    echo "Usage: port_kill <port>" >&2
    return 1
  fi

  if ! [[ "$port" =~ ^[0-9]+$ ]]; then
    echo "Error: invalid port number: $port" >&2
    return 1
  fi

  local pids
  pids=$(lsof -ti tcp:"$port")

  if [[ -z "$pids" ]]; then
    echo "No process found on port $port"
    return 0
  fi

  echo "Killing process(es) on port $port: $pids"
  echo "$pids" | xargs kill -9
  echo "Done."
}
