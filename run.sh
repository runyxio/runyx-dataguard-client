#!/bin/bash
# Runyx Sync Agent - Complete Setup and Start Script
# This script will install Docker if needed, start the agent, and verify connectivity

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    elif [ -f /etc/redhat-release ]; then
        echo "rhel"
    elif [ -f /etc/debian_version ]; then
        echo "debian"
    else
        echo "unknown"
    fi
}

# Check if Docker is installed
check_docker() {
    if command -v docker &> /dev/null; then
        print_success "Docker is already installed ($(docker --version))"
        return 0
    else
        print_warning "Docker is not installed"
        return 1
    fi
}

# Check if Docker Compose is installed
check_docker_compose() {
    if docker compose version &> /dev/null; then
        print_success "Docker Compose is available ($(docker compose version))"
        return 0
    elif command -v docker-compose &> /dev/null; then
        print_success "Docker Compose is available ($(docker-compose --version))"
        return 0
    else
        print_warning "Docker Compose is not installed"
        return 1
    fi
}

# Install Docker on Ubuntu/Debian
install_docker_debian() {
    print_info "Installing Docker on Debian/Ubuntu..."

    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg lsb-release

    # Add Docker's official GPG key
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/$1/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Set up the repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$1 \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker Engine
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    print_success "Docker installed successfully"
}

# Install Docker on CentOS/RHEL/Fedora
install_docker_rhel() {
    print_info "Installing Docker on RHEL/CentOS/Fedora..."

    sudo yum install -y yum-utils
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    print_success "Docker installed successfully"
}

# Install Docker on Amazon Linux
install_docker_amazon() {
    print_info "Installing Docker on Amazon Linux..."

    sudo yum update -y
    sudo yum install -y docker
    sudo usermod -aG docker $USER

    print_success "Docker installed successfully"
}

# Install Docker based on distribution
install_docker() {
    local distro=$(detect_distro)
    print_info "Detected distribution: $distro"

    case $distro in
        ubuntu|debian)
            install_docker_debian "$distro"
            ;;
        centos|rhel|rocky|almalinux)
            install_docker_rhel
            ;;
        fedora)
            install_docker_rhel
            ;;
        amzn)
            install_docker_amazon
            ;;
        *)
            print_error "Unsupported distribution: $distro"
            print_info "Please install Docker manually: https://docs.docker.com/engine/install/"
            exit 1
            ;;
    esac
}

# Start Docker service
start_docker_service() {
    print_info "Starting Docker service..."

    if command -v systemctl &> /dev/null; then
        sudo systemctl start docker
        sudo systemctl enable docker
        print_success "Docker service started and enabled"
    elif command -v service &> /dev/null; then
        sudo service docker start
        print_success "Docker service started"
    else
        print_warning "Could not start Docker service automatically"
    fi
}

# Setup Docker group permissions
setup_docker_permissions() {
    print_info "Checking Docker group permissions..."

    # Check if docker group exists, create if it doesn't
    if ! getent group docker > /dev/null 2>&1; then
        print_info "Creating docker group..."
        sudo groupadd docker
        print_success "Docker group created"
    fi

    # Check if current user is in docker group
    if ! groups $USER | grep -q docker; then
        print_warning "User '$USER' is not in the docker group"
        print_info "Adding user '$USER' to docker group..."

        sudo usermod -aG docker $USER

        print_success "User '$USER' added to docker group"
        print_warning "IMPORTANT: You need to log out and log back in for group changes to take effect"
        print_info "Alternatively, you can run: newgrp docker"
        echo ""

        # Ask user if they want to continue with current session or restart
        read -p "Do you want to try with the current session using 'newgrp docker'? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Attempting to apply group changes to current session..."
            exec sg docker "$0 $@"
        else
            print_warning "Please log out and log back in, then run this script again"
            exit 0
        fi
    else
        print_success "User '$USER' is already in the docker group"
    fi
}

# Check if Docker daemon is running
check_docker_running() {
    # Try docker info first (most reliable)
    if docker info &> /dev/null 2>&1; then
        print_success "Docker daemon is running"
        return 0
    fi

    # Check via systemctl if available
    if command -v systemctl &> /dev/null; then
        if systemctl is-active --quiet docker 2>/dev/null; then
            print_warning "Docker service is active but 'docker info' failed. May be a permissions issue."
            print_info "This is likely a Docker group permissions issue"
            # Return 1 to trigger permission setup
            return 1
        fi
    fi

    print_warning "Docker daemon is not running"
    return 1
}

# Test port connectivity
test_port() {
    local port=$1
    local name=$2

    print_info "Testing $name on port $port..."

    if command -v nc &> /dev/null; then
        if nc -z localhost $port 2>/dev/null; then
            print_success "$name is accessible on port $port"
            return 0
        fi
    elif command -v curl &> /dev/null; then
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:$port 2>/dev/null; then
            print_success "$name is accessible on port $port"
            return 0
        fi
    fi

    print_warning "$name is not accessible on port $port (may take a moment to start)"
    return 1
}

# Test agent health
test_agent_health() {
    print_info "Testing agent health..."

    local max_attempts=5
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        # Check if container is running and healthy
        local status=$(docker compose ps --format json | grep sync-agent | grep -o '"Status":"[^"]*"' | cut -d'"' -f4)

        if echo "$status" | grep -q "Up"; then
            print_success "Agent container is running and healthy"

            # Try to get metrics if available (optional, non-blocking)
            if curl -s --max-time 2 http://localhost:9090/metrics 2>/dev/null | grep -q "go_\|agent_"; then
                print_success "Metrics endpoint is responding on http://localhost:9090/metrics"
            else
                print_info "Metrics endpoint not yet available (this is optional)"
            fi

            return 0
        fi

        print_info "Waiting for agent to be healthy (attempt $attempt/$max_attempts)..."
        sleep 3
        attempt=$((attempt + 1))
    done

    print_warning "Agent health check timed out after $max_attempts attempts"
    return 1
}

# Main script
main() {
    echo ""
    echo "========================================="
    echo "  Runyx Sync Agent - Complete Setup"
    echo "========================================="
    echo ""

    # Check if running as root for Docker installation
    if [ "$EUID" -ne 0 ] && ! check_docker; then
        print_warning "This script may require sudo privileges to install Docker"
    fi

    # Step 1: Check and install Docker
    if ! check_docker; then
        print_info "Docker installation required"
        read -p "Do you want to install Docker automatically? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_docker
            # Setup permissions after fresh install
            echo ""
            setup_docker_permissions
        else
            print_error "Docker is required to run the agent. Please install Docker manually."
            exit 1
        fi
    fi

    # Step 2: Check Docker Compose
    if ! check_docker_compose; then
        print_error "Docker Compose is required but not found. Please install Docker Compose."
        exit 1
    fi

    # Step 3: Start Docker service if not running
    DOCKER_OK=true
    if ! check_docker_running; then
        start_docker_service
        sleep 3

        if ! check_docker_running; then
            # Docker is running but we can't connect - likely a permissions issue
            if command -v systemctl &> /dev/null && systemctl is-active --quiet docker 2>/dev/null; then
                echo ""
                print_warning "Docker is running but you don't have permission to use it"
                setup_docker_permissions
            else
                print_warning "Failed to start Docker daemon automatically."
                echo ""
                print_info "Please start Docker manually with one of these commands:"
                echo "  sudo systemctl start docker"
                echo "  sudo service docker start"
                echo ""
                print_info "After starting Docker, you can:"
                echo "  1. Run this script again: ./run.sh"
                echo "  2. Or run manually: docker compose up -d --build"
                echo ""
                DOCKER_OK=false
            fi
        fi
    fi

    # Step 4: Check for .env file
    echo ""
    print_info "Checking configuration files..."

    if [ ! -f .env ]; then
        print_error ".env file not found!"
        echo ""
        echo "Please create a .env file with the following variables:"
        echo "  AGENT_TOKEN=your-token-here"
        echo "  TENANT_ID=your-tenant-id"
        echo "  AGENT_ID=agent-001"
        echo ""
        echo "You can copy .env.example to get started:"
        echo "  cp .env.example .env"
        echo ""
        exit 1
    fi

    print_success ".env file found"

    # Step 5: Load environment variables from .env
    echo ""
    print_info "Loading environment variables from .env..."

    # Source the .env file
    set -a
    source .env
    set +a

    # Validate required variables
    if [ -z "$AGENT_TOKEN" ] || [ -z "$TENANT_ID" ] || [ -z "$AGENT_ID" ]; then
        print_error "Missing required environment variables in .env"
        echo ""
        echo "Required variables:"
        echo "  AGENT_TOKEN - Agent authentication token"
        echo "  TENANT_ID - Tenant ID"
        echo "  AGENT_ID - Agent ID"
        echo ""
        exit 1
    fi

    print_success "Environment variables loaded successfully"
    print_info "TENANT_ID: $TENANT_ID"
    print_info "AGENT_ID: $AGENT_ID"
    print_info "AGENT_TOKEN: ${AGENT_TOKEN:0:8}..." # Show only first 8 chars

    # Step 6: Create/update config.yaml with actual values
    echo ""
    print_info "Configuring agent..."

    if [ ! -f config.yaml ]; then
        print_warning "config.yaml not found, copying from example..."
        cp config.example.yaml config.yaml
        print_success "Created config.yaml from config.example.yaml"
    fi

    # Update config.yaml with actual credentials from .env
    print_info "Updating config.yaml with credentials from .env..."

    # Use sed to replace placeholders with actual values
    sed -i "s|agent_token:.*|agent_token: \"$AGENT_TOKEN\"|g" config.yaml
    sed -i "s|tenant_id:.*|tenant_id: \"$TENANT_ID\"|g" config.yaml
    sed -i "s|agent_id:.*|agent_id: \"$AGENT_ID\"|g" config.yaml

    # Update cloud URL if provided
    if [ ! -z "$AGENT_CLOUD_URL" ]; then
        sed -i "s|cloud_url:.*|cloud_url: \"$AGENT_CLOUD_URL\"|g" config.yaml
    fi

    # Update log level if provided
    if [ ! -z "$AGENT_LOG_LEVEL" ]; then
        sed -i "s|log_level:.*|log_level: \"$AGENT_LOG_LEVEL\"|g" config.yaml
    fi

    print_success "config.yaml updated with credentials"

    # Step 7: Create data directory and generate encryption keys
    mkdir -p data/keys
    print_success "Data directory ready"

    # Generate RSA keys for encryption if they don't exist
    if [ ! -f data/keys/agent-private.pem ]; then
        print_info "Generating RSA encryption keys for agent..."

        if command -v openssl &> /dev/null; then
            # Generate private key
            openssl genrsa -out data/keys/agent-private.pem 2048 2>/dev/null

            # Extract public key
            openssl rsa -in data/keys/agent-private.pem -pubout -out data/keys/agent-public.pem 2>/dev/null

            # Set proper permissions
            chmod 600 data/keys/agent-private.pem
            chmod 644 data/keys/agent-public.pem

            print_success "RSA encryption keys generated successfully"
            print_info "Private key: data/keys/agent-private.pem"
            print_info "Public key: data/keys/agent-public.pem"
        else
            print_warning "OpenSSL not found. Encryption keys not generated."
            print_info "Install OpenSSL to enable encryption: sudo apt-get install openssl"
            print_info "Or the agent will run without encryption (less secure)"
        fi
    else
        print_success "RSA encryption keys already exist"
    fi

    # Set proper ownership for agent user (uid 1000)
    print_info "Setting proper ownership for agent user..."
    chown -R 1000:1000 data
    print_success "Ownership set to agent user (uid 1000)"

    # Step 8: Start the agent (only if Docker is OK)
    if [ "$DOCKER_OK" = true ]; then
        echo ""
        print_info "Starting Runyx Sync Agent..."

        docker compose down 2>/dev/null || true
        docker compose up -d --build

        if [ $? -eq 0 ]; then
            print_success "Agent container started successfully!"
        else
            print_error "Failed to start agent container"
            print_warning "You can try starting manually: docker compose up -d --build"
            DOCKER_OK=false
        fi

        if [ "$DOCKER_OK" = true ]; then
            # Step 9: Wait for container to be ready
            echo ""
            print_info "Waiting for agent to initialize..."
            sleep 5

            # Step 10: Check container status
            echo ""
            print_info "Checking container status..."
            docker compose ps

            # Step 11: Test agent health and connectivity
            echo ""
            print_info "Testing agent health and connectivity..."
            echo ""

            test_agent_health

            # Check agent logs for connection status
            echo ""
            print_info "Checking agent connection logs..."
            if docker logs runyx-sync-agent --tail=10 2>&1 | grep -q "Connected to cloud successfully"; then
                print_success "Agent successfully connected to cloud (wss://dataguard.runyx.io/ws)"
            else
                print_warning "Could not confirm cloud connection in logs (check 'docker logs runyx-sync-agent')"
            fi
        fi
    else
        echo ""
        print_warning "Skipping agent startup due to Docker issues"
        print_info "Configuration files are ready. To start the agent manually:"
        echo ""
        echo "  1. Ensure Docker is running:"
        echo "     sudo systemctl start docker"
        echo ""
        echo "  2. Start the agent:"
        echo "     docker compose up -d --build"
        echo ""
        echo "  3. Check status:"
        echo "     docker compose ps"
        echo "     docker compose logs -f"
        echo ""
    fi

    # Final summary
    echo ""
    echo "========================================="
    if [ "$DOCKER_OK" = true ]; then
        echo "  Setup Complete!"
        echo "========================================="
        echo ""
        print_success "Runyx Sync Agent is running!"
        echo ""
        echo "Useful commands:"
        echo "  docker compose logs -f       # View logs"
        echo "  docker compose ps            # Check status"
        echo "  docker compose down          # Stop agent"
        echo "  docker compose restart       # Restart agent"
        echo ""
        echo "Agent Information:"
        echo "  Cloud URL: wss://dataguard.runyx.io/ws"
        echo "  Agent ID:  $AGENT_ID"
        echo "  Tenant ID: $TENANT_ID"
        echo ""
        print_info "To view live logs, run: docker compose logs -f"
        print_info "To check agent status in database, login to cloud dashboard"
    else
        echo "  Setup Partially Complete"
        echo "========================================="
        echo ""
        print_warning "Configuration files are ready, but Docker needs manual intervention"
        echo ""
        echo "To complete the setup:"
        echo ""
        echo "  1. Start Docker daemon:"
        echo "     sudo systemctl start docker"
        echo ""
        echo "  2. Run the agent:"
        echo "     docker compose up -d --build"
        echo ""
        echo "  3. Check if running:"
        echo "     docker compose ps"
        echo "     docker compose logs -f"
        echo ""
        print_info "Or simply run this script again after Docker is running: ./run.sh"
    fi
    echo ""
}

# Run main function
main
