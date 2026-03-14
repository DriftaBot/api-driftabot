#!/usr/bin/env bash
# Generate OpenAPI schema from a NestJS project using SwaggerModule.
# Falls back to any committed swagger/openapi file if generation fails.
set -euo pipefail

OUTPUT="${1:?Usage: nestjs.sh <output_path>}"
mkdir -p "$(dirname "$OUTPUT")"

# Install dependencies
echo "[drift-agent] installing NestJS dependencies..."
if [ -f "pnpm-lock.yaml" ]; then
  pnpm install --frozen-lockfile --prefer-offline 2>/dev/null || pnpm install
elif [ -f "yarn.lock" ]; then
  yarn install --frozen-lockfile 2>/dev/null || yarn install
else
  npm ci 2>/dev/null || npm install
fi

# Write the schema generation script
cat > /tmp/drift-nestjs-gen.ts << 'GENEOF'
import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import * as fs from 'fs';
import * as path from 'path';

const OUTPUT = process.env.DRIFT_OUTPUT!;

async function generate() {
  const candidates = [
    './src/app.module',
    './src/app/app.module',
    './app.module',
    './app/app.module',
  ];

  let AppModule: any;
  for (const p of candidates) {
    try {
      AppModule = (await import(path.resolve(p))).AppModule;
      if (AppModule) break;
    } catch {}
  }

  if (!AppModule) {
    console.error('[drift-agent] AppModule not found — tried:', candidates.join(', '));
    process.exit(1);
  }

  const app = await NestFactory.create(AppModule, { logger: false });
  const config = new DocumentBuilder()
    .setTitle('API')
    .setVersion('1.0')
    .build();
  const doc = SwaggerModule.createDocument(app, config);
  fs.mkdirSync(path.dirname(OUTPUT), { recursive: true });
  fs.writeFileSync(OUTPUT, JSON.stringify(doc, null, 2));
  console.log(`[drift-agent] generated NestJS OpenAPI schema → ${OUTPUT}`);
  await app.close();
}

generate().catch(e => {
  console.error('[drift-agent] NestJS schema generation failed:', e.message);
  process.exit(1);
});
GENEOF

# Run the generation script
DRIFT_OUTPUT="$OUTPUT" npx ts-node \
  --project tsconfig.json \
  --transpile-only \
  /tmp/drift-nestjs-gen.ts 2>&1 && exit 0

echo "::warning::NestJS ts-node generation failed — falling back to committed schema file"

# Fallback: look for any committed OpenAPI/swagger file
COMMITTED=$(find . -maxdepth 4 \( \
  -name "openapi.yaml" -o -name "openapi.yml" -o -name "openapi.json" \
  -o -name "swagger.yaml" -o -name "swagger.yml" -o -name "swagger.json" \) \
  ! -path "*/node_modules/*" ! -path "*/.git/*" | head -1)

if [ -n "$COMMITTED" ]; then
  cp "$COMMITTED" "$OUTPUT"
  echo "[drift-agent] fallback: using committed schema $COMMITTED"
  exit 0
fi

echo "::error::NestJS schema generation failed and no committed schema found. Commit a swagger.json or fix ts-node setup." >&2
exit 1
