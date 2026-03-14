#!/usr/bin/env bash
# Generate OpenAPI schema from a Go project using swag.
# Falls back to any committed swagger/openapi file if generation fails.
set -euo pipefail

OUTPUT="${1:?Usage: go.sh <output_path>}"
mkdir -p "$(dirname "$OUTPUT")"

# Try swag (Gin/Echo/Fiber)
if command -v swag &>/dev/null || go install github.com/swaggo/swag/cmd/swag@latest 2>/dev/null; then
  SWAG_OUT=$(mktemp -d)
  if swag init -g main.go -o "$SWAG_OUT" --quiet 2>/dev/null; then
    if [ -f "$SWAG_OUT/swagger.yaml" ]; then
      cp "$SWAG_OUT/swagger.yaml" "$OUTPUT"
      echo "[drift-agent] generated Go OpenAPI schema via swag → $OUTPUT"
      exit 0
    elif [ -f "$SWAG_OUT/swagger.json" ]; then
      cp "$SWAG_OUT/swagger.json" "$OUTPUT"
      echo "[drift-agent] generated Go OpenAPI schema via swag → $OUTPUT"
      exit 0
    fi
  fi
fi

echo "::warning::swag generation failed — falling back to committed schema file"

# Fallback: look for any committed OpenAPI/swagger file
COMMITTED=$(find . -maxdepth 4 \( \
  -name "openapi.yaml" -o -name "openapi.yml" -o -name "openapi.json" \
  -o -name "swagger.yaml" -o -name "swagger.yml" -o -name "swagger.json" \
  -o -name "docs/swagger.yaml" -o -name "docs/swagger.json" \) \
  ! -path "*/.git/*" | head -1)

if [ -n "$COMMITTED" ]; then
  cp "$COMMITTED" "$OUTPUT"
  echo "[drift-agent] fallback: using committed schema $COMMITTED"
  exit 0
fi

echo "::error::Go schema generation failed and no committed schema found. Run 'swag init' and commit docs/swagger.yaml, or use a schema-first approach." >&2
exit 1
