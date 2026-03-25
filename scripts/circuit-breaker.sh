#!/usr/bin/env bash
# Portable circuit breaker for agent orchestration.
#
# State file can be overridden with PANTHEON_STATE_FILE.
# Threshold can be overridden with PANTHEON_CIRCUIT_THRESHOLD.
# Probation threshold can be overridden with PANTHEON_PROBATION_AFTER_FALLBACKS.

set -euo pipefail

STATE_FILE="${PANTHEON_STATE_FILE:-$(cd "$(dirname "$0")/.." && pwd)/.pantheon/agent-failures.json}"
THRESHOLD="${PANTHEON_CIRCUIT_THRESHOLD:-3}"
PROBATION_AFTER_FALLBACKS="${PANTHEON_PROBATION_AFTER_FALLBACKS:-2}"

usage() {
  echo "Usage: $0 {should-escalate|is-probation|record|record-success|record-fallback-success|activate-probation|record-probation-success|record-probation-failure|get-failures|get-escalation-context|reset} <agent> [args...]" >&2
  exit 1
}

[ $# -ge 2 ] || usage

cmd="$1"
agent="$2"

ensure_state_file() {
  mkdir -p "$(dirname "$STATE_FILE")"
  if [ ! -f "$STATE_FILE" ]; then
    printf '{\n  "agents": {}\n}\n' > "$STATE_FILE"
  fi
}

py_run() {
  python3 - "$STATE_FILE" "$agent" "$THRESHOLD" "$cmd" "$PROBATION_AFTER_FALLBACKS" "${@:-}" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

state_path = Path(sys.argv[1])
agent = sys.argv[2]
threshold = int(sys.argv[3])
cmd = sys.argv[4]
probation_threshold = int(sys.argv[5])
args = sys.argv[6:]


def now_iso():
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace('+00:00', 'Z')


def load_state(path):
    try:
        data = json.loads(path.read_text())
    except Exception:
        data = {}
    if not isinstance(data, dict):
        data = {}
    agents = data.get("agents")
    if not isinstance(agents, dict):
        agents = {}
    data["agents"] = agents
    return data


def save_state(path, data):
    path.write_text(json.dumps(data, indent=2) + "\n")


def get_agent(data, name):
    entry = data["agents"].get(name)
    if not isinstance(entry, dict):
        entry = {
            "failures": 0,
            "last_failure": None,
            "on_probation": False,
            "fallback_successes": 0,
            "probation_attempts": 0,
            "last_probation": None,
            "escalation_context": None,
        }
    entry["failures"] = int(entry.get("failures", 0) or 0)
    entry["fallback_successes"] = int(entry.get("fallback_successes", 0) or 0)
    entry["probation_attempts"] = int(entry.get("probation_attempts", 0) or 0)
    entry["on_probation"] = bool(entry.get("on_probation", False))
    data["agents"][name] = entry
    return entry

state = load_state(state_path)
entry = get_agent(state, agent)

if cmd == "should-escalate":
    if entry.get("on_probation"):
        sys.exit(1)
    sys.exit(0 if entry["failures"] >= threshold else 1)

elif cmd == "is-probation":
    sys.exit(0 if entry.get("on_probation") else 1)

elif cmd == "record":
    if not args or args[0] != "failure":
        print("record command requires first extra argument: failure", file=sys.stderr)
        sys.exit(2)
    reason = args[1] if len(args) > 1 else ""
    missing_artifacts = args[2:] if len(args) > 2 else []
    entry["failures"] += 1
    entry["last_failure"] = now_iso()
    entry["escalation_context"] = {
        "reason": reason,
        "missing_artifacts": missing_artifacts,
        "timestamp": now_iso(),
    }
    if entry.get("on_probation"):
        entry["probation_attempts"] += 1
        entry["on_probation"] = False
        entry["fallback_successes"] = 0
    save_state(state_path, state)
    print(json.dumps(entry))
    sys.exit(0)

elif cmd == "get-escalation-context":
    ctx = entry.get("escalation_context") or {}
    print(json.dumps(ctx))
    sys.exit(0)

elif cmd == "record-success":
    entry["failures"] = 0
    entry["last_failure"] = None
    entry["on_probation"] = False
    entry["fallback_successes"] = 0
    entry["probation_attempts"] = 0
    entry["last_probation"] = None
    entry["escalation_context"] = None
    save_state(state_path, state)
    print(json.dumps(entry))
    sys.exit(0)

elif cmd == "record-fallback-success":
    entry["fallback_successes"] = entry.get("fallback_successes", 0) + 1
    entry["escalation_context"] = None
    save_state(state_path, state)
    if entry["fallback_successes"] >= probation_threshold and entry.get("failures", 0) >= threshold:
        print(f"PROBATION_RECOMMENDED ({entry['fallback_successes']} fallback successes)")
    else:
        print(f"fallback_successes={entry['fallback_successes']} (need {probation_threshold} for probation)")
    sys.exit(0)

elif cmd == "activate-probation":
    entry["on_probation"] = True
    entry["last_probation"] = now_iso()
    save_state(state_path, state)
    print(json.dumps(entry))
    sys.exit(0)

elif cmd == "record-probation-success":
    entry["failures"] = 0
    entry["last_failure"] = None
    entry["on_probation"] = False
    entry["fallback_successes"] = 0
    entry["probation_attempts"] += 1
    entry["last_probation"] = now_iso()
    entry["escalation_context"] = None
    save_state(state_path, state)
    print(json.dumps(entry))
    sys.exit(0)

elif cmd == "record-probation-failure":
    entry["on_probation"] = False
    entry["fallback_successes"] = 0
    entry["probation_attempts"] += 1
    entry["last_probation"] = now_iso()
    save_state(state_path, state)
    print(json.dumps(entry))
    sys.exit(0)

elif cmd == "reset":
    entry["failures"] = 0
    entry["last_failure"] = None
    entry["on_probation"] = False
    entry["fallback_successes"] = 0
    entry["probation_attempts"] = 0
    entry["last_probation"] = None
    entry["escalation_context"] = None
    save_state(state_path, state)
    print(json.dumps(entry))
    sys.exit(0)

print("Unknown command", file=sys.stderr)
sys.exit(2)
PY
}

ensure_state_file

case "$cmd" in
  should-escalate|is-probation|get-escalation-context|record-success|record-fallback-success|record-probation-success|record-probation-failure|activate-probation|reset)
    py_run
    ;;
  record)
    [ $# -ge 3 ] || usage
    py_run "${@:3}"
    ;;
  get-failures)
    python3 - "$STATE_FILE" "$agent" <<'PY'
import json, sys
from pathlib import Path
state_path = Path(sys.argv[1])
agent = sys.argv[2]
try:
    data = json.loads(state_path.read_text())
    e = data.get("agents", {}).get(agent, {})
    print(f"failures={e.get('failures', 0)} on_probation={e.get('on_probation', False)} fallback_successes={e.get('fallback_successes', 0)}")
except Exception:
    print("failures=0 on_probation=False fallback_successes=0")
PY
    ;;
  *)
    usage
    ;;
esac
