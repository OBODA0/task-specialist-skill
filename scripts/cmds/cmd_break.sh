cmd_break() {
  local parent_id="${1:-}"
  [ -z "$parent_id" ] && die "Usage: task break ID \"subtask 1\" \"subtask 2\" ..."
  shift

  require_int "$parent_id" "ID"
  local status
  status=$(sql "SELECT status FROM tasks WHERE id = $parent_id;" 2>/dev/null) || true
  [ -z "$status" ] && die "Task #$parent_id not found"

  local parent_priority
  parent_priority=$(sql "SELECT priority FROM tasks WHERE id = $parent_id;")
  local parent_project
  parent_project=$(sql "SELECT project FROM tasks WHERE id = $parent_id;")

  local project_val="NULL"
  [ -n "$parent_project" ] && project_val="'$parent_project'"

  local created=0
  for sub in "$@"; do
    local safe_sub
    safe_sub=$(printf '%s' "$sub" | sed "s/'/''/g")
    
    local sub_id
    sub_id=$(sql "INSERT INTO tasks (request_text, project, status, priority, parent_id, created_at, last_updated)
      VALUES ('$safe_sub', $project_val, 'pending', $parent_priority, $parent_id, datetime('now'), datetime('now'));
      SELECT last_insert_rowid();")
    
    echo "  → Created subtask #$sub_id: $sub"
    created=$((created + 1))
  done

  [ "$created" -eq 0 ] && warn "No subtasks provided." || ok "Created $created subtasks for task #$parent_id"
}
