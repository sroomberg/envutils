null_commit() {
    local default_message="refresh PR"
    git commit --allow-empty -m "${1:-$default_message}"
}
