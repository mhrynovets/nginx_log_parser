#!/bin/sh

# Error codes
ERR_INVALID_URL=1
ERR_SSH_KEY_MISSING=2
ERR_PARSER=3
ERR_GIT_OPS=4
ERR_FILE_MISSING=5
ERR_FS_PROBLEM=6
ERR_GIT_CLONE_PROBLEM=7

REPO_DIR="/app/repo"
TARGET_BRANCH=${GIT_BRANCH:-main}
MOUNTED_KEY="/tmp/id_rsa"
KEY_PATH="/root/.ssh/id_rsa"
OUTPUT_FILE="logs.csv"

# 1. Validate provided Git URL
if [ -z "$GIT_REMOTE_URL" ] || ! echo "$GIT_REMOTE_URL" | grep -Eq "^git@[a-zA-Z0-9.-]+:[a-zA-Z0-9._/-]+\.git$"; then
    echo "CRITICAL: Invalid Git SSH URL."
    exit $ERR_INVALID_URL
fi

# 2. SSH Setup
if [ -f "$MOUNTED_KEY" ]; then
    mkdir -p /root/.ssh && chmod 700 /root/.ssh
    cp "$MOUNTED_KEY" "$KEY_PATH"
    chmod 600 "$KEY_PATH"
    export GIT_SSH_COMMAND="ssh -i $KEY_PATH -o BatchMode=yes"

    DOMAIN=$(echo "$GIT_REMOTE_URL" | sed -e 's/.*@//' -e 's/[:/].*//')
    ssh-keyscan -t rsa,ed25519 -H "$DOMAIN" >> /root/.ssh/known_hosts 2>/dev/null
else
    echo "CRITICAL: SSH key not found at $MOUNTED_KEY."
    exit $ERR_SSH_KEY_MISSING
fi

# 3. Git preparation
echo "--- Preparing Repository ---"
git config --global user.name "${GIT_USER_NAME:-"Log Parser Bot"}"
git config --global user.email "${GIT_USER_EMAIL:-"bot@example.com"}"
git config --global --add safe.directory "$REPO_DIR"

mkdir -p "$REPO_DIR" || exit $ERR_FS_PROBLEM
git clone "$GIT_REMOTE_URL" "$REPO_DIR" || exit $ERR_GIT_CLONE_PROBLEM
cd "$REPO_DIR" || exit
git checkout "$TARGET_BRANCH" 2>/dev/null || git checkout -b "$TARGET_BRANCH"

# 4. Core parsing execution
echo "--- Parsing logs ---"
python3 /app/parser.py "$@" --output "$REPO_DIR/$OUTPUT_FILE"
[ $? -ne 0 ] && exit $ERR_PARSER

# 5. Git workflow
[ ! -f "$OUTPUT_FILE" ] && echo "File $OUTPUT_FILE not found!" && exit $ERR_FILE_MISSING

echo "--- Pushing results ---"
git add "$OUTPUT_FILE"
# Додаємо || true щоб скрипт не падав, якщо змін немає
git commit -m "Auto-update ($TARGET_BRANCH): $(date +%T)" || echo "No changes to commit"
git push -u origin "$TARGET_BRANCH" || exit $ERR_GIT_OPS
