FROM node:22-slim

# System dependencies
RUN apt-get update && apt-get install -y \
    git \
    python3 \
    python3-pip \
    curl \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install Claude Code CLI globally
RUN npm install -g @anthropic-ai/claude-code@latest

# Non-root user (matches typical host UID)
ARG HOST_UID=501
ARG HOST_GID=20
RUN groupadd -g ${HOST_GID} claude 2>/dev/null || true && \
    useradd -m -u ${HOST_UID} -g ${HOST_GID} -s /bin/bash claude
USER claude

WORKDIR /workspace

ENTRYPOINT ["claude"]
