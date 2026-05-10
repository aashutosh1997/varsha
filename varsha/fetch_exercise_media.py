#!/usr/bin/env python3
"""
fetch_exercise_media.py

Downloads exercise demonstration media for every exercise referenced in
Varsha's WorkoutData.swift. Tries two sources in order:

  1. ExerciseDB v1 (https://oss.exercisedb.dev) — animated GIFs, AGPL-3.0
     Best fidelity. Free hosted tier, no auth needed, 180p GIFs.

  2. yuhonas/free-exercise-db                   — start/end photos, public domain
     Fallback for any exercise that doesn't match in ExerciseDB. The Swift
     side renders these as a two-frame crossfade animation.

Output:
  Varsha/Resources/ExerciseMedia/
    back-squat.gif                  (preferred, when EDB match exists)
    rdl.gif
    ...
    bulgarian-split-squat-0.jpg     (fallback, when no GIF found)
    bulgarian-split-squat-1.jpg
    manifest.json                   (records what we got per exercise)

The manifest.json shape:
  {
    "back-squat":            { "kind": "gif",    "files": ["back-squat.gif"] },
    "bulgarian-split-squat": { "kind": "frames", "files": ["bulgarian-split-squat-0.jpg", "bulgarian-split-squat-1.jpg"] },
    "lateral-lunge":         { "kind": "none",   "files": [] }
  }

LICENSING: Because Varsha bundles GIFs from ExerciseDB (AGPL-3.0), the
combined work must also be AGPL-3.0. Make sure the Varsha repo has an
AGPL-3.0 LICENSE file before publishing.

Usage:
  python3 fetch_exercise_media.py [--out PATH] [--gifs-only] [--frames-only] [--dry-run]
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Optional

# ---------------------------------------------------------------------------
# Mapping 1 — Varsha id -> candidate ExerciseDB names (substring matched)
# Each list is tried in order; first name that appears as a case-insensitive
# substring of any EDB exercise name wins. Add or reorder candidates as you
# discover better matches in the data.
# ---------------------------------------------------------------------------

EDB_NAME_CANDIDATES: dict[str, list[str]] = {
    # Lower body
    "back-squat":            ["barbell back squat", "barbell full squat", "barbell squat"],
    "goblet-squat":          ["dumbbell goblet squat", "goblet squat"],
    "leg-press":             ["sled 45° leg press", "leg press", "sled leg press"],
    "hack-squat":            ["barbell hack squat", "sled hack squat", "hack squat"],
    "rdl":                   ["barbell romanian deadlift", "romanian deadlift"],
    "db-rdl":                ["dumbbell romanian deadlift"],
    "cable-pull-through":    ["cable pull through", "cable pull-through"],
    "bulgarian-split-squat": ["dumbbell bulgarian split squat", "barbell bulgarian split squat", "bulgarian split squat"],
    "reverse-lunge":         ["dumbbell rear lunge", "barbell reverse lunge", "reverse lunge", "dumbbell reverse lunge"],
    "walking-lunge":         ["dumbbell walking lunge", "barbell walking lunge", "walking lunge"],
    "step-up":               ["dumbbell step-up", "dumbbell step up", "barbell step up", "step-up"],
    "ham-curl":              ["lever seated leg curl", "seated leg curl"],
    "lying-ham-curl":        ["lever lying leg curl", "lying leg curl"],
    "nordic-curl":           ["nordic hamstring", "natural glute ham raise", "glute ham raise"],
    "hip-thrust":            ["barbell hip thrust", "hip thrust"],
    "glute-bridge":          ["barbell glute bridge", "glute bridge", "hip lift"],
    "single-leg-hip-thrust": ["single leg hip thrust", "one leg hip thrust", "single-leg glute bridge"],
    "calf-raise":            ["barbell standing calf raise", "standing calf raise"],
    "seated-calf-raise":     ["lever seated calf raise", "seated calf raise"],

    # Glute accessories
    "curtsy-lunge":          ["dumbbell curtsy lunge", "curtsy lunge", "crossover lunge", "crossover reverse lunge"],
    "lateral-lunge":         ["dumbbell lateral lunge", "lateral lunge", "side lunge"],
    "glute-kickback":        ["cable glute kickback", "glute kickback"],
    "banded-kickback":       ["band glute kickback", "donkey kick", "banded glute kickback"],
    "kb-swing":              ["kettlebell swing", "two-arm kettlebell swing", "one-arm kettlebell swing"],

    # Upper body — push
    "bench-press":           ["barbell bench press", "barbell flat bench press"],
    "db-bench":              ["dumbbell bench press"],
    "machine-press":         ["smith machine bench press", "lever bench press", "machine bench press"],
    "ohp":                   ["barbell standing military press", "barbell overhead press", "standing military press"],
    "db-shoulder-press":     ["dumbbell seated shoulder press", "dumbbell shoulder press"],
    "machine-shoulder-press":["lever shoulder press", "machine shoulder press"],

    # Upper body — pull
    "barbell-row":           ["barbell bent over row", "bent over barbell row"],
    "chest-supported-row":   ["dumbbell chest supported row", "chest supported row", "dumbbell incline row"],
    "cable-row":             ["cable seated row", "seated cable row"],
    "lat-pulldown":          ["cable wide grip lat pulldown", "lat pulldown", "cable lat pulldown"],
    "assisted-pullup":       ["assisted pull-up", "assisted pullup", "lever assisted pull-up", "pull-up"],

    # Arms
    "db-curl":               ["dumbbell biceps curl", "dumbbell bicep curl", "dumbbell curl"],
    "cable-curl":            ["cable rope hammer curl", "cable curl"],
    "tricep-pushdown":       ["cable triceps pushdown", "cable tricep pushdown", "triceps pushdown"],
    "overhead-tri-extension":["dumbbell overhead triceps extension", "standing overhead triceps extension", "overhead triceps extension"],

    # Core / calisthenics
    "dead-bug":              ["dead bug"],
    "side-plank":            ["side plank", "side bridge"],
    "plank":                 ["front plank", "plank"],
    "pallof-press":          ["cable pallof press", "pallof press"],
    "hanging-knee-raise":    ["hanging knee raise", "hanging leg raise"],
    "lying-leg-raise":       ["lying leg raise", "flat bench lying leg raise"],
    "pushup":                ["push-up", "pushup"],
    "incline-pushup":        ["incline push-up", "incline pushup"],
    "knee-pushup":           ["kneeling push-up", "knee push-up", "push-up on knees"],
    "inverted-row":          ["inverted row", "australian pull-up"],
    "plank-to-pushup":       ["plank up-down", "plank to push-up", "push-up to plank"],
    "bench-dip":             ["bench dip", "triceps bench dip"],
    "hollow-hold":           ["hollow hold", "hollow body hold"],
    "russian-twist":         ["russian twist"],

    # Cardio / conditioning
    "treadmill-sprint":      ["treadmill running", "running treadmill", "treadmill sprint"],
    "treadmill-walk":        ["treadmill walking", "walking treadmill"],
    "bike-sprint":           ["stationary bike", "bike", "cycling"],
    "farmer-carry":          ["farmers walk", "farmer's walk", "trap bar carry"],
}

# ---------------------------------------------------------------------------
# Mapping 2 — fallback to yuhonas/free-exercise-db (start/end photos)
# Used only when ExerciseDB has no GIF match. Verified against the actual
# repo on disk; values are the case-sensitive folder names.
# ---------------------------------------------------------------------------

FREEDB_FALLBACK_MAP: dict[str, Optional[str]] = {
    "back-squat":            "Barbell_Squat",
    "goblet-squat":          "Goblet_Squat",
    "leg-press":             "Leg_Press",
    "hack-squat":            "Hack_Squat",
    "rdl":                   "Romanian_Deadlift",
    "db-rdl":                "Romanian_Deadlift",
    "cable-pull-through":    "Pull_Through",
    "bulgarian-split-squat": "Split_Squats",
    "reverse-lunge":         "Dumbbell_Rear_Lunge",
    "walking-lunge":         "Bodyweight_Walking_Lunge",
    "step-up":               "Dumbbell_Step_Ups",
    "ham-curl":              "Seated_Leg_Curl",
    "lying-ham-curl":        "Lying_Leg_Curls",
    "nordic-curl":           "Natural_Glute_Ham_Raise",
    "hip-thrust":            "Barbell_Hip_Thrust",
    "glute-bridge":          "Hip_Lift_with_Band",
    "single-leg-hip-thrust": "Single_Leg_Glute_Bridge",
    "calf-raise":            "Standing_Barbell_Calf_Raise",
    "seated-calf-raise":     "Seated_Calf_Raise",
    "curtsy-lunge":          "Crossover_Reverse_Lunge",
    "lateral-lunge":         None,
    "glute-kickback":        "Cable_Hip_Adduction",
    "banded-kickback":       "Glute_Kickback",
    "kb-swing":              "One-Arm_Kettlebell_Swings",
    "bench-press":           "Barbell_Bench_Press_-_Medium_Grip",
    "db-bench":              "Dumbbell_Bench_Press",
    "machine-press":         "Smith_Machine_Bench_Press",
    "ohp":                   "Standing_Military_Press",
    "db-shoulder-press":     "Dumbbell_Shoulder_Press",
    "machine-shoulder-press":"Machine_Shoulder_Military_Press",
    "barbell-row":           "Bent_Over_Barbell_Row",
    "chest-supported-row":   "Reverse_Grip_Bent-Over_Rows",
    "cable-row":             "Seated_Cable_Rows",
    "lat-pulldown":          "Wide-Grip_Lat_Pulldown",
    "assisted-pullup":       "Pullups",
    "db-curl":               "Dumbbell_Bicep_Curl",
    "cable-curl":            "Cable_Hammer_Curls_-_Rope_Attachment",
    "tricep-pushdown":       "Triceps_Pushdown",
    "overhead-tri-extension":"Standing_Dumbbell_Triceps_Extension",
    "dead-bug":              "Dead_Bug",
    "side-plank":            "Side_Bridge",
    "plank":                 "Plank",
    "pallof-press":          "Pallof_Press",
    "hanging-knee-raise":    "Hanging_Leg_Raise",
    "lying-leg-raise":       "Flat_Bench_Lying_Leg_Raise",
    "pushup":                "Pushups",
    "incline-pushup":        "Incline_Push-Up",
    "knee-pushup":            "Push-Ups_-_Close_Triceps_Position",
    "inverted-row":          "Inverted_Row",
    "plank-to-pushup":       "Push_Up_to_Side_Plank",
    "bench-dip":             "Bench_Dips",
    "hollow-hold":           "Body-Up",
    "russian-twist":         "Russian_Twist",
    "treadmill-sprint":      "Running_Treadmill",
    "treadmill-walk":        "Walking_Treadmill",
    "bike-sprint":           "Bicycling_Stationary",
    "farmer-carry":          "Farmers_Walk",
}

EDB_API = "https://oss.exercisedb.dev/api/v1/exercises"
FREEDB_BASE = "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises"
USER_AGENT = "varsha-fetcher/2.0"


# ---------------------------------------------------------------------------
# HTTP helpers
# ---------------------------------------------------------------------------

def http_get_json(url: str, timeout: int = 30) -> dict:
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT, "Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return json.loads(resp.read().decode("utf-8"))


def http_download(url: str, dest: Path, dry_run: bool) -> bool:
    if dest.exists():
        print(f"    ✓ exists  {dest.name}")
        return True
    if dry_run:
        print(f"    → would download  {url}")
        return True
    try:
        req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
        with urllib.request.urlopen(req, timeout=60) as resp:
            data = resp.read()
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(data)
        print(f"    ↓ downloaded  {dest.name}  ({len(data) // 1024} KB)")
        return True
    except urllib.error.HTTPError as e:
        print(f"    ✗ HTTP {e.code}  {url}", file=sys.stderr)
        return False
    except urllib.error.URLError as e:
        print(f"    ✗ Network error  {e.reason}  {url}", file=sys.stderr)
        return False


# ---------------------------------------------------------------------------
# ExerciseDB index — paginate the entire free dataset once
# ---------------------------------------------------------------------------

def fetch_edb_index(dry_run: bool) -> dict[str, dict]:
    """Returns { lowercased_name: exercise_record } across all pages."""
    if dry_run:
        print("📚 [dry-run] would fetch full ExerciseDB index")
        return {}

    print("📚 Fetching ExerciseDB index…")
    index: dict[str, dict] = {}
    cursor: Optional[str] = None
    page = 0
    while True:
        page += 1
        params = {"limit": "200"}
        if cursor:
            params["after"] = cursor
        url = f"{EDB_API}?{urllib.parse.urlencode(params)}"
        try:
            payload = http_get_json(url)
        except Exception as e:
            print(f"    ✗ failed page {page}: {e}", file=sys.stderr)
            break

        data = payload.get("data") or []
        for record in data:
            name = (record.get("name") or "").strip().lower()
            if name:
                index.setdefault(name, record)

        meta = payload.get("meta") or {}
        if not meta.get("hasNextPage"):
            break
        cursor = meta.get("nextCursor")
        if not cursor:
            break
        # Tiny politeness delay — the free tier is unmetered but be kind.
        time.sleep(0.05)

    print(f"    ✓ {len(index)} exercises indexed across {page} page(s)")
    return index


def find_edb_match(varsha_id: str, index: dict[str, dict]) -> Optional[dict]:
    """Try each candidate name; substring match against EDB names."""
    candidates = EDB_NAME_CANDIDATES.get(varsha_id, [])
    for needle in candidates:
        n = needle.lower()
        # Prefer exact first
        if n in index:
            return index[n]
        # Then substring
        for name, record in index.items():
            if n in name:
                return record
    return None


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--out", type=Path, default=Path("Varsha/Resources/ExerciseMedia"),
                        help="Output directory")
    parser.add_argument("--gifs-only", action="store_true",
                        help="Only fetch GIFs from ExerciseDB; skip free-exercise-db fallback")
    parser.add_argument("--frames-only", action="store_true",
                        help="Skip ExerciseDB; only fetch start/end photos from free-exercise-db")
    parser.add_argument("--dry-run", action="store_true",
                        help="Show what would happen without writing files")
    args = parser.parse_args()

    out_dir: Path = args.out
    if not args.dry_run:
        out_dir.mkdir(parents=True, exist_ok=True)

    edb_index: dict[str, dict] = {} if args.frames_only else fetch_edb_index(args.dry_run)

    manifest: dict[str, dict] = {}
    n_gif = n_frames = n_none = 0

    for varsha_id in EDB_NAME_CANDIDATES.keys():
        print(f"⤓ {varsha_id}")

        gif_record = None if args.frames_only else find_edb_match(varsha_id, edb_index)

        # ------- Path 1: ExerciseDB GIF -------
        if gif_record:
            gif_url = gif_record.get("gifUrl")
            edb_name = gif_record.get("name")
            if gif_url:
                dest = out_dir / f"{varsha_id}.gif"
                print(f"    EDB ← {edb_name}")
                if http_download(gif_url, dest, args.dry_run):
                    manifest[varsha_id] = {"kind": "gif", "files": [dest.name],
                                            "source": "exercisedb", "edb_name": edb_name}
                    n_gif += 1
                    continue

        if args.gifs_only:
            print("    ⊘ no EDB match (gifs-only mode)")
            manifest[varsha_id] = {"kind": "none", "files": []}
            n_none += 1
            continue

        # ------- Path 2: free-exercise-db two-frame fallback -------
        freedb_id = FREEDB_FALLBACK_MAP.get(varsha_id)
        if not freedb_id:
            print("    ⊘ no fallback mapping")
            manifest[varsha_id] = {"kind": "none", "files": []}
            n_none += 1
            continue

        print(f"    free-db ← {freedb_id}")
        files: list[str] = []
        ok = True
        for frame in (0, 1):
            url = f"{FREEDB_BASE}/{freedb_id}/{frame}.jpg"
            local = out_dir / f"{varsha_id}-{frame}.jpg"
            if http_download(url, local, args.dry_run):
                files.append(local.name)
            else:
                ok = False
        if ok and files:
            manifest[varsha_id] = {"kind": "frames", "files": files,
                                    "source": "free-exercise-db", "freedb_id": freedb_id}
            n_frames += 1
        else:
            manifest[varsha_id] = {"kind": "none", "files": []}
            n_none += 1

    # Write manifest
    if not args.dry_run:
        manifest_path = out_dir / "manifest.json"
        manifest_path.write_text(json.dumps(manifest, indent=2, sort_keys=True))
        print(f"\n📄 manifest written to {manifest_path}")

    print(f"\nDone. {n_gif} GIFs, {n_frames} frame-pairs, {n_none} unmapped.")
    print("Total:", n_gif + n_frames + n_none, "exercises processed.")

    return 0


if __name__ == "__main__":
    sys.exit(main())
