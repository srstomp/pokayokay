# auto-improve

Autonomous skill improvement system for Claude Code plugins, inspired by [Karpathy's autoresearch](https://github.com/karpathy/autoresearch).

Iteratively evaluates and improves skill quality using an LLM-as-judge feedback loop: edit skill → run eval scenarios → score → keep/discard → repeat.

## Using in a Claude Code Session

The most common way to use auto-improve is interactively within Claude Code. Just ask Claude to run the commands for you:

**Check how a skill is performing:**
> "Run a baseline eval on the planning skill with 3 scenarios"

**Compare with vs without:**
> "Compare the work-session skill with and without — use 5 scenarios"

**See the dashboard:**
> "Show me the skill portfolio dashboard"

**Improve a skill:**
> "The api-design skill scores low on anti-slop. Look at the eval-log, read the SKILL.md, and try to improve it. Then re-run the eval to see if the score went up."

**Manual improvement loop (the recommended workflow):**

1. Ask Claude to run `eval.py --compare` on a skill
2. Review which scenarios/criteria are failing
3. Ask Claude to read the SKILL.md and propose an improvement hypothesis
4. Make the edit
5. Re-run the eval
6. If score improved → commit. If not → revert.
7. Repeat

This manual loop is the same structure as the automated runner, but with you making the keep/discard decisions. Start here before trusting the automated loop.

**Overnight automated run:**
```bash
claude -p --model opus --dangerously-skip-permissions \
  "Run auto-improve/runner.py with --skills-dir plugins/pokayokay/skills --eval-only --max-scenarios 5 -v on all three pilot skills, then show me the dashboard"
```

## Quick Start (CLI)

```bash
# 1. Run a baseline evaluation (measures what Claude knows WITHOUT the skill)
python3 auto-improve/eval.py \
  --baseline \
  --skills-dir plugins/pokayokay/skills \
  --skill api-design \
  -v

# 2. Compare with vs without skill
python3 auto-improve/eval.py \
  --compare \
  --skills-dir plugins/pokayokay/skills \
  --skill planning \
  -v

# 3. Quick test (limit scenarios for speed)
python3 auto-improve/eval.py \
  --compare \
  --skills-dir plugins/pokayokay/skills \
  --skill api-design \
  --max-scenarios 3 \
  -v

# 4. Evaluate all skills that have eval.json
python3 auto-improve/eval.py \
  --skills-dir plugins/pokayokay/skills \
  -v

# 5. Run through the runner with dashboard updates
python3 auto-improve/runner.py \
  --skills-dir plugins/pokayokay/skills \
  --eval-only \
  -v

# 6. View portfolio dashboard
python3 auto-improve/runner.py \
  --skills-dir plugins/pokayokay/skills \
  --dashboard
```

All commands use `claude -p` (print mode) under the hood, so they inherit Claude Code's authentication. No separate API key needed.

## How It Works

### The Loop (autoresearch pattern)

```
1. Select skill (scheduler picks lowest-score or most-stale)
2. Read skill's eval.json + eval-log.md
3. Generate improvement hypothesis
4. Edit SKILL.md or references
5. Run eval suite → LLM-as-judge scores response
6. If improved → git commit, append eval-log.md
   If worse   → git revert, append eval-log.md
7. Update portfolio dashboard
8. Loop
```

### Scoring

Each scenario is scored on four dimensions:

| Dimension | Weight | How |
|---|---|---|
| **Scenario pass rate** | 50% | Binary criteria (0/1) × weight, averaged across scenarios |
| **Anti-slop rate** | 20% | Checks for generic/boilerplate output |
| **Structural compliance** | 15% | Line counts, required sections, description format |
| **LLM quality** | 15% | Proxy from scenario + anti-slop averages |

The judge uses **binary criteria with chain-of-thought-before-verdict** for maximum reliability. Each criterion is independently evaluated as pass (1) or fail (0), then weighted and aggregated.

### Per-Skill Files

Each skill gets two files alongside its existing `SKILL.md`:

```
skills/api-design/
├── SKILL.md          # (existing)
├── references/       # (existing)
├── eval.json         # Scenarios, criteria, scoring config
└── eval-log.md       # Experiment history (append-only)
```

**`eval.json`** — Defines what "good" looks like. Contains scenarios with input prompts, binary eval criteria (with weights), anti-slop checks, structural checks, and scoring weights. Human-controlled: the improvement loop cannot edit its own eval criteria.

**`eval-log.md`** — Records every experiment: hypothesis, what changed, before/after scores, kept/discarded. The agent reads this to learn from its own history.

## eval.json Schema

```json
{
  "skill": "skill-name",
  "version": 1,
  "baseline_model": "claude-haiku-4-5-20251001",
  "eval_model": "claude-haiku-4-5-20251001",
  "current_best_score": null,
  "scenarios": [
    {
      "id": "unique-kebab-id",
      "name": "Human-readable name",
      "input": "The prompt to send to Claude",
      "system_context": "Optional system-level context",
      "eval_criteria": [
        { "criterion": "Binary check: did the response include X?", "weight": 2 },
        { "criterion": "Another check", "weight": 1 }
      ],
      "baseline_score": null,
      "anti_slop_checks": [
        "Does NOT use generic placeholder names",
        "Output is specific, not boilerplate"
      ]
    }
  ],
  "structural_checks": {
    "max_skill_lines": 100,
    "max_reference_lines": 500,
    "required_sections": ["When NOT to Use"],
    "description_format": "trigger-condition"
  },
  "scoring": {
    "weights": {
      "scenario_pass_rate": 0.50,
      "anti_slop_rate": 0.20,
      "structural_compliance": 0.15,
      "llm_quality_score": 0.15
    },
    "improvement_threshold": 0.02,
    "simplicity_bonus": true
  }
}
```

## Writing Good Scenarios

### Discriminating scenarios

A good scenario sits in the **goldilocks zone** where baseline Claude passes 20-70% of the time:

| Baseline pass rate | What it means |
|---|---|
| >80% | Too easy — Claude already knows this. Proves nothing. |
| 30-60% | **Sweet spot** — the skill can make a real difference here |
| 10-30% | Hard — tests unique skill contributions |
| <10% | Drop — adds noise, not signal |

### Scenario sources

1. **Hand-crafted** (30%): Write 5-6 per skill that directly test what the skill teaches
2. **From failure logs** (30%): Map `pokayokay-review-failures.json` categories to skills
3. **LLM-generated + curated** (30%): Give Claude the skill + golden scenarios, generate variations
4. **Real session extracts** (10%): Pull from ohno task activity logs

### Criteria guidelines

- Each criterion is **binary** (yes/no) — not subjective
- Weight important criteria at 2, standard at 1
- Anti-slop checks catch generic/boilerplate output
- Test what the **skill specifically teaches**, not general Claude capabilities

## The Runner

### Scheduling strategies

| Strategy | Description | When to use |
|---|---|---|
| `adaptive` (default) | Lowest score first, skip plateaus | General overnight runs |
| `breadth` | Round-robin, fewest experiments first | Initial exploration, find quick wins |
| `deep` | Stay on one skill until plateau | Focused improvement of a specific skill |

### Commands

```bash
# Evaluate without modifying (updates dashboard)
python3 auto-improve/runner.py \
  --skills-dir plugins/pokayokay/skills \
  --eval-only -v

# Run improvement loop (N iterations)
python3 auto-improve/runner.py \
  --skills-dir plugins/pokayokay/skills \
  --iterations 50 \
  --strategy adaptive

# Target one skill
python3 auto-improve/runner.py \
  --skills-dir plugins/pokayokay/skills \
  --skill planning \
  --iterations 20

# Budget-constrained
python3 auto-improve/runner.py \
  --skills-dir plugins/pokayokay/skills \
  --iterations 100 \
  --budget-usd 15.0

# Dashboard
python3 auto-improve/runner.py \
  --skills-dir plugins/pokayokay/skills \
  --dashboard
```

### Improvement program

Edit `auto-improve/improvement-program.md` to steer the agent's strategy:
- Which skills to focus on
- Constraints (don't add domain knowledge Claude already knows)
- Strategy notes (description wording has outsized impact, authority language doubles compliance)
- Stop conditions

## Cross-Plugin Usage

The harness is plugin-agnostic. Point `--skills-dir` at any directory of skills:

```bash
# pokayokay skills
python3 auto-improve/eval.py --skills-dir plugins/pokayokay/skills -v

# toyoda design skills
python3 auto-improve/eval.py --skills-dir ~/Projects/stevestomp/toyoda/plugins/design/skills -v

# Any skill directory
python3 auto-improve/eval.py --skills-dir ~/.claude/skills -v
```

To add eval support to a new skill, create an `eval.json` in its directory.

## Architecture

```
auto-improve/
├── eval.py              # Core eval runner (scenarios, scoring, logging)
├── judge.py             # LLM-as-judge via claude CLI (binary criteria, CoT)
├── structural.py        # Automated structural checks (line counts, sections)
├── runner.py            # Loop orchestrator (scheduler, dashboard, git)
├── dashboard.json       # Portfolio state (per-skill scores, trends)
├── patterns.json        # Cross-skill learning patterns
├── improvement-program.md  # Human steering file
└── pyproject.toml       # Project metadata

skills/<name>/
├── eval.json            # Eval definition (scenarios, criteria, weights)
└── eval-log.md          # Experiment history (append-only)
```

### Key design decisions

- **Binary criteria > scored scales** — Highest agreement, lowest variance. Five binary checks are more reliable than one 1-5 holistic score.
- **claude CLI, not Anthropic SDK** — Uses `claude -p` (print mode) for API access. Inherits Claude Code auth, no separate API key.
- **Haiku as judge** — PoLL research (Cohere, 2024) showed panels of small models outperform solo GPT-4. Binary factual criteria are where small models excel.
- **Eval criteria are human-controlled** — The agent cannot edit eval.json. Same principle as autoresearch's `prepare.py`.
- **Simplicity bonus** — If score is equal but skill got shorter, keep it. Shorter skills = less context consumed.

## Prior Art

Inspired by [Karpathy's autoresearch](https://github.com/karpathy/autoresearch):

| Autoresearch | auto-improve |
|---|---|
| `train.py` (agent edits) | `SKILL.md` + `references/` |
| `program.md` (human steering) | `improvement-program.md` |
| `prepare.py` (fixed infra) | `eval.json` (fixed criteria) |
| `results.tsv` (global log) | `eval-log.md` per skill |
| `val_bpb` (metric) | Composite score (criteria + anti-slop + structural) |
| 5 min GPU training | ~30s per scenario via Haiku |
| Git commits as memory | Git commits as memory |
