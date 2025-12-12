FROM ghcr.io/astral-sh/uv:python3.13-bookworm-slim AS runner
ENV UV_PYTHON_DOWNLOADS=0
RUN apt-get update && \
    apt-get install -y --no-install-recommends \ 
        ca-certificates \ 
        wget \ 
        gnupg \ 
        fonts-liberation \ 
        libasound2 \ 
        libatk-bridge2.0-0 \ 
        libatk1.0-0 \ 
        libc6 \ 
        libcairo2 \ 
        libdbus-1-3 \ 
        libexpat1 \ 
        libgbm1 \ 
        libglib2.0-0 \ 
        libgtk-3-0 \ 
        libnspr4 \ 
        libnss3 \ 
        libx11-6 \ 
        libx11-xcb1 \ 
        libxcb1 \ 
        libxcomposite1 \ 
        libxcursor1 \ 
        libxdamage1 \ 
        libxext6 \ 
        libxfixes3 \ 
        libxrandr2 \ 
        libxrender1 \ 
        libxss1 \ 
        libxtst6 \ 
        lsb-release && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

FROM ghcr.io/astral-sh/uv:python3.13-bookworm-slim AS builder
ENV UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy UV_PYTHON_DOWNLOADS=0
ENV PLAYWRIGHT_BROWSERS_PATH=/opt/playwright
ENV XDG_CACHE_HOME=/tmp
WORKDIR /app

# Install dependencies
COPY pyproject.toml uv.lock README.md /app/
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked --no-install-project --no-dev

# Install project
COPY torrent_search /app/torrent_search
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked --no-dev

# Install playwright browsers using the project's Playwright version so revisions match
RUN mkdir -p /opt/playwright && chmod 755 /opt/playwright && \
    uv run playwright install --with-deps chromium || true

FROM runner
COPY --from=builder /opt/playwright /opt/playwright
COPY --from=builder --chown=app:app /app /app
ENV PATH="/app/.venv/bin:$PATH"
ENV PLAYWRIGHT_BROWSERS_PATH=/opt/playwright
ENV XDG_CACHE_HOME=/tmp

EXPOSE 8000
CMD ["torrent-search-mcp", "--mode", "sse"]