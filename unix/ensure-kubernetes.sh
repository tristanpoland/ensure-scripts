#!/usr/bin/env bash

# Script to ensure Kubernetes is installed and running on UNIX-like systems
# Works on macOS and Linux (includes minikube for local development)

set -e

# Text formatting
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "☸️  Kubernetes Installation & Startup Helper"
echo "==========================================="

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

# Check if Docker is installed (required for Kubernetes)
check_docker_installed() {
  if command -v docker &> /dev/null; then
    echo -e "${GREEN}✓ Docker is already installed${NC}"
    docker --version
    return 0
  else
    echo -e "${RED}✗ Docker is required for Kubernetes but is not installed${NC}"
    echo "Please install Docker first"
    exit 1
  fi
}

# Check if Docker is running
check_docker_running() {
  if docker info &> /dev/null; then
    echo -e "${GREEN}✓ Docker service is running${NC}"
    return 0
  else
    echo -e "${YELLOW}✗ Docker service is not running${NC}"
    return 1
  fi
}

# Check if kubectl is installed
check_kubectl_installed() {
  if command -v kubectl &> /dev/null; then
    echo -e "${GREEN}✓ kubectl is already installed${NC}"
    kubectl version --client
    return 0
  else
    echo -e "${YELLOW}✗ kubectl is not installed${NC}"
    return 1
  fi
}

# Install kubectl on macOS
install_kubectl_macos() {
  echo "Installing kubectl for macOS..."
  
  if command -v brew &> /dev/null; then
    echo "Using Homebrew to install kubectl..."
    brew install kubectl
  else
    echo "Homebrew not found, installing kubectl using direct download..."
    
    # Create a temporary directory
    TMP_DIR=$(mktemp -d)
    cd "$TMP_DIR"
    
    # Download kubectl
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
    
    # Make kubectl executable
    chmod +x ./kubectl
    
    # Move kubectl to a directory in PATH
    sudo mv ./kubectl /usr/local/bin/kubectl
    
    # Clean up
    cd -
    rm -rf "$TMP_DIR"
  fi
}

# Install kubectl on Linux
install_kubectl_linux() {
  echo "Installing kubectl for Linux..."
  
  # Download kubectl
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  
  # Make kubectl executable
  chmod +x ./kubectl
  
  # Move kubectl to a directory in PATH
  sudo mv ./kubectl /usr/local/bin/kubectl
}

# Check if minikube is installed
check_minikube_installed() {
  if command -v minikube &> /dev/null; then
    echo -e "${GREEN}✓ minikube is already installed${NC}"
    minikube version
    return 0
  else
    echo -e "${YELLOW}✗ minikube is not installed${NC}"
    return 1
  fi
}

# Install minikube on macOS
install_minikube_macos() {
  echo "Installing minikube for macOS..."
  
  if command -v brew &> /dev/null; then
    echo "Using Homebrew to install minikube..."
    brew install minikube
  else
    echo "Homebrew not found, installing minikube using direct download..."
    
    # Create a temporary directory
    TMP_DIR=$(mktemp -d)
    cd "$TMP_DIR"
    
    # Download minikube
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-darwin-amd64
    
    # Make minikube executable and move to PATH
    chmod +x minikube-darwin-amd64
    sudo mv minikube-darwin-amd64 /usr/local/bin/minikube
    
    # Clean up
    cd -
    rm -rf "$TMP_DIR"
  fi
}

# Install minikube on Linux
install_minikube_linux() {
  echo "Installing minikube for Linux..."
  
  # Download minikube
  curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
  
  # Make minikube executable and move to PATH
  chmod +x minikube-linux-amd64
  sudo mv minikube-linux-amd64 /usr/local/bin/minikube
}

# Start minikube
start_minikube() {
  echo "Starting minikube..."
  
  # Check if minikube is already running
  if minikube status | grep -q "Running"; then
    echo -e "${GREEN}✓ minikube is already running${NC}"
  else
    # Start minikube with Docker driver
    minikube start --driver=docker
    
    # Enable ingress addon
    echo "Enabling Kubernetes ingress..."
    minikube addons enable ingress
  fi
}

# Check if minikube is running
check_kubernetes_running() {
  if kubectl cluster-info &> /dev/null; then
    echo -e "${GREEN}✓ Kubernetes is running${NC}"
    return 0
  else
    echo -e "${YELLOW}✗ Kubernetes is not running${NC}"
    return 1
  fi
}

# Wait for Kubernetes to be up and responsive
wait_for_kubernetes() {
  echo "Waiting for Kubernetes to become responsive..."
  local max_attempts=30
  local attempt=1
  
  while [ $attempt -le $max_attempts ]; do
    if kubectl cluster-info &> /dev/null; then
      echo -e "${GREEN}✓ Kubernetes is now running and responsive${NC}"
      return 0
    fi
    
    echo "Attempt $attempt/$max_attempts - Kubernetes not yet responsive, waiting..."
    sleep 2
    attempt=$((attempt + 1))
  done
  
  echo -e "${RED}✗ Kubernetes did not become responsive within the timeout period${NC}"
  return 1
}

# Main execution flow
main() {
  # Check if Docker is installed and running
  check_docker_installed
  
  if ! check_docker_running; then
    echo -e "${RED}Docker is not running. Please start Docker first.${NC}"
    exit 1
  fi
  
  # Install kubectl if not present
  if ! check_kubectl_installed; then
    echo "Installing kubectl..."
    
    case "$OS" in
      "macOS")
        install_kubectl_macos
        ;;
      "Linux"|"WSL")
        install_kubectl_linux
        ;;
      *)
        echo "Unknown operating system. Cannot install kubectl."
        exit 1
        ;;
    esac
    
    # Verify kubectl installation
    if ! check_kubectl_installed; then
      echo -e "${RED}Failed to install kubectl. Please install manually.${NC}"
      exit 1
    fi
  fi
  
  # Check and install minikube for local cluster
  if ! check_minikube_installed; then
    echo "Installing minikube..."
    
    case "$OS" in
      "macOS")
        install_minikube_macos
        ;;
      "Linux"|"WSL")
        install_minikube_linux
        ;;
      *)
        echo "Unknown operating system. Cannot install minikube."
        exit 1
        ;;
    esac
    
    # Verify minikube installation
    if ! check_minikube_installed; then
      echo -e "${RED}Failed to install minikube. Please install manually.${NC}"
      exit 1
    fi
  fi
  
  # Start minikube if Kubernetes is not running
  if ! check_kubernetes_running; then
    start_minikube
    
    # Wait for Kubernetes to become responsive
    wait_for_kubernetes || {
      echo -e "${RED}Failed to start Kubernetes. Please check minikube status.${NC}"
      exit 1
    }
  fi
  
  # Final verification
  if check_kubernetes_running; then
    echo -e "${GREEN}==================================================${NC}"
    echo -e "${GREEN}Kubernetes is successfully installed and running!${NC}"
    echo -e "${GREEN}==================================================${NC}"
    
    # Display Kubernetes info
    echo -e "\nKubernetes cluster info:"
    kubectl cluster-info
    
    echo -e "\nKubernetes version:"
    kubectl version --short
    
    echo -e "\nKubernetes nodes:"
    kubectl get nodes
    
    echo -e "\nTo access the Kubernetes dashboard, run: minikube dashboard"
  else
    echo -e "${RED}Something went wrong. Kubernetes is not running correctly.${NC}"
    exit 1
  fi
}

# Execute the main function
main
