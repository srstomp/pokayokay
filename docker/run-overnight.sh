#!/usr/bin/env bash
set -euo pipefail

# Run Claude Code in Docker isolation
#
# Usage:
#   ./docker/run-overnight.sh                          # pokayokay repo
#   ./docker/run-overnight.sh -d ~/Projects/toyoda     # any project

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
POKAYOKAY_DIR="$(dirname "$SCRIPT_DIR")"
AUTO_IMPROVE_DIR="$POKAYOKAY_DIR/auto-improve"
PLUGIN_DIR="$POKAYOKAY_DIR/plugins/pokayokay"
IMAGE_NAME="pokayokay-claude"

# Parse -d flag for project directory
PROJECT_DIR="$POKAYOKAY_DIR"
while [[ $# -gt 0 ]]; do
    case "$1" in
        -d)
            PROJECT_DIR="$(cd "$2" && pwd)"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

PROJECT_NAME="$(basename "$PROJECT_DIR")"
CONTAINER_NAME="claude-${PROJECT_NAME}"

# Build image if needed (cached after first build)
echo "Building Docker image (cached)..."
docker build \
    --build-arg HOST_UID="$(id -u)" \
    --build-arg HOST_GID="$(id -g)" \
    -t "$IMAGE_NAME" \
    "$SCRIPT_DIR"

# Pass API key if set
ENV_ARGS=()
if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
    ENV_ARGS+=(-e "ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY")
fi

echo "Starting Claude Code in Docker..."
echo "  Container: $CONTAINER_NAME"
echo "  Project: $PROJECT_DIR"
echo ""

docker run --rm -it \
    --name "$CONTAINER_NAME" \
    -v "$PROJECT_DIR:/workspace" \
    -v "$AUTO_IMPROVE_DIR:/workspace/auto-improve:ro" \
    -v "$PLUGIN_DIR:/pokayokay-plugin:ro" \
    -v "$HOME/.claude:/home/claude/.claude" \
    -v "$HOME/.claude.json:/home/claude/.claude.json" \
    -v "$HOME/.gitconfig:/home/claude/.gitconfig:ro" \
    "${ENV_ARGS[@]+"${ENV_ARGS[@]}"}" \
    --memory=16g \
    --cpus=8 \
    --security-opt=no-new-privileges \
    "$IMAGE_NAME" \
    --dangerously-skip-permissions \
    --plugin-dir /pokayokay-plugin
