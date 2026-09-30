#!/usr/bin/env python3
"""Regenerate the known early free rewards; do not edit the JSON by hand.

Sources are the checked reading in docs/TOWER_RULES.md (28 September 2026)
and the developer's v29 patch notes (25 August 2026). Later wave rewards
remain absent until their exact amounts are verified.
"""
import json
from pathlib import Path

milestones = [
    {"tier": 1, "wave": 10, "coins": 10, "gems": 0},
    {"tier": 1, "wave": 20, "coins": 0, "gems": 10},
    {"tier": 1, "wave": 30, "coins": 0, "gems": 0},
    {"tier": 1, "wave": 40, "coins": 150, "gems": 0},
    {"tier": 1, "wave": 50, "coins": 0, "gems": 15},
    {"tier": 1, "wave": 80, "coins": 1500, "gems": 0},
    {"tier": 1, "wave": 90, "coins": 0, "gems": 20},
    {"tier": 1, "wave": 100, "coins": 0, "gems": 0},
    {"tier": 2, "wave": 10, "coins": 250, "gems": 0},
]
data = {
    "version": 1,
    "sources": [
        "https://the-tower-idle-tower-defense.fandom.com/wiki/Milestones",
        "https://www.techtreegames.com/post/v29-patch-notes-august-25-2026",
    ],
    "milestones": milestones,
    "daily_gems": 20,
}
output = Path(__file__).resolve().parents[1] / "data/tower/progression.json"
output.write_text(json.dumps(data, separators=(",", ":")) + "\n")
print(f"Wrote {len(milestones)} known milestones to {output}")
