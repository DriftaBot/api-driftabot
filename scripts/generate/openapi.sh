#!/usr/bin/env bash
# Generate (find) a committed OpenAPI schema and copy to $1.
set -euo pipefail

OUTPUT="${1:?Usage: openapi.sh <output_path>}"
mkdir -p "$(dirname "$OUTPUT")"

SCHEMA=$(find . -maxdepth 4 \( \
  -name "openapi.yaml" -o -name "openapi.yml" -o -name "openapi.json" \
  -o -name "api.yaml" -o -name "api.yml" -o -name "api.json" \
  -o -name "swagger.yaml" -o -name "swagger.yml" -o -name "swagger.json" \) \
  ! -path "*/node_modules/*" ! -path "*/.git/*" | head -1)

if [ -z "$SCHEMA" ]; then
  echo "::error::No committed OpenAPI schema found (openapi.yaml, swagger.json, etc.)" >&2
  exit 1
fi

cp "$SCHEMA" "$OUTPUT"
echo "[drift-agent] openapi schema: $SCHEMA → $OUTPUT"
