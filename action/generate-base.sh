#!/usr/bin/env bash
# Generate the base (target branch) API schema.
# Env vars: TYPE, OVERRIDE_BASE, BASE_REF
set -euo pipefail

if [ -n "${OVERRIDE_BASE:-}" ]; then
  GIT_PATH="${OVERRIDE_BASE#./}"
  git show "origin/${BASE_REF}:${GIT_PATH}" > /tmp/specs/base.yml 2>/dev/null || {
    echo "::warning::Could not read $OVERRIDE_BASE from origin/${BASE_REF} — using head as base"
    cp /tmp/specs/head.yml /tmp/specs/base.yml
  }
  echo "[drift-agent] base schema: override $OVERRIDE_BASE from origin/${BASE_REF}"
else
  bash /tmp/scripts/generate-base.sh \
    "$TYPE" \
    "$BASE_REF" \
    /tmp/specs/base.yml
fi
