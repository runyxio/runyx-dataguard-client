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

# Test WebUI connectivity
test_webui() {
    print_info "Testing WebUI connectivity..."

    local max_attempts=10
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 2>/dev/null | grep -q "200\|404\|301\|302"; then
            print_success "WebUI is responding on http://localhost:8080"
            return 0
        fi

        print_info "Waiting for WebUI to start (attempt $attempt/$max_attempts)..."
        sleep 2
        attempt=$((attempt + 1))
    done

    print_warning "WebUI did not respond after $max_attempts attempts"
    return 1
}

# Test metrics endpoint
test_metrics() {
    print_info "Testing Prometheus metrics endpoint..."

    local max_attempts=10
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if curl -s http://localhost:9090/metrics 2>/dev/null | grep -q "go_"; then
            print_success "Metrics endpoint is responding on http://localhost:9090/metrics"
            return 0
        fi

        print_info "Waiting for metrics endpoint (attempt $attempt/$max_attempts)..."
        sleep 2
        attempt=$((attempt + 1))
    done

    print_warning "Metrics endpoint did not respond after $max_attempts attempts"
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

    # Step 5: Check for config.yaml
    if [ ! -f config.yaml ]; then
        print_warning "config.yaml not found, copying from example..."
        cp config.example.yaml config.yaml
        print_success "Created config.yaml from config.example.yaml"
        print_info "Note: Configuration is primarily set via environment variables in .env"
    else
        print_success "config.yaml found"
    fi

    # Step 6: Create data directory
    mkdir -p data
    print_success "Data directory ready"

    # Step 7: Start the agent (only if Docker is OK)
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
            # Step 8: Wait for container to be ready
            echo ""
            print_info "Waiting for agent to initialize..."
            sleep 5

            # Step 9: Check container status
            echo ""
            print_info "Checking container status..."
            docker compose ps

            # Step 10: Test connectivity
            echo ""
            print_info "Testing connectivity..."
            echo ""

            test_metrics
            echo ""
            test_webui
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
        echo "Endpoints:"
        echo "  Metrics: http://localhost:9090/metrics"
        echo "  WebUI:   http://localhost:8080"
        echo ""
        print_info "To view logs, run: docker compose logs -f"
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
