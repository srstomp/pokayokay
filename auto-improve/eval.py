#!/usr/bin/env python3
"""Core eval runner for the auto-improve system.

Evaluates skill and agent quality by running scenarios with and without the
component loaded, then scoring responses with LLM-as-judge. Uses claude CLI
for API access.

Usage:
    # Evaluate a whole plugin (auto-discovers skills + agents)
    python eval.py --plugin-dir ./plugins/design -v

    # Evaluate skills
    python eval.py --skills-dir ./plugins/pokayokay/skills --skill api-design

    # Evaluate agents
    python eval.py --agents-dir ./plugins/pokayokay/agents --agent yokay-spec-reviewer

    # Evaluate both explicitly
    python eval.py --skills-dir ./plugins/pokayokay/skills --agents-dir ./plugins/pokayokay/agents -v
"""

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

from judge import claude_cli, judge_response
from structural import check_skill_structure, check_agent_structure


# --- Loading ---


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


def _resolve_agent_file(agents_dir: Path, agent_name: str) -> Optional[Path]:
    """Find the agent markdown file, supporting both layout styles.

    pokayokay style: agents/<name>.md  (flat files)
    toyoda style:    agents/<name>/AGENT.md  (subdirectories)
    """
    # Flat file first (pokayokay)
    flat = agents_dir / f"{agent_name}.md"
    if flat.exists():
        return flat
    # Subdirectory (toyoda)
    subdir = agents_dir / agent_name / "AGENT.md"
    if subdir.exists():
        return subdir
    return None


def load_agent_content(agents_dir: Path, agent_name: str) -> str:
    """Load agent markdown content (the full system prompt)."""
    agent_path = _resolve_agent_file(agents_dir, agent_name)
    if not agent_path:
        return ""
    return agent_path.read_text()


def load_eval_config(skill_dir: Path) -> Optional[dict]:
    """Load eval.json from a skill directory."""
    eval_json = skill_dir / "eval.json"
    if not eval_json.exists():
        return None
    return json.loads(eval_json.read_text())


def load_agent_eval_config(agents_dir: Path, agent_name: str) -> Optional[dict]:
    """Load eval config for an agent. Checks both layout styles.

    pokayokay style: agents/eval/<name>.json
    toyoda style:    agents/<name>/eval.json
    """
    # pokayokay style
    flat_eval = agents_dir / "eval" / f"{agent_name}.json"
    if flat_eval.exists():
        return json.loads(flat_eval.read_text())
    # toyoda style
    subdir_eval = agents_dir / agent_name / "eval.json"
    if subdir_eval.exists():
        return json.loads(subdir_eval.read_text())
    return None


def _agent_eval_log_path(agents_dir: Path, agent_name: str) -> Path:
    """Return the eval log path for an agent, matching its layout style."""
    # If subdir agent exists, log goes there
    if (agents_dir / agent_name / "AGENT.md").exists():
        return agents_dir / agent_name / "eval-log.md"
    # Otherwise pokayokay style
    return agents_dir / "eval" / f"{agent_name}.eval-log.md"


def find_agents_with_evals(agents_dir: Path) -> list[str]:
    """Find all agents that have eval configs.

    Checks both layout styles:
    - pokayokay: agents/eval/<name>.json  (with agents/<name>.md)
    - toyoda:    agents/<name>/eval.json  (with agents/<name>/AGENT.md)
    """
    agents = []

    # pokayokay style: eval/<name>.json
    eval_dir = agents_dir / "eval"
    if eval_dir.exists():
        for eval_file in sorted(eval_dir.glob("*.json")):
            name = eval_file.stem
            if (agents_dir / f"{name}.md").exists():
                agents.append(name)

    # toyoda style: <name>/eval.json
    for subdir in sorted(agents_dir.iterdir()):
        if subdir.is_dir() and subdir.name != "eval" and subdir.name != "templates":
            if (subdir / "eval.json").exists() and (subdir / "AGENT.md").exists():
                if subdir.name not in agents:  # avoid duplicates
                    agents.append(subdir.name)

    return agents


def discover_plugin(plugin_dir: Path) -> tuple[Optional[Path], Optional[Path]]:
    """Auto-discover skills and agents directories within a plugin.

    Returns (skills_dir, agents_dir) — either may be None.
    """
    skills_dir = plugin_dir / "skills"
    agents_dir = plugin_dir / "agents"
    return (
        skills_dir if skills_dir.is_dir() else None,
        agents_dir if agents_dir.is_dir() else None,
    )


# --- Response generation ---


def generate_response(
    user_input: str,
    system_context: str = "",
    skill_content: str = "",
    component_type: str = "skill",
    model: str = "haiku",
) -> str:
    """Generate a response with optional component content via claude CLI.

    For skills: content is injected into system prompt as context.
    For agents: content IS the system prompt (it's the agent's instructions).
    """
    if component_type == "agent" and skill_content:
        # Agent content is the full system prompt
        system = skill_content
        if system_context:
            system += f"\n\n{system_context}"
        return claude_cli(user_input, system, model)

    # Skill mode (original behavior)
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
    component_type: str = "skill",
) -> dict:
    """Evaluate a single scenario."""
    content = skill_content if with_skill else ""

    response_text = generate_response(
        user_input=scenario["input"],
        system_context=scenario.get("system_context", ""),
        skill_content=content,
        component_type=component_type,
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
    """Run full evaluation for a skill. Delegates to _eval_component."""
    config = load_eval_config(skill_dir)
    if not config:
        return {"error": f"No eval.json found in {skill_dir}"}

    content = load_skill_content(skill_dir)
    structural_result = check_skill_structure(skill_dir, config.get("structural_checks", {}))

    return _eval_component(
        config=config,
        content=content,
        structural_result=structural_result,
        component_type="skill",
        component_path=str(skill_dir),
        baseline=baseline,
        compare=compare,
        verbose=verbose,
        max_scenarios=max_scenarios,
    )


def eval_agent(
    agents_dir: Path,
    agent_name: str,
    baseline: bool = False,
    compare: bool = False,
    verbose: bool = False,
    max_scenarios: Optional[int] = None,
) -> dict:
    """Run full evaluation for an agent."""
    config = load_agent_eval_config(agents_dir, agent_name)
    if not config:
        return {"error": f"No eval config found for agent {agent_name}"}

    content = load_agent_content(agents_dir, agent_name)
    if not content:
        return {"error": f"Agent file not found: {agent_name} in {agents_dir}"}

    agent_path = _resolve_agent_file(agents_dir, agent_name)
    structural_result = check_agent_structure(agent_path, config.get("structural_checks", {}))

    return _eval_component(
        config=config,
        content=content,
        structural_result=structural_result,
        component_type="agent",
        component_path=str(agent_path),
        baseline=baseline,
        compare=compare,
        verbose=verbose,
        max_scenarios=max_scenarios,
    )


def _eval_component(
    config: dict,
    content: str,
    structural_result: dict,
    component_type: str,
    component_path: str,
    baseline: bool = False,
    compare: bool = False,
    verbose: bool = False,
    max_scenarios: Optional[int] = None,
) -> dict:
    """Shared eval logic for skills and agents."""
    component_name = config.get("agent", config.get("skill", "unknown"))
    eval_model = config.get("eval_model", "haiku")
    judge_model = config.get("judge_model", eval_model)
    scenarios = config.get("scenarios", [])
    scoring_weights = config.get("scoring", {}).get("weights", {})

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
        label = "agent" if component_type == "agent" else "skill"
        print(f"\nEvaluating {label}: {component_name}")
        print(f"  Scenarios: {len(scenarios)}")
        print(f"  Model: {eval_model}")
        print(f"  Mode: {'baseline' if baseline else 'compare' if compare else 'with_component'}")
        print(f"  Structural: {structural_result['passed']}/{structural_result['total']}")

    results_with = []
    results_without = []

    for i, scenario in enumerate(scenarios):
        if verbose:
            print(f"  [{i+1}/{len(scenarios)}] {scenario['name']}...", end=" ", flush=True)

        if not baseline:
            result_with = eval_scenario(
                scenario, content, eval_model, judge_model,
                with_skill=True, component_type=component_type,
            )
            results_with.append(result_with)

        if baseline or compare:
            result_without = eval_scenario(
                scenario, content, eval_model, judge_model,
                with_skill=False, component_type=component_type,
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
        "skill": component_name,
        "type": component_type,
        "skill_dir": component_path,
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
        print(f"\n  Results for {component_name}:")
        if composite_with is not None:
            print(f"    With {component_type}:    {composite_with:.4f}")
        if composite_without is not None:
            print(f"    Without {component_type}: {composite_without:.4f}")
        if result["delta"] is not None:
            print(f"    Delta:         {result['delta']:+.4f}")
        print(f"    Structural:    {structural_result['passed']}/{structural_result['total']}")

    return result


def _append_eval_log(log_path: Path, result: dict, entry_type: str = "Baseline"):
    """Append an eval log entry to any path."""
    component_name = result.get("skill", "unknown")
    component_type = result.get("type", "skill")

    if not log_path.exists():
        log_path.parent.mkdir(parents=True, exist_ok=True)
        log_path.write_text(f"# {component_name} Eval Log\n\n")

    timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    label = component_type

    lines = [f"\n## {entry_type} ({timestamp})\n"]
    lines.append(f"- Model: {result['eval_model']}")

    if result["composite_with_skill"] is not None:
        lines.append(f"- Composite (with {label}): {result['composite_with_skill']:.4f}")
    if result["composite_without_skill"] is not None:
        lines.append(f"- Composite (without {label}): {result['composite_without_skill']:.4f}")
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


def update_eval_log(skill_dir: Path, result: dict, entry_type: str = "Baseline"):
    """Append an entry to the skill's eval-log.md."""
    log_path = skill_dir / "eval-log.md"
    _append_eval_log(log_path, result, entry_type)


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


def _eval_skills_from_dir(skills_dir: Path, skill_name: Optional[str], args, all_results: list):
    """Evaluate skills from a directory, appending results."""
    if skill_name:
        skill_dirs = [skills_dir / skill_name]
        if not skill_dirs[0].exists():
            print(f"Error: skill not found: {skill_dirs[0]}", file=sys.stderr)
            return
    else:
        skill_dirs = find_skills_with_evals(skills_dir)

    for skill_dir in skill_dirs:
        result = eval_skill(
            skill_dir=skill_dir,
            baseline=args.baseline,
            compare=args.compare,
            verbose=args.verbose,
            max_scenarios=args.max_scenarios,
        )
        all_results.append(result)

        entry_type = "Baseline" if args.baseline else "Compare" if args.compare else "Evaluation"
        update_eval_log(skill_dir, result, entry_type)

        if args.baseline and result.get("scenarios_without_skill"):
            update_baseline_scores(skill_dir, result["scenarios_without_skill"])


def _eval_agents_from_dir(agents_dir: Path, agent_name: Optional[str], args, all_results: list):
    """Evaluate agents from a directory, appending results."""
    if agent_name:
        agent_names = [agent_name]
    else:
        agent_names = find_agents_with_evals(agents_dir)

    for name in agent_names:
        result = eval_agent(
            agents_dir=agents_dir,
            agent_name=name,
            baseline=args.baseline,
            compare=args.compare,
            verbose=args.verbose,
            max_scenarios=args.max_scenarios,
        )
        all_results.append(result)

        if "error" not in result:
            entry_type = "Baseline" if args.baseline else "Compare" if args.compare else "Evaluation"
            log_path = _agent_eval_log_path(agents_dir, name)
            _append_eval_log(log_path, result, entry_type)


def main():
    parser = argparse.ArgumentParser(description="Evaluate skill and agent quality")
    parser.add_argument("--plugin-dir", help="Path to plugin directory (auto-discovers skills/ and agents/)")
    parser.add_argument("--skills-dir", help="Path to skills directory")
    parser.add_argument("--skill", help="Specific skill to evaluate")
    parser.add_argument("--agents-dir", help="Path to agents directory")
    parser.add_argument("--agent", help="Specific agent to evaluate")
    parser.add_argument("--baseline", action="store_true", help="Run without component loaded")
    parser.add_argument("--compare", action="store_true", help="Run both with and without component")
    parser.add_argument("--max-scenarios", type=int, help="Limit scenarios per component (for quick tests)")
    parser.add_argument("--verbose", "-v", action="store_true", help="Verbose output")
    parser.add_argument("--output", "-o", help="Write results JSON to file")

    args = parser.parse_args()

    # Resolve directories from --plugin-dir if provided
    skills_dir = Path(args.skills_dir).resolve() if args.skills_dir else None
    agents_dir = Path(args.agents_dir).resolve() if args.agents_dir else None

    if args.plugin_dir:
        plugin_path = Path(args.plugin_dir).resolve()
        if not plugin_path.exists():
            print(f"Error: plugin directory not found: {plugin_path}", file=sys.stderr)
            sys.exit(1)
        discovered_skills, discovered_agents = discover_plugin(plugin_path)
        # --plugin-dir provides defaults; explicit --skills-dir/--agents-dir override
        if not skills_dir and discovered_skills:
            skills_dir = discovered_skills
        if not agents_dir and discovered_agents:
            agents_dir = discovered_agents

    if not skills_dir and not agents_dir:
        parser.error("Provide --plugin-dir, --skills-dir, or --agents-dir")

    all_results = []

    if skills_dir and skills_dir.exists():
        _eval_skills_from_dir(skills_dir, args.skill, args, all_results)

    if agents_dir and agents_dir.exists():
        _eval_agents_from_dir(agents_dir, args.agent, args, all_results)

    if not all_results:
        print("No components with eval configs found.", file=sys.stderr)
        sys.exit(1)

    # Print summary
    print("\n" + "=" * 60)
    print("EVALUATION SUMMARY")
    print("=" * 60)
    for r in all_results:
        if "error" in r:
            print(f"  {r.get('skill', '?')}: ERROR - {r['error']}")
            continue
        tag = f"[{r.get('type', 'skill')}]"
        line = f"  {tag:8s} {r['skill']:20s}"
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
