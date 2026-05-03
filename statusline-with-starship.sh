#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

# Claude Code statusline (w/ Starship)
# stdin から JSON を受け取り、環境変数にエクスポートして starship prompt を実行する
#
# Inspired by: https://github.com/martinemde/starship-claude

input="$(cat || true)"

if command -v jq >/dev/null 2>&1 && [ -n "$input" ]; then

  MODEL=$(echo "$input" | jq -r '.model.display_name')
  effort=$(echo "$input" | jq -r '.effort.level // empty')
  CONTEXT=$(echo "$input" | jq -r '(.context_window.used_percentage // 0) | round')
  rate_5h_pct=$(echo "$input" | jq -r '(.rate_limits.five_hour.used_percentage // 0) | round')
  rate_5h_reset_epoch=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
  rate_7d_pct=$(echo "$input" | jq -r '(.rate_limits.seven_day.used_percentage // 0) | round')
  rate_7d_reset_epoch=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

  export CLAUDE_MODEL="$MODEL"

  # effort
  if [ -n "$effort" ]; then
    EFFORT=""
    case "$effort" in
      "low" ) EFFORT="󰋕" ;; # f02d5  nf-md-heart_outline
      "medium" ) EFFORT="󰛞" ;; # f06de  nf-md-heart_half_full
      "high" | "xhigh" ) EFFORT="󰋑" ;; # f02d1  nf-md-heart
      "max" ) EFFORT="󰋑󰋕" ;; # f02d1 f02d5
      * ) EFFORT="󰋔" ;; # f0d14  nf-md-heart_broken_outline
    esac
    export CLAUDE_EFFORT="$EFFORT"
  fi

  # コンテキスト使用率
  export CLAUDE_CONTEXT="${CONTEXT}%"

  # レート制限 5h
  if [ -n "$rate_5h_reset_epoch" ]; then
    rate_5h_reset_jst=$(TZ='Asia/Tokyo' date -r "$rate_5h_reset_epoch" '+%-H:%M')
    export CLAUDE_RATE_5H="${rate_5h_pct}%(${rate_5h_reset_jst})"
  fi

  # レート制限 7d
  if [ -n "$rate_7d_reset_epoch" ]; then
    rate_7d_reset_jst=$(TZ='Asia/Tokyo' date -r "$rate_7d_reset_epoch" '+%-m/%-d %-H:%M')
    export CLAUDE_RATE_7D="${rate_7d_pct}%(${rate_7d_reset_jst})"
  fi

fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

STARSHIP_CONFIG="$SCRIPT_DIR/starship.toml" \
  STARSHIP_SHELL=sh \
  starship prompt
