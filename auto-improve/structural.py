"""Automated structural checks for skill quality."""

from __future__ import annotations

import re
from pathlib import Path


def check_skill_structure(skill_dir: Path, checks: dict) -> dict:
    """Run structural checks on a skill directory.

    Args:
        skill_dir: Path to the skill directory (contains SKILL.md)
        checks: structural_checks config from eval.json

    Returns:
        dict with passed/total counts and per-check details
    """
    skill_md = skill_dir / "SKILL.md"
    if not skill_md.exists():
        return {"passed": 0, "total": 1, "details": [{"check": "SKILL.md exists", "passed": False}]}

    content = skill_md.read_text()
    lines = content.splitlines()
    results = []

    # Check SKILL.md line count
    max_lines = checks.get("max_skill_lines", 100)
    results.append({
        "check": f"SKILL.md under {max_lines} lines",
        "passed": len(lines) <= max_lines,
        "value": len(lines),
    })

    # Check references line counts
    max_ref_lines = checks.get("max_reference_lines", 500)
    refs_dir = skill_dir / "references"
    if refs_dir.exists():
        for ref_file in sorted(refs_dir.glob("*.md")):
            ref_lines = len(ref_file.read_text().splitlines())
            results.append({
                "check": f"references/{ref_file.name} under {max_ref_lines} lines",
                "passed": ref_lines <= max_ref_lines,
                "value": ref_lines,
            })

    # Check required sections
    for section in checks.get("required_sections", []):
        # Look for the section as a heading or in content
        pattern = re.compile(rf"#+\s*{re.escape(section)}", re.IGNORECASE)
        found = bool(pattern.search(content))
        if not found:
            # Also check for it as plain text
            found = section.lower() in content.lower()
        results.append({
            "check": f"Has '{section}' section",
            "passed": found,
        })

    # Check description format
    desc_format = checks.get("description_format")
    if desc_format == "trigger-condition":
        # Extract description from frontmatter
        fm_match = re.match(r"^---\n(.*?)\n---", content, re.DOTALL)
        if fm_match:
            fm_text = fm_match.group(1)
            # Look for description field
            desc_match = re.search(r"description:\s*['\"]?(.*?)(?:['\"]?\s*$|\n)", fm_text, re.MULTILINE)
            if desc_match:
                desc = desc_match.group(1).strip()
                # Trigger-condition format: starts with "Use when" or similar
                is_trigger = bool(re.match(
                    r"(?:Use\s+(?:when|this|for)|ALWAYS|You\s+MUST)",
                    desc,
                    re.IGNORECASE,
                ))
                results.append({
                    "check": "Description uses trigger-condition format",
                    "passed": is_trigger,
                    "value": desc[:80],
                })
            else:
                results.append({
                    "check": "Description uses trigger-condition format",
                    "passed": False,
                    "value": "No description found in frontmatter",
                })
        else:
            results.append({
                "check": "Description uses trigger-condition format",
                "passed": False,
                "value": "No frontmatter found",
            })

    # Check frontmatter validity (reuse quick_validate.py logic)
    fm_match = re.match(r"^---\n(.*?)\n---", content, re.DOTALL)
    has_valid_fm = False
    if fm_match:
        try:
            import yaml
            fm = yaml.safe_load(fm_match.group(1))
            has_valid_fm = isinstance(fm, dict) and "name" in fm and "description" in fm
        except Exception:
            pass
    results.append({
        "check": "Valid YAML frontmatter with name and description",
        "passed": has_valid_fm,
    })

    passed = sum(1 for r in results if r["passed"])
    return {
        "passed": passed,
        "total": len(results),
        "score": passed / len(results) if results else 0.0,
        "details": results,
    }
