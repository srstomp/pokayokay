#!/usr/bin/env python3
"""Loop runner for autonomous skill improvement.

Orchestrates the autoresearch-style improvement loop:
1. Select next skill (scheduler)
2. Read skill's eval.json + eval-log.md
3. Generate hypothesis (via Claude Code headless or manual)
4. Run eval suite
5. Keep/discard based on score delta
6. Log results, update dashboard
7. Loop

Usage:
    # Evaluate all pilot skills (no modifications)
    python runner.py --skills-dir ./plugins/pokayokay/skills --eval-only

    # Run improvement loop (requires Claude Code headless for hypothesis generation)
    python runner.py --skills-dir ./plugins/pokayokay/skills --iterations 50 --strategy adaptive

    # Target specific skill
    python runner.py --skills-dir ./plugins/pokayokay/skills --skill api-design --iterations 20

    # Budget-constrained run
    python runner.py --skills-dir ./plugins/pokayokay/skills --iterations 100 --budget-usd 15.0
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

from eval import eval_skill, find_skills_with_evals, load_eval_config, update_eval_log


DASHBOARD_FILE = "dashboard.json"
PATTERNS_FILE = "patterns.json"


def load_dashboard(auto_improve_dir: Path) -> dict:
    """Load or initialize the portfolio dashboard."""
    path = auto_improve_dir / DASHBOARD_FILE
    if path.exists():
        return json.loads(path.read_text())
    return {
        "last_updated": None,
        "skills": {},
        "portfolio_avg": 0.0,
        "total_experiments": 0,
        "total_kept": 0,
        "keep_rate": 0.0,
        "cost_total_usd": 0.0,
    }


def save_dashboard(auto_improve_dir: Path, dashboard: dict):
    """Save the portfolio dashboard."""
    dashboard["last_updated"] = datetime.now(timezone.utc).isoformat()
    path = auto_improve_dir / DASHBOARD_FILE
    path.write_text(json.dumps(dashboard, indent=2) + "\n")


def load_patterns(auto_improve_dir: Path) -> dict:
    """Load or initialize the cross-skill patterns log."""
    path = auto_improve_dir / PATTERNS_FILE
    if path.exists():
        return json.loads(path.read_text())
    return {"patterns": []}


def save_patterns(auto_improve_dir: Path, patterns: dict):
    """Save the cross-skill patterns log."""
    path = auto_improve_dir / PATTERNS_FILE
    path.write_text(json.dumps(patterns, indent=2) + "\n")


def update_dashboard_for_skill(dashboard: dict, skill_name: str, result: dict, kept: bool):
    """Update dashboard with a new experiment result."""
    if skill_name not in dashboard["skills"]:
        dashboard["skills"][skill_name] = {
            "score": 0.0,
            "experiments": 0,
            "kept": 0,
            "trend": "new",
            "last_experiment": None,
        }

    entry = dashboard["skills"][skill_name]
    entry["experiments"] += 1
    entry["last_experiment"] = datetime.now(timezone.utc).isoformat()

    if kept:
        entry["kept"] += 1
        score = result.get("composite_with_skill", 0.0)
        if score is not None:
            entry["score"] = score

    # Detect trend
    if entry["experiments"] >= 10:
        recent_keep_rate = entry["kept"] / entry["experiments"]
        if recent_keep_rate < 0.05:
            entry["trend"] = "plateau"
        elif recent_keep_rate > 0.3:
            entry["trend"] = "improving"
        else:
            entry["trend"] = "slow"
    elif entry["experiments"] >= 3:
        entry["trend"] = "warming_up"

    dashboard["total_experiments"] += 1
    if kept:
        dashboard["total_kept"] += 1
    dashboard["keep_rate"] = (
        dashboard["total_kept"] / dashboard["total_experiments"]
        if dashboard["total_experiments"] > 0
        else 0.0
    )
    dashboard["cost_total_usd"] += result.get("cost_usd", 0.0)

    # Recalculate portfolio average
    scores = [s["score"] for s in dashboard["skills"].values() if s["score"] > 0]
    dashboard["portfolio_avg"] = sum(scores) / len(scores) if scores else 0.0


def select_next_skill(
    dashboard: dict,
    available_skills: list[str],
    strategy: str = "adaptive",
    focus_skills: list[str] | None = None,
) -> str | None:
    """Select the next skill to work on.

    Strategies:
    - adaptive: lowest score first, skip plateaus
    - breadth: round-robin
    - deep: stay on same skill until plateau
    """
    candidates = focus_skills if focus_skills else available_skills

    if not candidates:
        return None

    if strategy == "breadth":
        # Pick the skill with fewest experiments (round-robin effect)
        def sort_key(name):
            entry = dashboard["skills"].get(name, {})
            return entry.get("experiments", 0)
        return min(candidates, key=sort_key)

    # adaptive and deep: filter out plateaus (unless everything is plateau)
    non_plateau = [
        s for s in candidates
        if dashboard["skills"].get(s, {}).get("trend") != "plateau"
    ]
    pool = non_plateau if non_plateau else candidates

    if strategy == "deep":
        # If there's a skill currently being worked on (in_progress), continue with it
        # Otherwise pick lowest score
        pass

    # Default (adaptive): lowest score first, break ties by staleness
    def sort_key(name):
        entry = dashboard["skills"].get(name, {})
        score = entry.get("score", 0.0)
        last = entry.get("last_experiment", "")
        # Lower score = higher priority, older = higher priority
        return (score, last)

    return min(pool, key=sort_key)


def git_commit_skill(skill_dir: Path, message: str) -> str | None:
    """Commit changes in the skill directory and return the commit hash."""
    try:
        # Stage skill files
        subprocess.run(
            ["git", "add", str(skill_dir)],
            capture_output=True, check=True,
        )
        # Check if there are staged changes
        result = subprocess.run(
            ["git", "diff", "--cached", "--quiet"],
            capture_output=True,
        )
        if result.returncode == 0:
            return None  # No changes to commit

        result = subprocess.run(
            ["git", "commit", "-m", message],
            capture_output=True, check=True, text=True,
        )
        # Extract commit hash
        hash_result = subprocess.run(
            ["git", "rev-parse", "--short", "HEAD"],
            capture_output=True, check=True, text=True,
        )
        return hash_result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"  Git error: {e.stderr}", file=sys.stderr)
        return None


def git_revert_skill(skill_dir: Path):
    """Revert uncommitted changes in the skill directory."""
    try:
        subprocess.run(
            ["git", "checkout", "--", str(skill_dir)],
            capture_output=True, check=True,
        )
    except subprocess.CalledProcessError as e:
        print(f"  Git revert error: {e.stderr}", file=sys.stderr)


def run_eval_only(
    skills_dir: Path,
    auto_improve_dir: Path,
    skill_names: Optional[list] = None,
    compare: bool = False,
    verbose: bool = False,
    max_scenarios: Optional[int] = None,
):
    """Run evaluation without modifications. Updates dashboard and eval-logs."""
    skill_dirs = find_skills_with_evals(skills_dir)
    if skill_names:
        skill_dirs = [d for d in skill_dirs if d.name in skill_names]

    dashboard = load_dashboard(auto_improve_dir)

    for skill_dir in skill_dirs:
        result = eval_skill(
            skill_dir=skill_dir,
            baseline=False,
            compare=compare,
            verbose=verbose,
            max_scenarios=max_scenarios,
        )

        if "error" not in result:
            skill_name = result["skill"]
            if skill_name not in dashboard["skills"]:
                dashboard["skills"][skill_name] = {
                    "score": result.get("composite_with_skill", 0.0),
                    "experiments": 0,
                    "kept": 0,
                    "trend": "new",
                    "last_experiment": datetime.now(timezone.utc).isoformat(),
                }
            else:
                dashboard["skills"][skill_name]["score"] = result.get("composite_with_skill", 0.0)
                dashboard["skills"][skill_name]["last_experiment"] = datetime.now(timezone.utc).isoformat()

    # Recalculate portfolio average
    scores = [s["score"] for s in dashboard["skills"].values() if s["score"] > 0]
    dashboard["portfolio_avg"] = sum(scores) / len(scores) if scores else 0.0

    save_dashboard(auto_improve_dir, dashboard)
    print(f"\nDashboard updated: {auto_improve_dir / DASHBOARD_FILE}")


def print_dashboard(auto_improve_dir: Path):
    """Print a human-readable portfolio summary."""
    dashboard = load_dashboard(auto_improve_dir)

    print("\n" + "=" * 70)
    print("SKILL PORTFOLIO DASHBOARD")
    print("=" * 70)

    if not dashboard["skills"]:
        print("  No skills evaluated yet. Run with --eval-only first.")
        return

    # Sort by score ascending
    sorted_skills = sorted(
        dashboard["skills"].items(),
        key=lambda x: x[1].get("score", 0),
    )

    print(f"  {'Skill':25s} {'Score':>8s} {'Experiments':>12s} {'Kept':>6s} {'Trend':>12s}")
    print("  " + "-" * 65)

    for name, entry in sorted_skills:
        score = entry.get("score", 0.0)
        experiments = entry.get("experiments", 0)
        kept = entry.get("kept", 0)
        trend = entry.get("trend", "new")
        print(f"  {name:25s} {score:8.4f} {experiments:12d} {kept:6d} {trend:>12s}")

    print("  " + "-" * 65)
    print(f"  {'Portfolio Average':25s} {dashboard['portfolio_avg']:8.4f}")
    print(f"  Total experiments: {dashboard['total_experiments']}")
    print(f"  Keep rate: {dashboard['keep_rate']:.1%}")
    print(f"  Total cost: ${dashboard['cost_total_usd']:.2f}")
    print(f"  Last updated: {dashboard.get('last_updated', 'never')}")


def main():
    parser = argparse.ArgumentParser(description="Auto-skill improvement runner")
    parser.add_argument("--skills-dir", required=True, help="Path to skills directory")
    parser.add_argument("--skill", help="Target specific skill")
    parser.add_argument("--iterations", type=int, default=10, help="Number of improvement iterations")
    parser.add_argument("--strategy", choices=["adaptive", "breadth", "deep"], default="adaptive")
    parser.add_argument("--budget-usd", type=float, default=15.0, help="Maximum spend in USD")
    parser.add_argument("--eval-only", action="store_true", help="Only evaluate, don't modify skills")
    parser.add_argument("--compare", action="store_true", help="Run with/without comparison")
    parser.add_argument("--max-scenarios", type=int, help="Limit scenarios per skill (for quick tests)")
    parser.add_argument("--dashboard", action="store_true", help="Print portfolio dashboard")
    parser.add_argument("--verbose", "-v", action="store_true")

    args = parser.parse_args()

    skills_dir = Path(args.skills_dir).resolve()
    auto_improve_dir = Path(__file__).parent.resolve()

    if args.dashboard:
        print_dashboard(auto_improve_dir)
        return

    if args.eval_only:
        skill_names = [args.skill] if args.skill else None
        run_eval_only(skills_dir, auto_improve_dir, skill_names, args.compare, args.verbose, args.max_scenarios)
        return

    # Improvement loop
    dashboard = load_dashboard(auto_improve_dir)
    skill_dirs = find_skills_with_evals(skills_dir)
    available_skills = [d.name for d in skill_dirs]
    focus_skills = [args.skill] if args.skill else None

    print(f"\nStarting improvement loop")
    print(f"  Strategy: {args.strategy}")
    print(f"  Iterations: {args.iterations}")
    print(f"  Budget: ${args.budget_usd:.2f}")
    print(f"  Skills: {', '.join(focus_skills or available_skills)}")

    for iteration in range(1, args.iterations + 1):
        skill_name = select_next_skill(dashboard, available_skills, args.strategy, focus_skills)
        if not skill_name:
            print("\n  No skills available to improve.")
            break

        skill_dir = skills_dir / skill_name
        print(f"\n  [{iteration}/{args.iterations}] Evaluating {skill_name}...")

        result = eval_skill(
            skill_dir=skill_dir,
            baseline=False,
            compare=False,
            verbose=args.verbose,
            max_scenarios=args.max_scenarios,
        )

        if "error" in result:
            print(f"    Error: {result['error']}")
            continue

        cost = result.get("cost_usd", 0.0)
        total_cost += cost
        score = result.get("composite_with_skill", 0.0)

        # In eval-only mode (no external editor), just track scores
        # The actual hypothesis → edit → eval → keep/discard loop
        # requires Claude Code headless as the "improver brain"
        print(f"    Score: {score:.4f}, Cost: ${cost:.4f}, Total: ${total_cost:.2f}")

        # Update dashboard
        update_dashboard_for_skill(dashboard, skill_name, result, kept=False)
        update_eval_log(skill_dir, result, f"Iteration {iteration}")

    save_dashboard(auto_improve_dir, dashboard)
    print(f"\nDashboard saved. Total cost: ${total_cost:.2f}")
    print_dashboard(auto_improve_dir)


if __name__ == "__main__":
    main()
