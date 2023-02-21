#!/usr/bin/env bash

set -o pipefail

ORGANIZATION="demo"
PROJECT="demo"
AUTH_TOKEN="secret"

function callAPI {
  PAYLOAD=$1
  TASK_ID=$2
  URL="https://taskbadger.net/api/${ORGANIZATION}/${PROJECT}/tasks/"
  METHOD=POST
  if [ -n "$TASK_ID" ]; then
    URL="${URL}${TASK_ID}/"
    METHOD="PATCH"
  fi
  curl -X $METHOD $URL \
    -H "Authorization: Bearer ${AUTH_TOKEN}" -H "Content-Type: application/json" \
    -d "$PAYLOAD" --fail --silent
}

function createTask() {
  NAME="$1"
  PAYLOAD=$(jq -n --arg name "$NAME" '{"name": $name, "status": "processing"}')
  TASK_ID=$(callAPI "$PAYLOAD" | jq '.id' --raw-output)
  # Display an error message if the task was not created
  test $? -ne 0 && echo "[WARN] Unable to create task" 1>&2 && return 1
  echo "$TASK_ID"
}

function updateTaskStatus {
  TASK_ID="$1"
  # Exit early if the task ID is empty
  test -z "$TASK_ID" && return 1
  STATUS="$2"
  PAYLOAD=$(jq -n --arg status "$STATUS" '{"status": $status}')
  callAPI "$PAYLOAD" "$TASK_ID"

  # Display an error message if the task update failed
  test $? -ne 0 && echo "Unable to update task status" 1>&2;
}

TASK_ID=$(createTask "demo task 1")

# Perform the actual task in a subshell
(
  for i in $(seq 1 10); do
      echo $i
  done
)

if [ "$?" -ne 0 ]; then
  updateTaskStatus "$TASK_ID" "error"
else
  updateTaskStatus "$TASK_ID" "success"
fi
