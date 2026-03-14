#!/usr/bin/env bash
# Warn if GITHUB_TOKEN is missing 'issues: write' permission.
# Env vars: GITHUB_TOKEN, GITHUB_REPOSITORY (both auto-set by Actions runner)
set -euo pipefail

PERM=$(curl -sSf \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/$GITHUB_REPOSITORY" \
  | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('permissions',{}).get('push',False))" 2>/dev/null || echo "False")

if [ "$PERM" != "True" ]; then
  echo "::warning::drift-guard-agent: the GITHUB_TOKEN may not have 'issues: write'. Issues will not be created in consumer repos. Add 'issues: write' to your workflow permissions."
fi
