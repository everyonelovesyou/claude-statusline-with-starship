#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

# Claude Code statusline (w/ Starship)
# stdin から JSON を受け取り、環境変数にエクスポートして starship prompt を実行する
#
# Based on: https://github.com/martinemde/starship-claude

payload="$(cat || true)"

if command -v jq >/dev/null 2>&1 && [ -n "$payload" ]; then

  get_model_name() { echo "$payload" | jq -r '.model.display_name'; }
  # get_current_dir() { echo "$payload" | jq -r '.workspace.current_dir'; }
  # get_project_dir() { echo "$payload" | jq -r '.workspace.project_dir'; }
  # get_version() { echo "$payload" | jq -r '.version'; }
  # get_input_tokens() { echo "$input" | jq -r '.context_window.total_input_tokens'; }
  # get_output_tokens() { echo "$payload" | jq -r '.context_window.total_output_tokens'; }
  get_usage() { echo "$payload" | jq -r '.context_window.current_usage'; }
  get_context_window_size() { echo "$payload" | jq -r '.context_window.context_window_size'; }

  model_name=$(get_model_name)
  export CLAUDE_MODEL="$model_name"
  context_size=$(get_context_window_size)
  usage=$(get_usage)

  # コンテキスト使用率を計算する
  if [ "$usage" != "null" ]; then
    current_tokens=$(echo "$usage" | jq '.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens')
    percent=$((current_tokens * 100 / context_size))
    export CLAUDE_CONTEXT="${percent}%"
  else
    export CLAUDE_CONTEXT="0%"
  fi
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

STARSHIP_CONFIG="$SCRIPT_DIR/starship.toml" \
  STARSHIP_SHELL=sh \
  starship prompt
