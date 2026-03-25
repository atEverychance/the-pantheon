#!/usr/bin/env bash
# Portable receipt verifier.
#
# Checks:
# - JSON parses
# - required receipt fields exist
# - completed receipts are not empty theater
# - output files exist when path-like
# - basic syntax checks for sh/py/js/ts/json/md/go files when local files are present
#
# Exit 0 on acceptance, 1 on rejection.

set -euo pipefail

RECEIPT_JSON="${1:-}"
[ -n "$RECEIPT_JSON" ] || { echo "Usage: $0 '<receipt-json>'" >&2; exit 1; }

TMP="$(mktemp)"
printf '%s' "$RECEIPT_JSON" > "$TMP"

cleanup() { rm -f "$TMP"; }
trap cleanup EXIT

python3 - "$TMP" <<'PY'
import json, sys, os
path = sys.argv[1]
raw = open(path).read()
try:
    data = json.loads(raw)
except Exception as e:
    print(f"REJECT: invalid_json: {e}")
    sys.exit(1)

r = data.get("receipt", data)
required = ["agent", "task", "status", "outputs", "claims", "evidence", "confidence", "uncertainties", "observations"]
missing = [k for k in required if k not in r]
if missing:
    print("REJECT: missing_fields: " + ",".join(missing))
    sys.exit(1)

if r.get("status") not in {"completed", "partial", "failed", "unverifiable"}:
    print("REJECT: invalid_status")
    sys.exit(1)

claims = r.get("claims") or []
outputs = r.get("outputs") or []
if r.get("status") == "completed" and not claims and not outputs:
    print("REJECT: completed_without_outputs_or_claims")
    sys.exit(1)

claim_types = [c.get("type") for c in claims if isinstance(c, dict)]
if r.get("status") == "completed" and claim_types and all(ct == "asserted" for ct in claim_types):
    print("REJECT: asserted_only_completed_receipt")
    sys.exit(1)

print("PARSE_OK")
PY

FAILED=0

extract_lines() {
  python3 - "$TMP" "$1" <<'PY'
import json, sys
raw = open(sys.argv[1]).read()
key = sys.argv[2]
data = json.loads(raw)
r = data.get("receipt", data)
for item in (r.get(key) or []):
    if isinstance(item, str):
        print(item)
    elif key == "claims" and isinstance(item, dict):
        print(item.get("target", ""))
PY
}

check_file() {
  local path="$1"
  [ -n "$path" ] || return 0
  [ -f "$path" ] || { echo "REJECT: missing_file: $path"; FAILED=1; return 0; }

  case "$path" in
    *.sh)
      bash -n "$path" 2>/dev/null || { echo "REJECT: shell_syntax: $path"; FAILED=1; }
      ;;
    *.py)
      python3 -m py_compile "$path" 2>/dev/null || { echo "REJECT: python_syntax: $path"; FAILED=1; }
      ;;
    *.js|*.cjs|*.mjs)
      node --check "$path" 2>/dev/null || { echo "REJECT: js_syntax: $path"; FAILED=1; }
      ;;
    *.json)
      python3 -m json.tool "$path" >/dev/null 2>&1 || { echo "REJECT: json_syntax: $path"; FAILED=1; }
      ;;
    *.md)
      :
      ;;
    *.go)
      if command -v go >/dev/null 2>&1; then
        go build -o /tmp/pantheon-go-check-$$ "$path" >/dev/null 2>&1 || { echo "REJECT: go_build: $path"; FAILED=1; }
        rm -f /tmp/pantheon-go-check-$$
      fi
      ;;
    *.ts)
      if command -v npx >/dev/null 2>&1; then
        npx --yes tsc --noEmit "$path" >/dev/null 2>&1 || echo "WARN: ts_check_skipped_or_failed: $path"
      fi
      ;;
  esac
}

while IFS= read -r output; do
  case "$output" in
    /*|./*|../* ) check_file "$output" ;;
  esac
done < <(extract_lines outputs)

while IFS= read -r target; do
  case "$target" in
    /*|./*|../* ) check_file "$target" ;;
    pattern::* ) : ;;
    *::* ) : ;;
  esac
done < <(extract_lines claims)

if [ "$FAILED" -eq 1 ]; then
  echo "RECEIPT REJECTED"
  exit 1
fi

echo "RECEIPT ACCEPTED"
