#!/usr/bin/env bash
set -euo pipefail
AGENT="${1:-unknown}"
RECEIPT_JSON="${2:-{}}"
echo "[post-flight] agent=$AGENT"
echo "$RECEIPT_JSON" | python3 -m json.tool >/dev/null
echo "receipt json is valid"
# Stub: wire in artifact verification + circuit breaker recording.
