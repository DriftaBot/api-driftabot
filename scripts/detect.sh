#!/usr/bin/env bash
# Detect the API schema type for the current project.
# Outputs: type=<nestjs|fastapi|go|graphql|grpc|openapi> to GITHUB_OUTPUT.
set -euo pipefail

detect_type() {
  # 1. Committed OpenAPI file (schema-first or previously generated)
  OPENAPI=$(find . -maxdepth 4 \( \
    -name "openapi.yaml" -o -name "openapi.yml" -o -name "openapi.json" \
    -o -name "api.yaml" -o -name "api.yml" -o -name "api.json" \
    -o -name "swagger.yaml" -o -name "swagger.yml" -o -name "swagger.json" \) \
    ! -path "*/node_modules/*" ! -path "*/.git/*" | head -1)
  if [ -n "$OPENAPI" ]; then
    echo "openapi"
    return
  fi

  # 2. GraphQL SDL
  GRAPHQL=$(find . -maxdepth 6 \( -name "*.graphql" -o -name "*.gql" \) \
    ! -path "*/node_modules/*" ! -path "*/.git/*" | head -1)
  if [ -n "$GRAPHQL" ]; then
    echo "graphql"
    return
  fi

  # 3. Protobuf
  PROTO=$(find . -maxdepth 6 -name "*.proto" ! -path "*/.git/*" | head -1)
  if [ -n "$PROTO" ]; then
    echo "grpc"
    return
  fi

  # 4. NestJS (code-first)
  if [ -f "package.json" ] && grep -q "@nestjs/swagger" package.json 2>/dev/null; then
    echo "nestjs"
    return
  fi

  # 5. FastAPI (code-first)
  if grep -qiE "^fastapi[>=<!\[]" requirements.txt 2>/dev/null || \
     grep -qiE 'fastapi' pyproject.toml 2>/dev/null; then
    echo "fastapi"
    return
  fi

  # 6. Go (code-first — swag or huma)
  if [ -f "go.mod" ]; then
    echo "go"
    return
  fi

  echo "unknown"
}

TYPE=$(detect_type)
echo "[drift-agent] detected project type: $TYPE"

if [ "$TYPE" = "unknown" ]; then
  echo "::error::Could not detect API schema type. Commit an openapi.yaml, *.graphql, or *.proto file, or ensure your framework is NestJS, FastAPI, or Go."
  exit 1
fi

echo "type=$TYPE" >> "${GITHUB_OUTPUT:-/dev/stdout}"
# Also export for use in the same shell session
export DRIFT_PROJECT_TYPE="$TYPE"
