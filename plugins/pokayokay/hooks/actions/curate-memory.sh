#!/bin/bash
# Curate MEMORY.md - enforce section structure and line budgets
# Called by: bridge.py on SessionEnd
# Environment: MEMORY_DIR (auto memory directory path)
# Output: Updated MEMORY.md with enforced budgets, overflow to topic files

set -e

MEMORY_DIR="${MEMORY_DIR:-}"

if [ -z "$MEMORY_DIR" ] || [ ! -d "$MEMORY_DIR" ]; then
  exit 0
fi

export MEMORY_FILE="$MEMORY_DIR/MEMORY.md"

# If MEMORY.md doesn't exist, create from template
if [ ! -f "$MEMORY_FILE" ]; then
  cat > "$MEMORY_FILE" << 'TEMPLATE'
# Memory

## Completed Work
<!-- pokayokay: managed by session-chain hooks -->

## Key Decisions
<!-- pokayokay: promoted from session handoffs -->

## Architecture Notes
<!-- pokayokay: stable project structure -->

## Active Patterns
<!-- pokayokay: graduated to .claude/rules/ when confirmed -->

## Recent Bug Fixes
<!-- pokayokay: rotated, max 5 entries -->

## Topic Index
<!-- pokayokay: links to detail files -->
- See `memory/chain-learnings.md` for session history
- See `memory/spike-results.md` for spike outcomes
- See `memory/recurring-failures.md` for failure patterns
TEMPLATE
  exit 0
fi

# Ensure all pokayokay sections exist
for section in "Completed Work" "Key Decisions" "Architecture Notes" "Active Patterns" "Recent Bug Fixes" "Topic Index"; do
  if ! grep -q "^## $section" "$MEMORY_FILE"; then
    COMMENT=""
    case "$section" in
      "Completed Work") COMMENT="<!-- pokayokay: managed by session-chain hooks -->" ;;
      "Key Decisions") COMMENT="<!-- pokayokay: promoted from session handoffs -->" ;;
      "Architecture Notes") COMMENT="<!-- pokayokay: stable project structure -->" ;;
      "Active Patterns") COMMENT="<!-- pokayokay: graduated to .claude/rules/ when confirmed -->" ;;
      "Recent Bug Fixes") COMMENT="<!-- pokayokay: rotated, max 5 entries -->" ;;
      "Topic Index") COMMENT="<!-- pokayokay: links to detail files -->" ;;
    esac
    echo "" >> "$MEMORY_FILE"
    echo "## $section" >> "$MEMORY_FILE"
    echo "$COMMENT" >> "$MEMORY_FILE"
  fi
done

# Enforce section line budgets via Python (reliable multiline parsing)
python3 - "$MEMORY_FILE" "$MEMORY_DIR" << 'PYEOF'
import os
import sys

memory_file = sys.argv[1]
memory_dir = sys.argv[2]

budgets = {
    "Completed Work": 20,
    "Key Decisions": 40,
    "Architecture Notes": 30,
    "Active Patterns": 15,
    "Recent Bug Fixes": 15,
    "Topic Index": 10,
}

archives = {
    "Completed Work": "completed-work-archive.md",
    "Key Decisions": "decisions-archive.md",
    "Architecture Notes": "architecture-archive.md",
    "Recent Bug Fixes": "bugfixes-archive.md",
}

pokayokay_marker = "<!-- pokayokay:"

with open(memory_file, "r") as f:
    content = f.read()

lines = content.split("\n")

# Parse into sections: list of (header, is_pokayokay, content_lines)
sections = []
current_header = None
current_lines = []
current_is_pokayokay = False

for line in lines:
    if line.startswith("## "):
        if current_header is not None or current_lines:
            sections.append((current_header, current_is_pokayokay, current_lines))
        current_header = line[3:].strip()
        current_lines = [line]
        current_is_pokayokay = False
    elif pokayokay_marker in line and current_header:
        current_is_pokayokay = True
        current_lines.append(line)
    elif line.startswith("# ") and not line.startswith("## "):
        if current_header is not None or current_lines:
            sections.append((current_header, current_is_pokayokay, current_lines))
        current_header = None
        current_lines = [line]
        current_is_pokayokay = False
    else:
        current_lines.append(line)

if current_header is not None or current_lines:
    sections.append((current_header, current_is_pokayokay, current_lines))

# Enforce budgets on pokayokay sections
output_sections = []
for header, is_pokayokay, section_lines in sections:
    if not is_pokayokay or header not in budgets:
        output_sections.append(section_lines)
        continue

    budget = budgets[header]
    if len(section_lines) <= budget:
        output_sections.append(section_lines)
        continue

    # Over budget - trim oldest content lines (keep header + comment + newest)
    header_lines = section_lines[:2]
    content_lines = section_lines[2:]

    while content_lines and not content_lines[0].strip():
        content_lines.pop(0)

    overflow_count = len(content_lines) - (budget - 2)
    if overflow_count > 0 and header in archives:
        overflow = content_lines[:overflow_count]
        remaining = content_lines[overflow_count:]

        archive_path = os.path.join(memory_dir, archives[header])
        archive_header = "# {} Archive\n\nOverflow entries from MEMORY.md, managed by pokayokay.\n\n".format(header)
        existing = ""
        if os.path.exists(archive_path):
            with open(archive_path, "r") as f:
                existing = f.read()
        if not existing.strip():
            existing = archive_header

        existing += "\n" + "\n".join(overflow) + "\n"
        with open(archive_path, "w") as f:
            f.write(existing)

        output_sections.append(header_lines + remaining)
    else:
        output_sections.append(header_lines + content_lines[:(budget - 2)])

output = "\n".join(line for section in output_sections for line in section)
output = output.rstrip() + "\n"

with open(memory_file, "w") as f:
    f.write(output)
PYEOF
