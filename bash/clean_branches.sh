clean_branches() {
  local default_branch="master"
  local opt

  while getopts "d:h" opt; do
    case $opt in
      d) default_branch="$OPTARG" ;;
      h)
        echo "Usage: clean_branches [-d <branch>]"
        echo ""
        echo "Deletes all local branches already merged into the default branch."
        echo ""
        echo "Options:"
        echo "  -d <branch>   Default branch to check against (default: master)"
        echo "  -h            Show this help message"
        echo ""
        echo "Examples:"
        echo "  clean_branches                # checks against master"
        echo "  clean_branches -d main        # checks against main"
        return 0
        ;;
    esac
  done

  local merged
  merged=$(git branch --merged "$default_branch" | grep -v -E "^\*|^\s*$default_branch$")

  if [[ -z "$merged" ]]; then
    echo "No merged branches to clean up."
    return 0
  fi

  echo "Branches to delete:"
  echo "$merged"
  echo ""
  read "reply?Delete these branches? [y/N] "
  if [[ "$reply" =~ ^[Yy]$ ]]; then
    echo "$merged" | xargs git branch -d
    echo "Done."
  else
    echo "Aborted."
  fi
}
