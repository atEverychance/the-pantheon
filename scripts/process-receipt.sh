#!/usr/bin/env bash
# Portable post-flight receipt processor.
#
# Environment:
#   PANTHEON_SCRIPT_DIR        override script directory
#   PANTHEON_LOG_FILE          override log file
#   PANTHEON_COMPLIANCE_FILE   override compliance json
#   PANTHEON_POST_HOOK         optional executable called as: hook <agent> <receipt-json>
#
# Usage:
#   process-receipt.sh <agent-id> '<receipt-json>'
#   process-receipt.sh stats

set -euo pipefail

SCRIPT_DIR="${PANTHEON_SCRIPT_DIR:-$(cd "$(dirname "$0")" && pwd)}"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_FILE="${PANTHEON_LOG_FILE:-$ROOT_DIR/.pantheon/logs/process-receipt.log}"
COMPLIANCE_FILE="${PANTHEON_COMPLIANCE_FILE:-$ROOT_DIR/.pantheon/logs/hook-compliance.json}"
VERIFY="$SCRIPT_DIR/verify-receipt.sh"
CB="$SCRIPT_DIR/circuit-breaker.sh"
POST_HOOK="${PANTHEON_POST_HOOK:-}"

mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$(dirname "$COMPLIANCE_FILE")"

log() {
  echo "[$(date -Iseconds)] $*" >> "$LOG_FILE"
}

ensure_compliance_file() {
  [ -f "$COMPLIANCE_FILE" ] || echo '{}' > "$COMPLIANCE_FILE"
}

compliance_track() {
  local agent="$1" status="$2"
  ensure_compliance_file
  python3 - "$COMPLIANCE_FILE" "$agent" "$status" <<'PY'
import json, sys
from pathlib import Path
from datetime import date
path = Path(sys.argv[1])
agent = sys.argv[2]
status = sys.argv[3]
date_key = date.today().isoformat()
data = json.loads(path.read_text()) if path.exists() else {}
day = data.setdefault(date_key, {"processed": 0, "successful": 0, "rejected": 0, "agents": {}})
if status in ("processed", "successful", "rejected"):
    day[status] += 1
agent_data = day["agents"].setdefault(agent, {"processed": 0, "successful": 0, "rejected": 0})
if status in agent_data:
    agent_data[status] += 1
path.write_text(json.dumps(data, indent=2) + "\n")
PY
}

human_summary() {
  python3 - "$1" <<'PY'
import json, sys
raw = sys.argv[1]
data = json.loads(raw)
r = data.get('receipt', data)
status = r.get('status', 'unknown')
task = r.get('task', 'unknown task')
claims = r.get('claims') or []
unc = r.get('uncertainties') or []
summary = []
for c in claims[:3]:
    if isinstance(c, dict):
        summary.append(f"{c.get('type', 'claim')}: {c.get('target', '')}")
print(f"REVIEW SUMMARY: status={status} | task={task}")
if summary:
    print("REVIEW CLAIMS: " + " ; ".join(summary))
if unc:
    print("REVIEW UNCERTAINTIES: " + " ; ".join(str(x) for x in unc[:3]))
PY
}

compliance_stats() {
  ensure_compliance_file
  python3 - "$COMPLIANCE_FILE" <<'PY'
import json, sys
from pathlib import Path
from datetime import date, timedelta
path = Path(sys.argv[1])
data = json.loads(path.read_text()) if path.exists() else {}
today = date.today().isoformat()
print("=" * 50)
print("Pantheon receipt-processing stats")
print("=" * 50)
today_data = data.get(today, {})
proc = today_data.get("processed", 0)
succ = today_data.get("successful", 0)
rej = today_data.get("rejected", 0)
rate = (succ / proc * 100) if proc else 0
print(f"today: processed={proc} successful={succ} rejected={rej} success_rate={rate:.0f}%")
for i in range(6, -1, -1):
    d = (date.today() - timedelta(days=i)).isoformat()
    dd = data.get(d, {})
    p = dd.get("processed", 0)
    s = dd.get("successful", 0)
    r = (s / p * 100) if p else 0
    print(f"{d}: {s}/{p} ({r:.0f}%)")
PY
}

if [ "${1:-}" = "stats" ]; then
  compliance_stats
  exit 0
fi

AGENT="${1:-}"
RECEIPT="${2:-}"
[ -n "$AGENT" ] && [ -n "$RECEIPT" ] || { echo "Usage: $0 <agent-id> '<receipt-json>'" >&2; exit 1; }

log "=== Processing receipt for $AGENT"
compliance_track "$AGENT" processed

set +e
VERIFY_OUTPUT="$($VERIFY "$RECEIPT" 2>&1)"
VERIFY_RESULT=$?
set -e

printf '%s\n' "$VERIFY_OUTPUT" | tee -a "$LOG_FILE"
SUMMARY_OUTPUT=$(human_summary "$RECEIPT" 2>&1 || true)
[ -z "$SUMMARY_OUTPUT" ] || printf '%s\n' "$SUMMARY_OUTPUT" | tee -a "$LOG_FILE"

if [ "$VERIFY_RESULT" -ne 0 ]; then
  log "Receipt verification failed for $AGENT"
  MISSING_FILES=$(printf '%s\n' "$VERIFY_OUTPUT" | awk -F': ' '/^REJECT: missing_file: / {print $3}')
  if [ -n "$MISSING_FILES" ]; then
    # shellcheck disable=SC2086
    "$CB" record "$AGENT" failure RECEIPT_VERIFICATION_FAILED $MISSING_FILES >> "$LOG_FILE" 2>&1 || true
  else
    "$CB" record "$AGENT" failure RECEIPT_VERIFICATION_FAILED >> "$LOG_FILE" 2>&1 || true
  fi

  if "$CB" should-escalate "$AGENT" >/dev/null 2>&1; then
    echo "CIRCUIT_OPEN"
    compliance_track "$AGENT" rejected
    exit 1
  fi

  echo "RECEIPT_REJECTED"
  compliance_track "$AGENT" rejected
  exit 1
fi

"$CB" record-success "$AGENT" >> "$LOG_FILE" 2>&1 || true
compliance_track "$AGENT" successful

if [ -n "$POST_HOOK" ] && [ -x "$POST_HOOK" ]; then
  "$POST_HOOK" "$AGENT" "$RECEIPT" >> "$LOG_FILE" 2>&1 || log "post-hook failed for $AGENT"
fi

log "=== Completed receipt for $AGENT"
echo "RECEIPT_VERIFIED"
