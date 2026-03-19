#!/usr/bin/env bash
set -euo pipefail

# Run Claude Code overnight in Docker isolation
#
# Usage:
#   ./docker/run-overnight.sh                          # pokayokay default
#   ./docker/run-overnight.sh -d ~/Projects/toyoda     # any project
#   ./docker/run-overnight.sh -d ~/Projects/toyoda --prompt="improve skills"
#
# Options:
#   -d <dir>    Project directory (default: pokayokay repo root)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
POKAYOKAY_DIR="$(dirname "$SCRIPT_DIR")"
AUTO_IMPROVE_DIR="$POKAYOKAY_DIR/auto-improve"
IMAGE_NAME="pokayokay-claude"

# Parse -d flag for project directory
PROJECT_DIR="$POKAYOKAY_DIR"
CLAUDE_ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -d)
            PROJECT_DIR="$(cd "$2" && pwd)"
            shift 2
            ;;
        *)
            CLAUDE_ARGS+=("$1")
            shift
            ;;
    esac
done

# Derive container name from project directory (allows parallel runs)
PROJECT_NAME="$(basename "$PROJECT_DIR")"
CONTAINER_NAME="claude-${PROJECT_NAME}"

# Default args if none provided
if [ ${#CLAUDE_ARGS[@]} -eq 0 ]; then
    CLAUDE_ARGS=(
        --print
        --dangerously-skip-permissions
        --prompt="/pokayokay:work unattended -n auto --all"
    )
fi

# Build image if needed (cached after first build)
echo "Building Docker image (cached)..."
docker build \
    --build-arg HOST_UID="$(id -u)" \
    --build-arg HOST_GID="$(id -g)" \
    -t "$IMAGE_NAME" \
    "$SCRIPT_DIR"

echo "Starting Claude Code in Docker..."
echo "  Container: $CONTAINER_NAME"
echo "  Project: $PROJECT_DIR"
echo "  Auto-improve: $AUTO_IMPROVE_DIR"
echo "  Args: ${CLAUDE_ARGS[*]}"
echo ""

docker run --rm -it \
    --name "$CONTAINER_NAME" \
    \
    `# Mount project (read-write for code changes)` \
    -v "$PROJECT_DIR:/workspace" \
    \
    `# Mount auto-improve scripts (read-only, always available)` \
    -v "$AUTO_IMPROVE_DIR:/workspace/auto-improve:ro" \
    \
    `# Mount Claude config (auth, settings, plugins, memory)` \
    -v "$HOME/.claude:/home/claude/.claude" \
    \
    `# Git config (for commits)` \
    -v "$HOME/.gitconfig:/home/claude/.gitconfig:ro" \
    \
    `# Resource limits` \
    --memory=16g \
    --cpus=8 \
    \
    --security-opt=no-new-privileges \
    \
    "$IMAGE_NAME" \
    "${CLAUDE_ARGS[@]}"
