#!/usr/bin/env python3
"""Core eval runner for the auto-skill-improvement system.

Evaluates skill quality by running scenarios with and without the skill loaded,
then scoring responses with LLM-as-judge. Uses claude CLI for API access.

Usage:
    # Run baseline for a specific skill
    python eval.py --baseline --skills-dir ./plugins/pokayokay/skills --skill api-design

    # Run baseline for all skills that have eval.json
    python eval.py --baseline --skills-dir ./plugins/pokayokay/skills

    # Evaluate current skill quality (with skill loaded)
    python eval.py --skills-dir ./plugins/pokayokay/skills --skill api-design

    # Evaluate and compare with/without
    python eval.py --compare --skills-dir ./plugins/pokayokay/skills --skill planning
"""

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

from judge import claude_cli, judge_response
from structural import check_skill_structure


def load_skill_content(skill_dir: Path) -> str:
    """Load SKILL.md and concatenate referenced content."""
    skill_md = skill_dir / "SKILL.md"
    if not skill_md.exists():
        return ""

    content = skill_md.read_text()

    refs_dir = skill_dir / "references"
    if refs_dir.exists():
        for ref_file in sorted(refs_dir.glob("*.md")):
            content += f"\n\n--- Reference: {ref_file.name} ---\n\n"
            content += ref_file.read_text()

    return content


def load_eval_config(skill_dir: Path) -> Optional[dict]:
    """Load eval.json from a skill directory."""
    eval_json = skill_dir / "eval.json"
    if not eval_json.exists():
        return None
    return json.loads(eval_json.read_text())


def generate_response(
    user_input: str,
    system_context: str = "",
    skill_content: str = "",
    model: str = "haiku",
) -> str:
    """Generate a response with optional skill content via claude CLI."""
    system_parts = []
    if skill_content:
        system_parts.append(f"You have the following skill loaded:\n\n{skill_content}")
    if system_context:
        system_parts.append(system_context)
    if not system_parts:
        system_parts.append("You are a helpful AI assistant.")

    system = "\n\n".join(system_parts)
    return claude_cli(user_input, system, model)


def eval_scenario(
    scenario: dict,
    skill_content: str,
    eval_model: str,
    judge_model: str,
    with_skill: bool = True,
) -> dict:
    """Evaluate a single scenario."""
    content = skill_content if with_skill else ""

    response_text = generate_response(
        user_input=scenario["input"],
        system_context=scenario.get("system_context", ""),
        skill_content=content,
        model=eval_model,
    )

    judgment = judge_response(
        response_text=response_text,
        criteria=scenario["eval_criteria"],
        anti_slop_checks=scenario.get("anti_slop_checks", []),
        model=judge_model,
    )

    return {
        "scenario_id": scenario["id"],
        "scenario_name": scenario["name"],
        "with_skill": with_skill,
        "response_text": response_text[:500],
        "criteria_weighted_score": judgment["criteria_weighted_score"],
        "anti_slop_score": judgment["anti_slop_score"],
        "criteria_details": judgment["criteria_scores"],
        "anti_slop_details": judgment["anti_slop_scores"],
        "error": judgment.get("error"),
    }


def compute_composite_score(
    scenario_results: list[dict],
    structural_result: dict,
    weights: dict,
) -> float:
    """Compute weighted composite score from scenario and structural results."""
    if not scenario_results:
        return 0.0

    scenario_scores = [r["criteria_weighted_score"] for r in scenario_results]
    scenario_pass_rate = sum(scenario_scores) / len(scenario_scores)

    anti_slop_scores = [r["anti_slop_score"] for r in scenario_results]
    anti_slop_rate = sum(anti_slop_scores) / len(anti_slop_scores)

    structural_score = structural_result.get("score", 0.0)

    # LLM quality proxy: average of scenario + anti-slop
    llm_quality = (scenario_pass_rate + anti_slop_rate) / 2

    composite = (
        weights.get("scenario_pass_rate", 0.5) * scenario_pass_rate
        + weights.get("anti_slop_rate", 0.2) * anti_slop_rate
        + weights.get("structural_compliance", 0.15) * structural_score
        + weights.get("llm_quality_score", 0.15) * llm_quality
    )

    return round(composite, 4)


def eval_skill(
    skill_dir: Path,
    baseline: bool = False,
    compare: bool = False,
    verbose: bool = False,
    max_scenarios: Optional[int] = None,
) -> dict:
    """Run full evaluation for a skill.

    Args:
        skill_dir: Path to skill directory
        baseline: If True, run without skill loaded
        compare: If True, run both with and without skill
        verbose: Print detailed output
        max_scenarios: Limit number of scenarios (for quick tests)

    Returns:
        Full evaluation result dict
    """
    config = load_eval_config(skill_dir)
    if not config:
        return {"error": f"No eval.json found in {skill_dir}"}

    skill_name = config["skill"]
    eval_model = config.get("eval_model", "haiku")
    judge_model = config.get("judge_model", eval_model)
    scenarios = config.get("scenarios", [])
    scoring_weights = config.get("scoring", {}).get("weights", {})
    structural_checks = config.get("structural_checks", {})

    # Map full model IDs to aliases for claude CLI
    model_aliases = {
        "claude-haiku-4-5-20251001": "haiku",
        "claude-sonnet-4-6": "sonnet",
        "claude-opus-4-6": "opus",
    }
    eval_model = model_aliases.get(eval_model, eval_model)
    judge_model = model_aliases.get(judge_model, judge_model)

    if max_scenarios:
        scenarios = scenarios[:max_scenarios]

    if verbose:
        print(f"\nEvaluating skill: {skill_name}")
        print(f"  Scenarios: {len(scenarios)}")
        print(f"  Model: {eval_model}")
        print(f"  Mode: {'baseline' if baseline else 'compare' if compare else 'with_skill'}")

    skill_content = load_skill_content(skill_dir)
    structural_result = check_skill_structure(skill_dir, structural_checks)

    if verbose:
        print(f"  Structural: {structural_result['passed']}/{structural_result['total']}")

    results_with = []
    results_without = []

    for i, scenario in enumerate(scenarios):
        if verbose:
            print(f"  [{i+1}/{len(scenarios)}] {scenario['name']}...", end=" ", flush=True)

        if not baseline:
            result_with = eval_scenario(
                scenario, skill_content, eval_model, judge_model, with_skill=True
            )
            results_with.append(result_with)

        if baseline or compare:
            result_without = eval_scenario(
                scenario, skill_content, eval_model, judge_model, with_skill=False
            )
            results_without.append(result_without)

        if verbose:
            if results_with:
                print(f"with={results_with[-1]['criteria_weighted_score']:.2f}", end=" ")
            if results_without:
                print(f"without={results_without[-1]['criteria_weighted_score']:.2f}", end="")
            print()

    # Compute composite scores
    composite_with = None
    composite_without = None

    if results_with:
        composite_with = compute_composite_score(results_with, structural_result, scoring_weights)
    if results_without:
        composite_without = compute_composite_score(results_without, structural_result, scoring_weights)

    result = {
        "skill": skill_name,
        "skill_dir": str(skill_dir),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "eval_model": eval_model,
        "judge_model": judge_model,
        "mode": "baseline" if baseline else "compare" if compare else "with_skill",
        "structural": structural_result,
        "composite_with_skill": composite_with,
        "composite_without_skill": composite_without,
        "delta": round(composite_with - composite_without, 4) if composite_with is not None and composite_without is not None else None,
        "scenarios_with_skill": results_with,
        "scenarios_without_skill": results_without,
    }

    if verbose:
        print(f"\n  Results for {skill_name}:")
        if composite_with is not None:
            print(f"    With skill:    {composite_with:.4f}")
        if composite_without is not None:
            print(f"    Without skill: {composite_without:.4f}")
        if result["delta"] is not None:
            print(f"    Delta:         {result['delta']:+.4f}")
        print(f"    Structural:    {structural_result['passed']}/{structural_result['total']}")

    return result


def update_eval_log(skill_dir: Path, result: dict, entry_type: str = "Baseline"):
    """Append an entry to the skill's eval-log.md."""
    log_path = skill_dir / "eval-log.md"

    if not log_path.exists():
        log_path.write_text(f"# {result['skill']} Eval Log\n\n")

    timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")

    lines = [f"\n## {entry_type} ({timestamp})\n"]
    lines.append(f"- Model: {result['eval_model']}")

    if result["composite_with_skill"] is not None:
        lines.append(f"- Composite (with skill): {result['composite_with_skill']:.4f}")
    if result["composite_without_skill"] is not None:
        lines.append(f"- Composite (without skill): {result['composite_without_skill']:.4f}")
    if result["delta"] is not None:
        lines.append(f"- Delta: {result['delta']:+.4f}")

    lines.append(f"- Structural: {result['structural']['passed']}/{result['structural']['total']}")

    scenarios = result.get("scenarios_with_skill") or result.get("scenarios_without_skill") or []
    if scenarios:
        lines.append("- Scenarios:")
        for s in scenarios:
            lines.append(f"  - {s['scenario_name']}: criteria={s['criteria_weighted_score']:.2f}, anti_slop={s['anti_slop_score']:.2f}")

    lines.append("")

    with open(log_path, "a") as f:
        f.write("\n".join(lines))


def update_baseline_scores(skill_dir: Path, results_without: list[dict]):
    """Update baseline_score in eval.json from baseline results."""
    eval_json_path = skill_dir / "eval.json"
    config = json.loads(eval_json_path.read_text())

    for result in results_without:
        for scenario in config["scenarios"]:
            if scenario["id"] == result["scenario_id"]:
                scenario["baseline_score"] = round(result["criteria_weighted_score"], 4)
                break

    eval_json_path.write_text(json.dumps(config, indent=2) + "\n")


def find_skills_with_evals(skills_dir: Path) -> list[Path]:
    """Find all skill directories that have eval.json."""
    skills = []
    for skill_dir in sorted(skills_dir.iterdir()):
        if skill_dir.is_dir() and (skill_dir / "eval.json").exists():
            skills.append(skill_dir)
    return skills


def main():
    parser = argparse.ArgumentParser(description="Evaluate skill quality")
    parser.add_argument("--skills-dir", required=True, help="Path to skills directory")
    parser.add_argument("--skill", help="Specific skill to evaluate (default: all with eval.json)")
    parser.add_argument("--baseline", action="store_true", help="Run without skill loaded")
    parser.add_argument("--compare", action="store_true", help="Run both with and without skill")
    parser.add_argument("--max-scenarios", type=int, help="Limit scenarios per skill (for quick tests)")
    parser.add_argument("--verbose", "-v", action="store_true", help="Verbose output")
    parser.add_argument("--output", "-o", help="Write results JSON to file")

    args = parser.parse_args()

    skills_dir = Path(args.skills_dir).resolve()
    if not skills_dir.exists():
        print(f"Error: skills directory not found: {skills_dir}", file=sys.stderr)
        sys.exit(1)

    if args.skill:
        skill_dirs = [skills_dir / args.skill]
        if not skill_dirs[0].exists():
            print(f"Error: skill not found: {skill_dirs[0]}", file=sys.stderr)
            sys.exit(1)
    else:
        skill_dirs = find_skills_with_evals(skills_dir)
        if not skill_dirs:
            print(f"No skills with eval.json found in {skills_dir}", file=sys.stderr)
            sys.exit(1)

    all_results = []
    for skill_dir in skill_dirs:
        result = eval_skill(
            skill_dir=skill_dir,
            baseline=args.baseline,
            compare=args.compare,
            verbose=args.verbose,
            max_scenarios=args.max_scenarios,
        )
        all_results.append(result)

        # Update eval-log.md
        entry_type = "Baseline" if args.baseline else "Compare" if args.compare else "Evaluation"
        update_eval_log(skill_dir, result, entry_type)

        # Update baseline scores in eval.json if running baseline
        if args.baseline and result.get("scenarios_without_skill"):
            update_baseline_scores(skill_dir, result["scenarios_without_skill"])

    # Print summary
    print("\n" + "=" * 60)
    print("EVALUATION SUMMARY")
    print("=" * 60)
    for r in all_results:
        if "error" in r:
            print(f"  {r.get('skill', '?')}: ERROR - {r['error']}")
            continue
        line = f"  {r['skill']:20s}"
        if r["composite_with_skill"] is not None:
            line += f"  with={r['composite_with_skill']:.4f}"
        if r["composite_without_skill"] is not None:
            line += f"  without={r['composite_without_skill']:.4f}"
        if r["delta"] is not None:
            line += f"  delta={r['delta']:+.4f}"
        print(line)

    if args.output:
        output_path = Path(args.output)
        output_path.write_text(json.dumps(all_results, indent=2, default=str) + "\n")
        print(f"\n  Results written to: {output_path}")


if __name__ == "__main__":
    main()
