#!/usr/bin/env bash
set -euo pipefail
AGENT="${1:-unknown}"
CONTEXT="${2:-}"
echo "[pre-flight] agent=$AGENT context=$CONTEXT"
# Stub: wire in circuit-breaker / health / limits for your runtime.
