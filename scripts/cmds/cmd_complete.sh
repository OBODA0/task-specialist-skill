cmd_complete() {
  local id="${1:-}"
  [ -z "$id" ] && die "Usage: task complete ID"
  require_int "$id" "ID"

  local status
  status=$(sql "SELECT status FROM tasks WHERE id = $id;" 2>/dev/null) || true
  [ -z "$status" ] && die "Task #$id not found"
  [ "$status" = "done" ] && die "Task #$id is already complete"

  local blocking
  blocking=$(sql "SELECT id || ': ' || request_text FROM tasks WHERE parent_id = $id AND status != 'done';")
  if [ -n "$blocking" ]; then
    warn "Cannot complete task #$id — pending subtasks:"
    echo "$blocking" | while IFS= read -r line; do
      printf '  → %s\n' "$line"
    done
    exit 1
  fi

  sql "UPDATE tasks SET status = 'done', completed_at = datetime('now'), last_updated = datetime('now') WHERE id = $id;"
  ok "Completed task #$id"
}
