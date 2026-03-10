#!/usr/bin/env bash
set -euo pipefail

# project_write.sh — OpenClaw 写入业务项目文件的统一入口
# 解决问题：OpenClaw 以 root 运行，但 Claude Code 以 claw 运行，
#           root 直接写文件会导致 claw 无法写入。
#
# 用法：
#   project_write.sh <project_path> mkdir <dir_path>
#   project_write.sh <project_path> write <file_path> <content>
#   project_write.sh <project_path> copy <src> <dest>
#   project_write.sh <project_path> fix_perms
#
# 所有操作完成后自动 chown 给 claw 用户。

PROJECT_PATH=${1:?project_path required}
ACTION=${2:?action required (mkdir|write|copy|fix_perms)}

fix_ownership() {
  local target="$1"
  chown -R claw:claw "$target" 2>/dev/null || true
}

case "$ACTION" in
  mkdir)
    DIR_PATH=${3:?dir_path required}
    mkdir -p "$PROJECT_PATH/$DIR_PATH"
    fix_ownership "$PROJECT_PATH/$DIR_PATH"
    echo "OK mkdir $DIR_PATH (owner: claw)"
    ;;
  write)
    FILE_PATH=${3:?file_path required}
    CONTENT=${4:-}
    mkdir -p "$(dirname "$PROJECT_PATH/$FILE_PATH")"
    if [ -n "$CONTENT" ]; then
      echo "$CONTENT" > "$PROJECT_PATH/$FILE_PATH"
    else
      # Read from stdin
      cat > "$PROJECT_PATH/$FILE_PATH"
    fi
    fix_ownership "$PROJECT_PATH/$FILE_PATH"
    fix_ownership "$(dirname "$PROJECT_PATH/$FILE_PATH")"
    echo "OK write $FILE_PATH (owner: claw)"
    ;;
  copy)
    SRC=${3:?src required}
    DEST=${4:?dest required}
    mkdir -p "$(dirname "$PROJECT_PATH/$DEST")"
    cp -r "$SRC" "$PROJECT_PATH/$DEST"
    fix_ownership "$PROJECT_PATH/$DEST"
    echo "OK copy -> $DEST (owner: claw)"
    ;;
  fix_perms)
    # 修复整个项目的权限（应急用）
    chown -R claw:claw "$PROJECT_PATH"
    echo "OK fix_perms $PROJECT_PATH (all -> claw)"
    ;;
  *)
    echo "ERROR: unknown action '$ACTION'. Use: mkdir|write|copy|fix_perms" >&2
    exit 1
    ;;
esac
