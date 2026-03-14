#!/usr/bin/env bash
# Diff base vs head schema and write breaking change count to GITHUB_OUTPUT.
# Env vars: TYPE, GITHUB_OUTPUT
set -euo pipefail

case "$TYPE" in
  graphql) CMD="graphql" ;;
  grpc)    CMD="grpc" ;;
  *)       CMD="openapi" ;;
esac

if ! drift-guard "$CMD" \
  --base /tmp/specs/base.yml \
  --head /tmp/specs/head.yml \
  --format json > /tmp/drift-diff.json; then
  echo "::error::drift-guard-engine failed to diff $CMD schemas. Check that both schema files are valid."
  exit 1
fi

BREAKING=$(python3 -c \
  "import json; d=json.load(open('/tmp/drift-diff.json')); print(d.get('summary',{}).get('breaking',0))" \
  2>/dev/null || echo "0")
echo "breaking=$BREAKING" >> "$GITHUB_OUTPUT"
echo "[drift-agent] $TYPE schema diff — breaking changes: $BREAKING"
