#!/usr/bin/env python3
"""TauntBuddy dataset validator.

The JSON files in `assets/data/` are a published contract: they ship inside the
app *and* are fetched at runtime from GitHub raw. This script is the single
source of truth for that schema, used both by CI (`.github/workflows/taunts.yml`)
and by anyone editing a taunt by hand:

    python3 .github/scripts/validate_taunts.py assets/data
    python3 .github/scripts/validate_taunts.py /tmp/live --require-fresh

Exit code 0 = the datasets are safe to ship.
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import sys
from pathlib import Path

TRIGGERS = {
    "onboarding",
    "morning",
    "afternoon",
    "evening",
    "night",
    "idle",
    "streak_lost",
    "goal_missed",
    "session_end",
    "break_over",
    "exam_soon",
    "kavach_break",
    "comeback",
    "milestone",
    "manual",
}

# Must stay in sync with ActivityRepository.metricValue.
BADGE_METRICS = {
    "sessions",
    "focus_minutes",
    "streak",
    "dhyan_sessions",
    "early_sessions",
    "late_sessions",
    "goals_done",
    "mood_checkins",
    "kavach_sessions",
}

ACCENTS = {"violet", "cyan", "magenta", "mint", "amber", "grey"}

# Must stay in sync with lib/data/models/exam.dart.
MILESTONE_KINDS = {
    "notification",
    "application",
    "admit",
    "exam",
    "result",
    "interview",
    "counselling",
    "training",
}

MIN_EXAMS = 20

REQUIRED_EXAM_IDS = {
    "upsc-cse",
    "bpsc",
    "ca",
    "clat-ug",
    "cuet-ug",
}

REQUIRED_TRIGGERS = {
    "morning",
    "afternoon",
    "evening",
    "night",
    "idle",
    "goal_missed",
    "streak_lost",
    "session_end",
    "break_over",
    "exam_soon",
    "kavach_break",
}

MAX_TAUNT_LENGTH = 220
ID_RE = re.compile(r"^[a-z0-9][a-z0-9._-]*$")
TIME_RE = re.compile(r"^([01]\d|2[0-3]):([0-5]\d)$")

errors: list[str] = []
warnings: list[str] = []


def fail(where: str, message: str) -> None:
    errors.append(f"{where}: {message}")


def warn(where: str, message: str) -> None:
    warnings.append(f"{where}: {message}")


def load(root: Path, name: str) -> dict | None:
    path = root / name
    if not path.exists():
        fail(name, "file is missing")
        return None
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        fail(name, f"invalid JSON ({exc})")
        return None
    if not isinstance(data, dict):
        fail(name, "top level value must be an object")
        return None
    return data


def require_schema_version(name: str, data: dict) -> None:
    version = data.get("schemaVersion")
    if version != 1:
        fail(name, f"schemaVersion must be 1, found {version!r}")


def validate_taunts(root: Path, data: dict) -> None:
    name = "taunts.json"
    require_schema_version(name, data)

    packs = data.get("packs")
    if not isinstance(packs, list) or not packs:
        fail(name, "packs must be a non-empty list")
        return

    seen_ids: set[str] = set()
    seen_triggers: set[str] = set()
    total = 0
    severities: dict[int, int] = {1: 0, 2: 0, 3: 0}

    for index, pack in enumerate(packs):
        where = f"{name}:packs[{index}]"
        if not isinstance(pack, dict):
            fail(where, "pack must be an object")
            continue
        pack_id = pack.get("id")
        if not isinstance(pack_id, str) or not ID_RE.match(pack_id):
            fail(where, f"invalid pack id {pack_id!r}")
        if not str(pack.get("title", "")).strip():
            fail(where, "pack title is required")
        if not str(pack.get("description", "")).strip():
            warn(where, "pack description is empty")

        taunts = pack.get("taunts")
        if not isinstance(taunts, list) or not taunts:
            fail(where, "pack must contain at least one taunt")
            continue

        for t_index, taunt in enumerate(taunts):
            t_where = f"{where}.taunts[{t_index}]"
            if not isinstance(taunt, dict):
                fail(t_where, "taunt must be an object")
                continue

            taunt_id = taunt.get("id")
            if not isinstance(taunt_id, str) or not ID_RE.match(taunt_id):
                fail(t_where, f"invalid taunt id {taunt_id!r}")
            elif taunt_id in seen_ids:
                fail(t_where, f"duplicate taunt id {taunt_id!r}")
            else:
                seen_ids.add(taunt_id)

            text = taunt.get("text")
            if not isinstance(text, str) or not text.strip():
                fail(t_where, "text is required")
            elif len(text) > MAX_TAUNT_LENGTH:
                fail(t_where, f"text is {len(text)} chars (max {MAX_TAUNT_LENGTH})")

            trigger = taunt.get("trigger")
            if trigger not in TRIGGERS:
                fail(t_where, f"unknown trigger {trigger!r}")
            else:
                seen_triggers.add(trigger)

            severity = taunt.get("severity")
            if not isinstance(severity, int) or isinstance(severity, bool):
                fail(t_where, f"severity must be an integer, found {severity!r}")
            elif severity not in (1, 2, 3):
                fail(t_where, f"severity must be 1-3, found {severity}")
            else:
                severities[severity] += 1

            if not str(taunt.get("category", "")).strip():
                fail(t_where, "category is required")

            tags = taunt.get("tags", [])
            if not isinstance(tags, list) or any(not isinstance(t, str) for t in tags):
                fail(t_where, "tags must be a list of strings")

            total += 1

    missing = REQUIRED_TRIGGERS - seen_triggers
    if missing:
        fail(name, f"no taunts for scheduled triggers: {sorted(missing)}")

    if total < 24:
        fail(name, f"only {total} taunts — the engine needs at least 24")

    for severity, count in severities.items():
        if count == 0:
            warn(name, f"no severity-{severity} taunts available")

    print(f"  taunts.json      {total} taunts · {len(packs)} packs · "
          f"severity mix {severities[1]}/{severities[2]}/{severities[3]}")


def validate_quotes(root: Path, data: dict) -> None:
    name = "quotes.json"
    require_schema_version(name, data)

    quotes = data.get("quotes")
    if not isinstance(quotes, list) or len(quotes) < 14:
        fail(name, "quotes must be a list with at least 14 entries")
        return

    seen: set[str] = set()
    for index, quote in enumerate(quotes):
        where = f"{name}:quotes[{index}]"
        if not isinstance(quote, dict):
            fail(where, "quote must be an object")
            continue
        text = quote.get("text")
        if not isinstance(text, str) or not text.strip():
            fail(where, "text is required")
        elif text in seen:
            warn(where, "duplicate quote text")
        else:
            seen.add(text)
        if not str(quote.get("author", "")).strip():
            fail(where, "author is required")
        if not str(quote.get("category", "")).strip():
            warn(where, "category is empty")

    print(f"  quotes.json      {len(quotes)} quotes")


def validate_catalog(root: Path, data: dict) -> None:
    name = "seed_catalog.json"
    require_schema_version(name, data)

    features = data.get("features") or []
    if len(features) < 10:
        fail(name, "at least 10 feature cards are required")
    pro = [f for f in features if isinstance(f, dict) and f.get("pro")]
    if len(pro) != 1 or pro[0].get("id") != "planner":
        fail(name, "the Exam Planner must be the only PRO feature")
    for index, feature in enumerate(features):
        where = f"{name}:features[{index}]"
        if not isinstance(feature, dict):
            fail(where, "feature must be an object")
            continue
        if not str(feature.get("title", "")).strip():
            fail(where, "title is required")
        if not str(feature.get("route", "")).startswith("/"):
            fail(where, "route must start with /")
        if feature.get("accent") not in ACCENTS:
            fail(where, f"unknown accent {feature.get('accent')!r}")

    badges = data.get("badges") or []
    if len(badges) < 10:
        fail(name, "at least 10 badges are required")
    for index, badge in enumerate(badges):
        where = f"{name}:badges[{index}]"
        if not isinstance(badge, dict):
            fail(where, "badge must be an object")
            continue
        if badge.get("metric") not in BADGE_METRICS:
            fail(where, f"unknown metric {badge.get('metric')!r}")
        threshold = badge.get("threshold")
        if not isinstance(threshold, int) or threshold <= 0:
            fail(where, f"threshold must be a positive integer, found {threshold!r}")
        if not str(badge.get("tier", "")).strip():
            fail(where, "tier is required")

    levels = data.get("levels") or []
    if len(levels) < 3:
        fail(name, "at least 3 levels are required")
    minutes = [int(lvl.get("minFocusMinutes", -1)) for lvl in levels if isinstance(lvl, dict)]
    if minutes and minutes[0] != 0:
        fail(name, "the first level must start at 0 focus minutes")
    if minutes != sorted(minutes) or len(set(minutes)) != len(minutes):
        fail(name, "level thresholds must be strictly ascending")

    courses = data.get("courses") or []
    for index, course in enumerate(courses):
        where = f"{name}:courses[{index}]"
        if not isinstance(course, dict):
            fail(where, "course must be an object")
            continue
        if int(course.get("lessons", 0)) <= 0 or int(course.get("hours", 0)) <= 0:
            fail(where, "lessons and hours must be positive")
        progress = course.get("progress")
        if not isinstance(progress, (int, float)) or not 0 <= float(progress) <= 1:
            fail(where, f"progress must be between 0 and 1, found {progress!r}")
        rating = course.get("rating")
        if not isinstance(rating, (int, float)) or not 0 <= float(rating) <= 5:
            fail(where, f"rating must be between 0 and 5, found {rating!r}")
        if course.get("accent") not in ACCENTS:
            fail(where, f"unknown accent {course.get('accent')!r}")

    for index, circle in enumerate(data.get("circles") or []):
        where = f"{name}:circles[{index}]"
        if not isinstance(circle, dict) or int(circle.get("members", 0)) <= 0:
            fail(where, "members must be positive")

    for index, entry in enumerate(data.get("leaderboard") or []):
        where = f"{name}:leaderboard[{index}]"
        if not isinstance(entry, dict) or int(entry.get("focusMinutes", 0)) <= 0:
            fail(where, "focusMinutes must be positive")

    moods = data.get("moods") or []
    if len(moods) < 4:
        fail(name, "at least 4 moods are required")
    for index, mood in enumerate(moods):
        where = f"{name}:moods[{index}]"
        if not isinstance(mood, dict) or not 1 <= int(mood.get("score", 0)) <= 5:
            fail(where, "mood score must be 1-5")

    for index, technique in enumerate(data.get("dhyan_techniques") or []):
        where = f"{name}:dhyan_techniques[{index}]"
        if not isinstance(technique, dict) or int(technique.get("minutes", 0)) <= 0:
            fail(where, "minutes must be positive")

    for index, template in enumerate(data.get("planner_templates") or []):
        where = f"{name}:planner_templates[{index}]"
        if not isinstance(template, dict):
            fail(where, "template must be an object")
            continue
        if int(template.get("daysOut", 0)) <= 0:
            fail(where, "daysOut must be positive")
        if not template.get("subjects"):
            fail(where, "template needs at least one subject")

    for index, profile in enumerate(data.get("kavach_profiles") or []):
        where = f"{name}:kavach_profiles[{index}]"
        if not isinstance(profile, dict) or not profile.get("blockedApps"):
            fail(where, "blockedApps must not be empty")

    for index, block in enumerate(data.get("timeline_blocks") or []):
        where = f"{name}:timeline_blocks[{index}]"
        if not isinstance(block, dict):
            fail(where, "block must be an object")
            continue
        start, end = block.get("start"), block.get("end")
        if not isinstance(start, str) or not TIME_RE.match(start):
            fail(where, f"start must be HH:MM, found {start!r}")
        if not isinstance(end, str) or not TIME_RE.match(end):
            fail(where, f"end must be HH:MM, found {end!r}")
        if isinstance(start, str) and isinstance(end, str) and TIME_RE.match(start) and TIME_RE.match(end):
            if end <= start:
                fail(where, f"end ({end}) must be after start ({start})")

    # An older published copy may not carry the exams block yet: that is a
    # warning (the app falls back to its bundled blueprints), while a present
    # but broken block is a hard failure.
    exams = data.get("exams")
    if exams is None:
        warn(name, "no exams block — the Exam Hub falls back to its bundled blueprints")
        exams = []
    elif not isinstance(exams, list) or not exams:
        fail(name, "the exams block must be a non-empty list of exam blueprints")
        exams = []
    elif len(exams) < MIN_EXAMS:
        fail(name, f"at least {MIN_EXAMS} exam blueprints are required, found {len(exams)}")
    seen_exams: set[str] = set()
    for index, exam in enumerate(exams):
        where = f"{name}:exams[{index}]"
        if not isinstance(exam, dict):
            fail(where, "exam must be an object")
            continue
        exam_id = exam.get("id")
        if not isinstance(exam_id, str) or not ID_RE.match(exam_id):
            fail(where, f"id must match {ID_RE.pattern}, found {exam_id!r}")
        elif exam_id in seen_exams:
            fail(where, f"duplicate exam id {exam_id!r}")
        else:
            seen_exams.add(exam_id)
        for field in ("code", "name", "body", "category", "about", "eligibility"):
            if not str(exam.get(field, "")).strip():
                fail(where, f"{field} is required")
        if exam.get("accent") not in ACCENTS:
            fail(where, f"unknown accent {exam.get('accent')!r}")
        daily = exam.get("dailyHours")
        if not isinstance(daily, (int, float)) or not 0 < float(daily) <= 16:
            fail(where, f"dailyHours must be between 0 and 16, found {daily!r}")

        stages = exam.get("stages")
        if not isinstance(stages, list) or not stages:
            fail(where, "stages (the exam pattern) must not be empty")
            stages = []
        for stage_index, stage in enumerate(stages):
            stage_where = f"{where}.stages[{stage_index}]"
            if not isinstance(stage, dict):
                fail(stage_where, "stage must be an object")
                continue
            for field in ("name", "type", "mode", "negative", "merit"):
                if not str(stage.get(field, "")).strip():
                    fail(stage_where, f"{field} is required")
            marks = stage.get("marks")
            if not isinstance(marks, (int, float)) or float(marks) < 0:
                fail(stage_where, f"marks must be a non-negative number, found {marks!r}")

        syllabus = exam.get("syllabus")
        if not isinstance(syllabus, list) or not syllabus:
            fail(where, "syllabus must not be empty")
            syllabus = []
        for paper_index, paper in enumerate(syllabus):
            paper_where = f"{where}.syllabus[{paper_index}]"
            if not isinstance(paper, dict):
                fail(paper_where, "syllabus paper must be an object")
                continue
            if not str(paper.get("subject", "")).strip():
                fail(paper_where, "subject is required")
            topics = paper.get("topics") or []
            if not isinstance(topics, list) or len(topics) < 2:
                fail(paper_where, "a syllabus paper needs at least 2 topics")
            elif len(topics) > 20:
                warn(paper_where, f"{len(topics)} topics will be clamped to 20 planner units")

        timeline = exam.get("timeline")
        if not isinstance(timeline, list) or not timeline:
            fail(where, "timeline must not be empty")
            timeline = []
        kinds: set[str] = set()
        for step_index, step in enumerate(timeline):
            step_where = f"{where}.timeline[{step_index}]"
            if not isinstance(step, dict):
                fail(step_where, "milestone must be an object")
                continue
            if not str(step.get("label", "")).strip():
                fail(step_where, "label is required")
            if not str(step.get("window", "")).strip():
                fail(step_where, "window is required")
            month = step.get("month")
            if not isinstance(month, int) or not 1 <= month <= 12:
                fail(step_where, f"month must be an integer 1-12, found {month!r}")
            kind = step.get("kind")
            if kind not in MILESTONE_KINDS:
                fail(step_where, f"unknown kind {kind!r}")
            else:
                kinds.add(kind)
        if timeline and "exam" not in kinds:
            fail(where, "timeline needs at least one 'exam' milestone")

    missing = sorted(REQUIRED_EXAM_IDS - seen_exams)
    if exams and missing:
        fail(name, f"required exam blueprints are missing: {', '.join(missing)}")

    exam_summary = f" · {len(exams)} exams" if exams else ""
    print(
        f"  seed_catalog.json {len(features)} features · {len(badges)} badges · "
        f"{len(levels)} levels · {len(courses)} courses{exam_summary}"
    )


def check_freshness(root: Path, names: list[str]) -> None:
    today = dt.date.today()
    for name in names:
        path = root / name
        if not path.exists():
            continue
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            continue
        stamp = data.get("updatedAt")
        if not isinstance(stamp, str):
            warn(name, "updatedAt is missing")
            continue
        try:
            updated = dt.date.fromisoformat(stamp[:10])
        except ValueError:
            fail(name, f"updatedAt is not an ISO date: {stamp!r}")
            continue
        if updated > today + dt.timedelta(days=1):
            fail(name, f"updatedAt ({updated}) is in the future")
        elif (today - updated).days > 120:
            warn(name, f"dataset is {(today - updated).days} days old")


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate TauntBuddy datasets")
    parser.add_argument(
        "root",
        nargs="?",
        default="assets/data",
        help="directory holding taunts.json / quotes.json / seed_catalog.json",
    )
    parser.add_argument(
        "--require-fresh",
        action="store_true",
        help="treat a stale/missing updatedAt as fatal (used for the published copy)",
    )
    args = parser.parse_args()

    root = Path(args.root)
    if not root.is_dir():
        print(f"✖ {root} is not a directory", file=sys.stderr)
        return 2

    print(f"Validating TauntBuddy datasets in {root}")

    taunts = load(root, "taunts.json")
    if taunts:
        validate_taunts(root, taunts)

    quotes = load(root, "quotes.json")
    if quotes:
        validate_quotes(root, quotes)

    catalog = load(root, "seed_catalog.json")
    if catalog:
        validate_catalog(root, catalog)

    check_freshness(root, ["taunts.json", "quotes.json", "seed_catalog.json"])

    for message in warnings:
        print(f"  ! warning: {message}")

    if errors:
        print("\n✖ dataset validation failed:", file=sys.stderr)
        for message in errors:
            print(f"  - {message}", file=sys.stderr)
        return 1

    print("✓ all datasets valid")
    if args.require_fresh and warnings:
        # A stale dataset is survivable but should be refreshed deliberately.
        print("✓ freshness check passed with warnings")
    return 0


if __name__ == "__main__":
    sys.exit(main())
