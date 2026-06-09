# Use the official uv Docker image with Python 3.12
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim

# Install git (required for uv to clone repositories)
RUN apt-get update && \
    apt-get install -y --no-install-recommends git && \
    rm -rf /var/lib/apt/lists/*

# Create non-root user for security
RUN groupadd --system --gid 999 nonroot \
 && useradd --system --gid 999 --uid 999 --create-home nonroot

# Set working directory
WORKDIR /app

# Configure uv environment variables
ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy

# Clone and install mealie-mcp-server from GitHub repository
ARG CACHE_BUST=1RUN echo "CACHE_BUST=${CACHE_BUST}" && \
    git clone --branch main --single-branch https://github.com/ericfri/mealie-mcp-server.git /app && \
    cd /app && \
    git rev-parse HEAD && \
    uv sync --locked && \
    chown -R nonroot:nonroot /app

RUN uv sync --locked \
    && uv add fastmcp

COPY server.py /app/src/server.py

# Add OCI labels for GitHub Container Registry
LABEL org.opencontainers.image.source=https://github.com/danielpalstra/mealie-mcp-server-docker
LABEL org.opencontainers.image.description="Dockerized Mealie MCP Server - provides MCP interface to Mealie recipe manager"
LABEL org.opencontainers.image.licenses=MIT

# Ensure PATH includes virtual environment
ENV PATH="/app/.venv/bin:$PATH"

EXPOSE 8000

# Switch to non-root user
USER nonroot

# Set the entrypoint to run the MCP server
# The server expects MEALIE_BASE_URL and MEALIE_API_KEY environment variables
# ENTRYPOINT ["python", "src/server.py"]

ENTRYPOINT ["fastmcp", "run", "src/server.py", "--host", "0.0.0.0", "--with", "httpx", "--transport", "http"]
