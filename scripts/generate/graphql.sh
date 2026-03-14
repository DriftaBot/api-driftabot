#!/usr/bin/env bash
# Find the GraphQL SDL file and copy to $1.
set -euo pipefail

OUTPUT="${1:?Usage: graphql.sh <output_path>}"
mkdir -p "$(dirname "$OUTPUT")"

SCHEMA=$(find . -maxdepth 6 \( -name "*.graphql" -o -name "*.gql" \) \
  ! -path "*/node_modules/*" ! -path "*/.git/*" | head -1)

if [ -z "$SCHEMA" ]; then
  echo "::error::No GraphQL SDL file found (*.graphql or *.gql)" >&2
  exit 1
fi

cp "$SCHEMA" "$OUTPUT"
echo "[drift-agent] graphql schema: $SCHEMA → $OUTPUT"
