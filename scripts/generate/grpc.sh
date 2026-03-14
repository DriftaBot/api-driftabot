#!/usr/bin/env bash
# Find the primary Protobuf file and copy to $1.
# For multiple .proto files, concatenates them in sorted order.
set -euo pipefail

OUTPUT="${1:?Usage: grpc.sh <output_path>}"
mkdir -p "$(dirname "$OUTPUT")"

PROTOS=$(find . -maxdepth 6 -name "*.proto" ! -path "*/.git/*" | sort)

if [ -z "$PROTOS" ]; then
  echo "::error::No .proto files found" >&2
  exit 1
fi

COUNT=$(echo "$PROTOS" | wc -l | tr -d ' ')
if [ "$COUNT" -eq 1 ]; then
  cp "$PROTOS" "$OUTPUT"
  echo "[drift-agent] grpc schema: $PROTOS → $OUTPUT"
else
  # Multiple .proto files — concatenate with separators
  > "$OUTPUT"
  echo "$PROTOS" | while IFS= read -r f; do
    echo "// === $f ===" >> "$OUTPUT"
    cat "$f" >> "$OUTPUT"
    echo "" >> "$OUTPUT"
  done
  echo "[drift-agent] grpc schema: $COUNT .proto files concatenated → $OUTPUT"
fi
