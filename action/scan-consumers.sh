#!/usr/bin/env bash
# Search for consumer repos affected by breaking changes and open GitHub Issues.
# Env vars: GITHUB_TOKEN, ORG_READ_TOKEN, ANTHROPIC_API_KEY, GITHUB_REPOSITORY_OWNER, GITHUB_REPOSITORY, PR_NUMBER
set -euo pipefail

drift-guard-agent \
  --diff /tmp/drift-diff.json \
  --org "$GITHUB_REPOSITORY_OWNER" \
  --token "$ORG_READ_TOKEN" \
  --github-token "$GITHUB_TOKEN" \
  --provider-repo "$GITHUB_REPOSITORY" \
  --pr "$PR_NUMBER"
