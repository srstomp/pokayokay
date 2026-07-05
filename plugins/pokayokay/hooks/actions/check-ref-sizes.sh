#!/bin/bash
# Check that reference files in skills/ don't exceed 500 lines
# Called by: pre-commit hooks (via bridge.py handle_pre_commit)
#
# Exit-code contract (see HOOKS.md): 0 = success, 1 = warning (advisory),
# 2 = error (blocks the commit). Oversized reference files that are staged —
# or about to be staged by the intercepted command — block. Working-tree
# files the commit will not include never block.

MAX_LINES=500
SKILLS_DIR="plugins/pokayokay/skills"
REF_PATTERN="^${SKILLS_DIR}/.*/references/.*\.md$"

# The intercepted Bash command, passed by bridge.py handle_pre_commit.
# Shell metacharacters (&&, ;, |, …) are neutralized to spaces in transit,
# so detection below matches tokens, not separators.
GIT_COMMAND="${POKAYOKAY_GIT_COMMAND:-}"

# Check staged .md files in skills/*/references/
FILES=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null | grep "$REF_PATTERN" || true)
SCOPE="staged"
BLOCK_EXIT=2

list_working_tree_refs() {
  { git diff --name-only --diff-filter=ACM 2>/dev/null
    git ls-files --others --exclude-standard 2>/dev/null
  } | grep "$REF_PATTERN" | sort -u || true
}

# The hook fires on PreToolUse for the whole Bash command, so compound
# commands like `git add -A && git commit ...` run this check before anything
# is staged. When no reference files are staged, only widen the scan to files
# the intercepted command will actually stage — a blanket working-tree scan
# would block commits that don't contain the offending file (e.g. an
# oversized untracked WIP draft deadlocking every later commit).
if [ -z "$FILES" ]; then
  ADD_CMD='(^|[[:space:]])git[[:space:]]+(-[^[:space:]]+[[:space:]]+)*add([[:space:]]|$)'
  COMMIT_CMD='(^|[[:space:]])git[[:space:]]+(-[^[:space:]]+[[:space:]]+)*commit([[:space:]]|$)'
  ADD_ALL_ARG='[[:space:]](-A|--all|-[a-zA-Z]*A[a-zA-Z]*|\.)([[:space:]]|$)'
  COMMIT_ALL_ARG='[[:space:]](--all|-[a-z]*a[a-z]*)([[:space:]]|$)'

  if [ -n "$GIT_COMMAND" ]; then
    if echo "$GIT_COMMAND" | grep -qE "$ADD_CMD" && echo "$GIT_COMMAND" | grep -qE "$ADD_ALL_ARG"; then
      # add-all form (`git add -A/--all/.`): modified + untracked will be staged
      SCOPE="about-to-be-staged"
      FILES=$(list_working_tree_refs)
    elif echo "$GIT_COMMAND" | grep -qE "$COMMIT_CMD" && echo "$GIT_COMMAND" | grep -qE "$COMMIT_ALL_ARG"; then
      # `git commit -a/--all`: tracked modified files will be committed
      SCOPE="about-to-be-staged"
      FILES=$(git diff --name-only --diff-filter=ACM 2>/dev/null | grep "$REF_PATTERN" || true)
    elif echo "$GIT_COMMAND" | grep -qE "$ADD_CMD"; then
      # `git add <pathspec>...`: gate reference files the add will stage.
      # bridge.py neutralizes shell separators (&& ; | ( )) to spaces before
      # we see the command, so the pathspec region cannot be bounded by them.
      # Walk the token stream as a git command parser: `add`/`commit` are only
      # honored as SUBCOMMANDS — the token following `git` past any global
      # options — never as bare words. This scans EVERY `git add` segment in a
      # compound command (so a later `&& git add <oversized-ref>` cannot slip
      # past) while an `add`/`commit` word inside a commit MESSAGE (which is
      # not a subcommand) can never start or restart pathspec collection.
      # Candidates match by exact path, parent directory, or glob (refs/*.md).
      SCOPE="about-to-be-staged"
      CANDIDATES=$(list_working_tree_refs)
      NL=$'\n'
      FILES=""
      # Extract pathspec tokens (tr avoids for-loop glob expansion).
      ALL_TOKENS=$(printf '%s' "$GIT_COMMAND" | tr ' \t' '\n\n')
      PATHSPECS=""
      expect_subcmd=""   # just saw `git`, awaiting its subcommand
      in_add=""          # currently inside a `git add` pathspec list
      skip_next=""       # consume the argument of a -C/-c global option
      while IFS= read -r tok; do
        [ -n "$tok" ] || continue
        if [ -n "$skip_next" ]; then skip_next=""; continue; fi
        if [ "$tok" = "git" ]; then
          expect_subcmd=1; in_add=""; continue
        fi
        if [ -n "$expect_subcmd" ]; then
          case "$tok" in
            -C|-c) skip_next=1; continue ;;  # global option taking an argument
            -*) continue ;;                   # other global option: keep waiting
          esac
          [ "$tok" = "add" ] && in_add=1 || in_add=""
          expect_subcmd=""
          continue
        fi
        [ -n "$in_add" ] || continue
        # Inside the add pathspec list; skip option flags (e.g. --, -f).
        case "$tok" in -*) continue ;; esac
        PATHSPECS="${PATHSPECS}${PATHSPECS:+$NL}${tok}"
      done <<< "$ALL_TOKENS"
      while IFS= read -r candidate; do
        [ -n "$candidate" ] || continue
        matched=""
        while IFS= read -r token; do
          [ -n "$token" ] || continue
          token="${token#\"}"; token="${token%\"}"
          token="${token#\'}"; token="${token%\'}"
          token="${token#./}"
          token="${token%/}"
          if [ "$token" = "." ] || [ -z "$token" ]; then
            matched=1
            break
          fi
          # Unquoted case patterns give glob matching without pathname
          # expansion; $token/* additionally covers directory containment.
          case "$candidate" in
            $token|$token/*) matched=1; break ;;
          esac
        done <<< "$PATHSPECS"
        [ -n "$matched" ] && FILES="${FILES}${FILES:+$NL}${candidate}"
      done <<< "$CANDIDATES"
    fi
    # Plain `git commit` of already-staged files: nothing relevant staged,
    # nothing new will be — no fallback scan.
  else
    # No command context (direct invocation outside bridge.py): scan the
    # working tree but stay advisory — we can't tell what the commit includes.
    SCOPE="working-tree"
    BLOCK_EXIT=1
    FILES=$(list_working_tree_refs)
  fi
fi

if [ -z "$FILES" ]; then
  echo "✓ No reference file changes to check"
  exit 0
fi

VIOLATIONS=""
COUNT=0
CHECKED=0

while IFS= read -r file; do
  [ -f "$file" ] || continue
  CHECKED=$((CHECKED + 1))
  LINES=$(wc -l < "$file")
  if [ "$LINES" -gt "$MAX_LINES" ]; then
    VIOLATIONS="${VIOLATIONS}"$'\n'"  ${file} (${LINES} lines)"
    COUNT=$((COUNT + 1))
  fi
done <<< "$FILES"

if [ "$COUNT" -gt 0 ]; then
  if [ "$BLOCK_EXIT" -eq 2 ]; then
    echo "ERROR: ${COUNT} ${SCOPE} reference file(s) exceed ${MAX_LINES}-line limit:${VIOLATIONS}"
  else
    echo "WARNING: ${COUNT} ${SCOPE} reference file(s) exceed ${MAX_LINES}-line limit (advisory — not part of this commit):${VIOLATIONS}"
  fi
  echo ""
  echo "Split oversized files into focused sub-topics and update the skill's SKILL.md reference table."
  exit "$BLOCK_EXIT"
fi

echo "✓ All ${CHECKED} ${SCOPE} reference files under ${MAX_LINES} lines"
