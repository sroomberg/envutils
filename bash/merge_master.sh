merge_master() {
  local default_branch="master"
  local message="WIP: committing before merge with master"
  local opt
  while getopts "d:m:h" opt; do
    case $opt in
      d) default_branch="$OPTARG" ;;
      m) message="$OPTARG" ;;
      h)
        echo "Usage: merge_master [-d <branch>] [-m <message>]"
        echo ""
        echo "Options:"
        echo "  -d <branch>   Default branch to merge from (default: master)"
        echo "  -m <message>  Commit message for current changes (default: 'WIP: committing before merge with master')"
        echo "  -h            Show this help message"
        echo ""
        echo "Examples:"
        echo "  merge_master                          # uses master + default message"
        echo "  merge_master -d main                  # merges main instead"
        echo "  merge_master -m 'saving work'         # custom commit message"
        echo "  merge_master -d main -m 'saving work' # both"
        return 0
        ;;
    esac
  done
  local branch=$(git rev-parse --abbrev-ref HEAD)
  git add -A && git commit -m "$message" &&
  git checkout "$default_branch" &&
  git pull origin "$default_branch" &&
  git checkout "$branch" &&
  git merge "$default_branch"
}
