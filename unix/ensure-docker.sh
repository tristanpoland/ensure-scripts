#!/usr/bin/env bash

# Script to ensure Docker is installed and running on UNIX-like systems
# Works on macOS and Linux

set -e

# Text formatting
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "🐳 Docker Installation & Startup Helper"
echo "======================================="

# Detect the operating system
detect_os() {
  case "$(uname -s)" in
    Darwin*)
      echo "macOS"
      ;;
    Linux*)
      if grep -q Microsoft /proc/version 2>/dev/null; then
        echo "WSL"
      else
        echo "Linux"
      fi
      ;;
    *)
      echo "Unknown"
      ;;
  esac
}

OS=$(detect_os)
echo -e "${YELLOW}Detected operating system: ${OS}${NC}"

# Check if Docker is installed
check_docker_installed() {
  if command -v docker &> /dev/null; then
    echo -e "${GREEN}✓ Docker is already installed${NC}"
    docker --version
    return 0
  else
    echo -e "${YELLOW}✗ Docker is not installed${NC}"
    return 1
  fi
}

# Install Docker on macOS
install_docker_macos() {
  echo "Installing Docker Desktop for macOS..."
  
  if command -v brew &> /dev/null; then
    echo "Using Homebrew to install Docker..."
    brew install --cask docker
  else
    echo "Homebrew not found, installing Docker using direct download..."
    
    # Create a temporary directory
    TMP_DIR=$(mktemp -d)
    cd "$TMP_DIR"
    
    # Download the latest Docker Desktop DMG
    curl -L -o docker.dmg "https://desktop.docker.com/mac/main/amd64/Docker.dmg"
    
    # Mount the DMG
    VOLUME=$(hdiutil attach docker.dmg | grep Volumes | awk '{print $3}')
    
    # Copy the app to Applications
    cp -R "$VOLUME/Docker.app" /Applications/
    
    # Unmount the DMG
    hdiutil detach "$VOLUME"
    
    # Clean up
    cd -
    rm -rf "$TMP_DIR"
    
    echo "Docker Desktop has been installed to your Applications folder"
  fi
}

# Install Docker on Linux
install_docker_linux() {
  echo "Installing Docker Engine for Linux..."
  
  # Update package index
  sudo apt-get update -y || sudo yum update -y || sudo dnf update -y || sudo zypper refresh || true
  
  # Install prerequisites
  sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release || 
  sudo yum install -y curl gnupg || 
  sudo dnf install -y curl gnupg || 
  sudo zypper install -y curl gnupg || true
  
  # Add Docker's official GPG key and repository based on distribution
  if [ -f /etc/debian_version ]; then
    # Debian/Ubuntu
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg 2>/dev/null || true
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null || true
    
    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
  elif [ -f /etc/redhat-release ]; then
    # RHEL/CentOS/Fedora
    sudo yum install -y yum-utils
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo || true
    sudo yum install -y docker-ce docker-ce-cli containerd.io || 
    sudo dnf install -y docker-ce docker-ce-cli containerd.io
  else
    # Generic approach for other distributions using convenience script
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
  fi
  
  # Add current user to the docker group
  sudo groupadd docker -f
  sudo usermod -aG docker "$USER"
  
  echo "Docker Engine has been installed"
  echo "You may need to log out and back in for group changes to take effect"
}

# Install Docker for WSL
install_docker_wsl() {
  echo "Installing Docker Engine for WSL..."
  install_docker_linux
  
  echo "Note: For the complete Docker Desktop experience on Windows, please install Docker Desktop for Windows."
}

# Check if Docker service is running
check_docker_running() {
  if docker info &> /dev/null; then
    echo -e "${GREEN}✓ Docker service is running${NC}"
    return 0
  else
    echo -e "${YELLOW}✗ Docker service is not running${NC}"
    return 1
  fi
}

# Start Docker service based on OS
start_docker() {
  case "$OS" in
    "macOS")
      echo "Starting Docker Desktop for macOS..."
      open -a Docker
      ;;
    "Linux")
      echo "Starting Docker service for Linux..."
      sudo systemctl start docker || sudo service docker start
      ;;
    "WSL")
      echo "Starting Docker service for WSL..."
      if sudo service docker status &> /dev/null; then
        sudo service docker start
      else
        echo "Docker service not found. Please ensure Docker Desktop for Windows is installed and WSL integration is enabled."
      fi
      ;;
    *)
      echo "Unknown operating system. Cannot start Docker service."
      exit 1
      ;;
  esac
}

# Wait for Docker to be up and responsive
wait_for_docker() {
  echo "Waiting for Docker to become responsive..."
  local max_attempts=30
  local attempt=1
  
  while [ $attempt -le $max_attempts ]; do
    if docker info &> /dev/null; then
      echo -e "${GREEN}✓ Docker is now running and responsive${NC}"
      return 0
    fi
    
    echo "Attempt $attempt/$max_attempts - Docker not yet responsive, waiting..."
    sleep 2
    attempt=$((attempt + 1))
  done
  
  echo -e "${RED}✗ Docker did not become responsive within the timeout period${NC}"
  return 1
}

# Main execution flow
main() {
  # Check if Docker is installed
  if ! check_docker_installed; then
    echo "Installing Docker..."
    
    case "$OS" in
      "macOS")
        install_docker_macos
        ;;
      "Linux")
        install_docker_linux
        ;;
      "WSL")
        install_docker_wsl
        ;;
      *)
        echo "Unknown operating system. Cannot install Docker."
        exit 1
        ;;
    esac
    
    # Re-check installation
    if ! check_docker_installed; then
      echo -e "${RED}Failed to install Docker. Please install manually.${NC}"
      exit 1
    fi
  fi
  
  # Check if Docker is running
  if ! check_docker_running; then
    echo "Starting Docker service..."
    start_docker
    
    # Wait for Docker to become responsive
    wait_for_docker || {
      echo -e "${RED}Failed to start Docker. Please start it manually.${NC}"
      exit 1
    }
  fi
  
  # Final verification
  if check_docker_running; then
    echo -e "${GREEN}==================================================${NC}"
    echo -e "${GREEN}Docker is successfully installed and running!${NC}"
    echo -e "${GREEN}==================================================${NC}"
    
    # Display basic Docker info
    echo -e "\nDocker version:"
    docker version --format '{{.Server.Version}}'
    
    echo -e "\nDocker info:"
    docker info --format '{{.ServerVersion}} running on {{.OperatingSystem}}'
    
    echo -e "\nTo verify installation, try running: docker run hello-world"
  else
    echo -e "${RED}Something went wrong. Docker is not running correctly.${NC}"
    exit 1
  fi
}

# Execute the main function
main
