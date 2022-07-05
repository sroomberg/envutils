function merge_master {
	current_branch=$(git rev-parse --abbrev-ref HEAD)
        git commit -am "commit before merge"
        git checkout master
        git pull
        git checkout $current_branch
        git merge master --no-edit
}
