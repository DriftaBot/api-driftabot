"""Discover node: resolve consumer repos to scan.

Requires an explicit consumer-repos list — no org-wide code search is performed.
"""

from __future__ import annotations

import os

from drift_guard_agent.state import ConsumerRepo, DriftState


def discover_consumers(state: DriftState) -> dict:
    token = state.get("token", "") or os.environ.get("ORG_READ_TOKEN", "")
    provider_repo = state.get("provider_repo", "")

    explicit = [r.strip() for r in state.get("consumer_repos", []) if r.strip()]
    if not explicit:
        print("[discover] No consumer-repos specified — skipping consumer scan")
        return {"consumers": []}

    if not token:
        print("[discover] No token — skipping consumer scan")
        return {"consumers": []}

    consumers = [
        ConsumerRepo(
            full_name=name,
            clone_url=f"https://x-access-token:{token}@github.com/{name}.git",
        )
        for name in explicit
        if name != provider_repo
    ]
    print(f"[discover] Scanning {len(consumers)} explicit consumer repo(s): {[c.full_name for c in consumers]}")
    return {"consumers": consumers}
