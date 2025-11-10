# Runyx Sync Agent - Client Distribution

This directory contains the Runyx Sync Agent for deployment in client environments.

## Contents

- `bin/sync-agent` - Agent executable binary
- `config.example.yaml` - Configuration template
- `Dockerfile` - Docker container for agent execution
- `docker-compose.yml` - Simplified Docker Compose orchestration
- `run.sh` - Automated installation script

## Requirements

- Docker 20.10+ and Docker Compose 2.0+
- Required environment variables:
  - `AGENT_TOKEN` - Agent authentication token
  - `TENANT_ID` - Tenant ID
  - `AGENT_ID` - Unique agent identifier

## Installation

### Option 1: Automatic Installation with run.sh (Recommended)

The `run.sh` script performs all configuration automatically, including:
- Linux distribution detection
- Docker installation (if needed)
- Docker service initialization
- **Loading credentials from `.env` file**
- **Auto-populating `config.yaml` with credentials**
- **RSA key generation for encryption**
- **Setting proper file ownership for container user**
- Agent startup with Docker Compose
- Health checks and connectivity verification

**Usage:**

1. Create an `.env` file:
```bash
cp .env.example .env
# Edit .env with your credentials
```

2. Run the installer script:
```bash
./run.sh
```

The script will:
- Automatically detect your distribution (Ubuntu, Debian, CentOS, RHEL, Fedora, Amazon Linux)
- Install Docker if not present
- Configure Docker group permissions for the current user
- Start Docker service via systemd
- Generate RSA encryption keys automatically (data/keys/agent-private.pem and agent-public.pem)
- Configure and start the agent
- Test ports 9090 (metrics) and 8080 (WebUI)

### Option 2: Manual Docker Compose

1. Create an `.env` file:
```bash
cp .env.example .env
# Edit .env with your credentials
```

2. Copy the configuration file:
```bash
cp config.example.yaml config.yaml
```

3. Start the agent:
```bash
docker compose up -d --build
```

4. Check logs:
```bash
docker compose logs -f
```

### Option 3: Docker Run

```bash
docker build -t runyx-sync-agent .

docker run -d \
  --name runyx-sync-agent \
  -e AGENT_TOKEN=your-token-here \
  -e TENANT_ID=your-tenant-id \
  -e AGENT_ID=agent-001 \
  -e AGENT_CLOUD_URL=wss://dataguard.runyx.io/ws \
  -p 9090:9090 \
  -p 8080:8080 \
  -v $(pwd)/data:/data \
  -v $(pwd)/config.yaml:/etc/runyx/config.yaml:ro \
  runyx-sync-agent
```

### Option 4: Direct Binary Execution

```bash
export AGENT_TOKEN=your-token-here
export TENANT_ID=your-tenant-id
export AGENT_ID=agent-001

./bin/sync-agent start
```

## Ports

- `9090` - Prometheus metrics
- `8080` - WebUI (if available)

## Useful Commands

```bash
# View logs
docker compose logs -f

# Stop the agent
docker compose down

# Restart the agent
docker compose restart

# Check status
docker compose ps

# View metrics
curl http://localhost:9090/metrics

# Health check
curl http://localhost:9090/health
```

## Configuration

Edit the `config.yaml` file to customize:
- Cloud server URL
- Log level
- Timeouts
- Connection pool
- Encryption
- And more...

See `config.example.yaml` for all available options.

## Supported Distributions

The auto-installer (`run.sh`) supports:
- Ubuntu 18.04+
- Debian 9+
- CentOS 7+
- RHEL 7+
- Rocky Linux
- AlmaLinux
- Fedora 30+
- Amazon Linux 2

## Environment Variables

**Required:**
- `AGENT_TOKEN` - Authentication token obtained from the cloud dashboard
- `TENANT_ID` - Tenant/organization ID
- `AGENT_ID` - Unique identifier for this agent instance

**Optional:**
- `AGENT_CLOUD_URL` - WebSocket URL to the cloud server (default: wss://dataguard.runyx.io/ws)
- `AGENT_LOG_LEVEL` - Logging level: debug, info, warn, error (default: info)

## Troubleshooting

### Agent won't start

```bash
# Check Docker is running
docker info

# Check logs
docker compose logs -f

# Verify environment variables
cat .env
```

### Connection issues

```bash
# Test WebSocket connectivity
curl -i -N \
  -H "Connection: Upgrade" \
  -H "Upgrade: websocket" \
  -H "Sec-WebSocket-Version: 13" \
  -H "Sec-WebSocket-Key: test" \
  wss://dataguard.runyx.io/ws

# Check firewall rules
sudo iptables -L
```

### Metrics not available

```bash
# Check if container is running
docker compose ps

# Check metrics endpoint
curl http://localhost:9090/metrics

# Verify port binding
netstat -tlnp | grep 9090
```

## Security

- The agent runs as a non-root user inside the container
- All communication with the cloud is encrypted via TLS/WebSocket
- Credentials are stored in environment variables (not in code)
- The binary is statically compiled with no external dependencies

### SSL/TLS Certificates

The agent connects to the Runyx Cloud API at `apidg.runyx.io`, which uses **ZeroSSL certificates**.

**✅ Automatic Certificate Installation:**

The Docker image automatically installs the necessary ZeroSSL CA certificates during build time. When you run:

```bash
docker compose up -d --build
```

The container will:
1. Install the ZeroSSL CA bundle from `certs/zerossl-ca-bundle.crt`
2. Update the system certificate store
3. Verify SSL/TLS connections to `apidg.runyx.io`

**No manual intervention is required!** The certificates are embedded in the Docker image.

**Files:**
- `certs/zerossl-ca-bundle.crt` - ZeroSSL intermediate CA certificate
- Installed to: `/usr/local/share/ca-certificates/zerossl-runyx-cloud.crt` (inside container)

**Troubleshooting SSL Errors:**

If you see an error like:
```
x509: certificate signed by unknown authority
```

This means the CA certificates were not installed. Solutions:

1. **Rebuild the Docker image:**
   ```bash
   docker compose down
   docker compose up -d --build
   ```

2. **Verify the `certs/` directory exists:**
   ```bash
   ls -la certs/
   # Should show: zerossl-ca-bundle.crt
   ```

3. **Check certificates inside the container:**
   ```bash
   docker exec runyx-sync-agent ls -la /usr/local/share/ca-certificates/
   docker exec runyx-sync-agent cat /etc/ssl/certs/ca-certificates.crt | grep -i zerossl
   ```

## Data Persistence

The agent stores temporary data in the `/data` directory, which is mounted as a Docker volume. This ensures data persistence across container restarts.

```bash
# View data directory
ls -la data/

# Clear cached data (agent must be stopped)
docker compose down
rm -rf data/*
```

## Updates

To update the agent to a newer version:

```bash
# Stop current version
docker compose down

# Pull new version (or copy new binary)
# Update bin/sync-agent with the new binary

# Rebuild and start
docker compose up -d --build

# Verify version
docker compose logs | grep version
```

## Support

For more information and support:
- Documentation: https://docs.runyx.io
- Email: support@runyx.io
- Issues: Report issues through your support channel

## License

Copyright © Runyx. All rights reserved.
