# Dockerfile for Runyx Sync Agent (Production)
# This container runs the pre-built agent binary

FROM debian:bookworm-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd -g 1000 agent && \
    useradd -r -u 1000 -g agent -d /app -s /bin/bash agent

# Create directories
RUN mkdir -p /app /etc/runyx /data && \
    chown -R agent:agent /app /etc/runyx /data

WORKDIR /app

# Copy pre-built binary
COPY --chown=agent:agent bin/sync-agent ./agent
RUN chmod +x ./agent

# Copy example config
COPY --chown=agent:agent config.example.yaml /etc/runyx/config.example.yaml

# Switch to non-root user
USER agent

# Expose ports
EXPOSE 9090
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD ["./agent", "health"] || exit 1

ENTRYPOINT ["./agent"]
CMD ["start"]
