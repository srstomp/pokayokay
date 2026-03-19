"""LLM-as-judge scoring for skill evaluation.

Uses binary criteria with chain-of-thought-before-verdict for reliable scoring.

Two backends, auto-detected:
- Anthropic SDK (fast, parallelizable) — used when ANTHROPIC_API_KEY is set
- claude CLI (no API key needed) — fallback using Claude Code's auth
"""

from __future__ import annotations

import json
import os
import re
import subprocess


# --- Backend detection ---

MODEL_MAP = {
    "haiku": "claude-haiku-4-5-20251001",
    "sonnet": "claude-sonnet-4-6",
    "opus": "claude-opus-4-6",
}

MODEL_MAP_REVERSE = {v: k for k, v in MODEL_MAP.items()}


def _get_backend() -> str:
    """Detect which backend to use. SDK if API key is set, CLI otherwise."""
    if os.environ.get("ANTHROPIC_API_KEY"):
        return "sdk"
    return "cli"


def _get_sdk_client():
    """Lazy-load the Anthropic SDK client."""
    import anthropic
    return anthropic.Anthropic()


# --- Prompts ---

JUDGE_SYSTEM_PROMPT = """You are an evaluation judge. Your job is to assess whether an AI response meets specific criteria.

Rules:
- Evaluate each criterion INDEPENDENTLY. Do not let one criterion influence another.
- Ignore response length. A short response that meets criteria is better than a long one that doesn't.
- For each criterion, provide brief reasoning (1 sentence), then a binary score (0 or 1).
- For anti-slop checks, score 1 if the check PASSES (the bad pattern is NOT present), 0 if violated.
- Be strict: partial compliance is 0. The criterion must be clearly met."""

JUDGE_USER_TEMPLATE = """Evaluate this AI response against the criteria below.

## Response to Evaluate

{response}

## Criteria (score 0 or 1 for each)

{criteria_list}

## Anti-Slop Checks (score 1 if check passes, 0 if violated)

{anti_slop_list}

Return ONLY valid JSON in this exact format:
{{
  "criteria": [
    {{"reasoning": "brief reason", "score": 0}},
    {{"reasoning": "brief reason", "score": 1}}
  ],
  "anti_slop": [
    {{"reasoning": "brief reason", "score": 1}}
  ]
}}"""


# --- API backends ---

def claude_sdk(
    prompt: str,
    system_prompt: str = "",
    model: str = "haiku",
) -> str:
    """Call Claude via the Anthropic SDK."""
    client = _get_sdk_client()
    model_id = MODEL_MAP.get(model, model)

    kwargs = {
        "model": model_id,
        "max_tokens": 4096,
        "messages": [{"role": "user", "content": prompt}],
    }
    if system_prompt:
        kwargs["system"] = system_prompt

    response = client.messages.create(**kwargs)
    return response.content[0].text.strip()


def claude_cli(
    prompt: str,
    system_prompt: str = "",
    model: str = "haiku",
) -> str:
    """Call claude CLI in print mode and return the response text."""
    cmd = [
        "claude", "-p",
        "--model", model,
        "--output-format", "text",
        "--no-session-persistence",
        "--disable-slash-commands",
    ]
    if system_prompt:
        cmd.extend(["--system-prompt", system_prompt])

    result = subprocess.run(
        cmd,
        input=prompt,
        capture_output=True,
        text=True,
        timeout=600,
    )

    if result.returncode != 0:
        raise RuntimeError(f"claude CLI error (exit {result.returncode}): {result.stderr[:500]}")

    return result.stdout.strip()


def call_llm(
    prompt: str,
    system_prompt: str = "",
    model: str = "haiku",
) -> str:
    """Call Claude using the best available backend."""
    backend = _get_backend()
    if backend == "sdk":
        return claude_sdk(prompt, system_prompt, model)
    return claude_cli(prompt, system_prompt, model)


# --- Formatting ---

def format_criteria_list(criteria: list[dict]) -> str:
    """Format criteria for the judge prompt."""
    lines = []
    for i, c in enumerate(criteria, 1):
        lines.append(f"{i}. {c['criterion']} (weight: {c.get('weight', 1)})")
    return "\n".join(lines)


def format_anti_slop_list(checks: list[str]) -> str:
    """Format anti-slop checks for the judge prompt."""
    if not checks:
        return "(none)"
    return "\n".join(f"{i}. {check}" for i, check in enumerate(checks, 1))


# --- JSON parsing ---

def _parse_judge_json(raw_text: str) -> dict | None:
    """Extract JSON from judge response, handling markdown code blocks."""
    json_text = raw_text
    if "```" in json_text:
        start = json_text.find("{")
        end = json_text.rfind("}") + 1
        if start >= 0 and end > start:
            json_text = json_text[start:end]

    try:
        return json.loads(json_text)
    except json.JSONDecodeError:
        pass

    match = re.search(r"\{.*\}", raw_text, re.DOTALL)
    if match:
        try:
            return json.loads(match.group())
        except json.JSONDecodeError:
            pass

    return None


# --- Scoring ---

def judge_response(
    response_text: str,
    criteria: list[dict],
    anti_slop_checks: list[str],
    model: str = "haiku",
) -> dict:
    """Judge a response against criteria using LLM-as-judge.

    Args:
        response_text: The AI response to evaluate
        criteria: List of {"criterion": str, "weight": int} dicts
        anti_slop_checks: List of anti-slop check strings
        model: Model to use as judge (alias or full ID)

    Returns:
        dict with criteria_scores, anti_slop_scores, and weighted totals
    """
    user_msg = JUDGE_USER_TEMPLATE.format(
        response=response_text,
        criteria_list=format_criteria_list(criteria),
        anti_slop_list=format_anti_slop_list(anti_slop_checks),
    )

    try:
        raw_text = call_llm(user_msg, JUDGE_SYSTEM_PROMPT, model)
    except (RuntimeError, subprocess.TimeoutExpired, Exception) as e:
        return {
            "error": str(e),
            "criteria_scores": [{"reasoning": "api error", "score": 0}] * len(criteria),
            "anti_slop_scores": [{"reasoning": "api error", "score": 0}] * len(anti_slop_checks),
            "criteria_weighted_score": 0.0,
            "anti_slop_score": 0.0,
        }

    result = _parse_judge_json(raw_text)
    if result is None:
        return {
            "error": f"Failed to parse judge response: {raw_text[:200]}",
            "criteria_scores": [{"reasoning": "parse error", "score": 0}] * len(criteria),
            "anti_slop_scores": [{"reasoning": "parse error", "score": 0}] * len(anti_slop_checks),
            "criteria_weighted_score": 0.0,
            "anti_slop_score": 0.0,
        }

    criteria_scores = result.get("criteria", [])
    anti_slop_scores = result.get("anti_slop", [])

    # Pad if judge returned fewer than expected
    while len(criteria_scores) < len(criteria):
        criteria_scores.append({"reasoning": "not evaluated", "score": 0})
    while len(anti_slop_scores) < len(anti_slop_checks):
        anti_slop_scores.append({"reasoning": "not evaluated", "score": 0})

    # Compute weighted criteria score
    total_weight = sum(c.get("weight", 1) for c in criteria)
    weighted_sum = sum(
        cs.get("score", 0) * c.get("weight", 1)
        for cs, c in zip(criteria_scores, criteria)
    )
    criteria_weighted = weighted_sum / total_weight if total_weight > 0 else 0.0

    # Compute anti-slop score
    slop_total = len(anti_slop_checks)
    slop_sum = sum(s.get("score", 0) for s in anti_slop_scores)
    anti_slop_rate = slop_sum / slop_total if slop_total > 0 else 1.0

    return {
        "criteria_scores": criteria_scores,
        "anti_slop_scores": anti_slop_scores,
        "criteria_weighted_score": criteria_weighted,
        "anti_slop_score": anti_slop_rate,
    }
