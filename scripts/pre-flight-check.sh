#!/usr/bin/env bash
# Portable pre-flight gate for Pantheon spawns.
#
# Environment:
#   PANTHEON_FALLBACK_MAP   optional newline-delimited agent:fallback map file
#   PANTHEON_SCRIPT_DIR     override script directory
#
# Exit codes:
#   0 = ready (may include fallback recommendation in output/env)
#   1 = blocked / escalate to human

set -euo pipefail

SCRIPT_DIR="${PANTHEON_SCRIPT_DIR:-$(cd "$(dirname "$0")" && pwd)}"
CB="$SCRIPT_DIR/circuit-breaker.sh"
AGENT="${1:-}"
CONTEXT="${2:-unknown}"
EXPLICIT_FALLBACK="${3:-}"

[ -n "$AGENT" ] || { echo "Usage: $0 <agent-id> <context> [fallback-agent]" >&2; exit 1; }

get_fallback() {
  local agent="$1"

  if [ -n "$EXPLICIT_FALLBACK" ] && [ "$EXPLICIT_FALLBACK" != "--cron-mode" ]; then
    printf '%s\n' "$EXPLICIT_FALLBACK"
    return
  fi

  if [ -n "${PANTHEON_FALLBACK_MAP:-}" ] && [ -f "$PANTHEON_FALLBACK_MAP" ]; then
    local mapped
    mapped=$(awk -F: -v a="$agent" '$1==a {print $2; exit}' "$PANTHEON_FALLBACK_MAP")
    if [ -n "$mapped" ]; then
      printf '%s\n' "$mapped"
      return
    fi
  fi

  case "$agent" in
    coder)         echo "senior-coder" ;;
    tester)        echo "senior-coder" ;;
    scout)         echo "researcher" ;;
    researcher)    echo "senior-coder" ;;
    pm)            echo "bigbrain" ;;
    writer)        echo "pm" ;;
    git-manager)   echo "senior-coder" ;;
    bigbrain)      echo "senior-coder" ;;
    senior-coder)  echo "senior-coder" ;;
    synthesizer)   echo "bigbrain" ;;
    publisher)     echo "writer" ;;
    artist)        echo "marketer" ;;
    tool)          echo "senior-coder" ;;
    *)             echo "senior-coder" ;;
  esac
}

check_circuit() {
  local agent="$1"
  if "$CB" should-escalate "$agent" >/dev/null 2>&1; then
    return 1
  fi
  return 0
}

receipt_hint() {
  case "$1" in
    artist|coder|git-manager|senior-coder)
      echo "receipt_hint=file-output"
      ;;
    publisher)
      echo "receipt_hint=url-output"
      ;;
    heracles|scout|writer)
      echo "receipt_hint=message-output"
      ;;
    bigbrain|pm|researcher|synthesizer|tester|tool)
      echo "receipt_hint=decision-output"
      ;;
    *)
      echo "receipt_hint=generic"
      ;;
  esac
}

if "$CB" is-probation "$AGENT" >/dev/null 2>&1; then
  echo "status=ok"
  echo "agent=$AGENT"
  echo "probation=true"
  receipt_hint "$AGENT"
  exit 0
fi

if check_circuit "$AGENT"; then
  echo "status=ok"
  echo "agent=$AGENT"
  echo "context=$CONTEXT"
  receipt_hint "$AGENT"
  exit 0
fi

FALLBACK="$(get_fallback "$AGENT")"

if [ -z "$FALLBACK" ]; then
  echo "status=blocked"
  echo "agent=$AGENT"
  echo "reason=no_fallback_configured"
  exit 1
fi

if check_circuit "$FALLBACK"; then
  "$CB" record-fallback-success "$AGENT" >/dev/null 2>&1 || true
  echo "status=fallback"
  echo "agent=$AGENT"
  echo "fallback_agent=$FALLBACK"
  echo "context=$CONTEXT"
  receipt_hint "$AGENT"
  exit 0
fi

if [ "$FALLBACK" != "senior-coder" ] && check_circuit "senior-coder"; then
  echo "status=fallback"
  echo "agent=$AGENT"
  echo "fallback_agent=senior-coder"
  echo "attempted_fallback=$FALLBACK"
  echo "context=$CONTEXT"
  receipt_hint "$AGENT"
  exit 0
fi

echo "status=blocked"
echo "agent=$AGENT"
echo "reason=all_fallbacks_exhausted"
echo "context=$CONTEXT"
exit 1
