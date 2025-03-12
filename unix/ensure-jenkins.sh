#!/usr/bin/env bash

# Script to ensure Jenkins is installed and running on UNIX-like systems
# Works on macOS and Linux

set -e

# Text formatting
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "🔧 Jenkins Installation & Startup Helper"
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

# Check if Java is installed (required for Jenkins)
check_java_installed() {
  if command -v java &> /dev/null; then
    echo -e "${GREEN}✓ Java is already installed${NC}"
    java -version
    return 0
  else
    echo -e "${YELLOW}✗ Java is not installed${NC}"
    return 1
  fi
}

# Install Java on macOS
install_java_macos() {
  echo "Installing Java for macOS..."
  
  if command -v brew &> /dev/null; then
    echo "Using Homebrew to install AdoptOpenJDK..."
    brew tap adoptopenjdk/openjdk
    brew install --cask adoptopenjdk11
  else
    echo "Homebrew not found. Please install Homebrew first, or install Java manually."
    echo "You can install Homebrew with:"
    echo '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    exit 1
  fi
}

# Install Java on Linux
install_java_linux() {
  echo "Installing Java for Linux..."
  
  # Check for common package managers
  if command -v apt-get &> /dev/null; then
    echo "Using apt to install OpenJDK..."
    sudo apt-get update
    sudo apt-get install -y openjdk-11-jdk
  elif command -v yum &> /dev/null; then
    echo "Using yum to install OpenJDK..."
    sudo yum install -y java-11-openjdk-devel
  elif command -v dnf &> /dev/null; then
    echo "Using dnf to install OpenJDK..."
    sudo dnf install -y java-11-openjdk-devel
  else
    echo "No supported package manager found. Please install Java manually."
    exit 1
  fi
}

# Check if Jenkins is installed
check_jenkins_installed() {
  if [ "$OS" = "macOS" ]; then
    # Check if Jenkins is installed via Homebrew
    if brew list jenkins &> /dev/null; then
      echo -e "${GREEN}✓ Jenkins is already installed via Homebrew${NC}"
      return 0
    else
      echo -e "${YELLOW}✗ Jenkins is not installed${NC}"
      return 1
    fi
  else
    # Check if Jenkins is installed on Linux
    if command -v jenkins &> /dev/null || [ -f /usr/share/jenkins/jenkins.war ]; then
      echo -e "${GREEN}✓ Jenkins is already installed${NC}"
      return 0
    else
      echo -e "${YELLOW}✗ Jenkins is not installed${NC}"
      return 1
    fi
  fi
}

# Install Jenkins on macOS
install_jenkins_macos() {
  echo "Installing Jenkins for macOS..."
  
  if command -v brew &> /dev/null; then
    echo "Using Homebrew to install Jenkins..."
    brew install jenkins
  else
    echo "Homebrew not found. Please install Homebrew first."
    exit 1
  fi
}

# Install Jenkins on Linux
install_jenkins_linux() {
  echo "Installing Jenkins for Linux..."
  
  # Check for common package managers
  if command -v apt-get &> /dev/null; then
    echo "Using apt to install Jenkins..."
    
    # Add Jenkins repository key
    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
    
    # Add Jenkins repository
    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
    
    # Update and install Jenkins
    sudo apt-get update
    sudo apt-get install -y jenkins
    
  elif command -v yum &> /dev/null; then
    echo "Using yum to install Jenkins..."
    
    # Add Jenkins repository
    sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
    sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
    
    # Install Jenkins
    sudo yum install -y jenkins
    
  elif command -v dnf &> /dev/null; then
    echo "Using dnf to install Jenkins..."
    
    # Add Jenkins repository
    sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
    sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
    
    # Install Jenkins
    sudo dnf install -y jenkins
    
  else
    echo "No supported package manager found. Installing Jenkins via direct download..."
    
    # Create Jenkins directory
    sudo mkdir -p /opt/jenkins
    
    # Download Jenkins WAR file
    wget -O /tmp/jenkins.war https://get.jenkins.io/war-stable/latest/jenkins.war
    sudo mv /tmp/jenkins.war /opt/jenkins/
    
    # Create Jenkins user
    sudo useradd -r -m -d /var/lib/jenkins jenkins || true
    sudo chown -R jenkins:jenkins /opt/jenkins
    
    # Create systemd service file
    cat << EOF | sudo tee /etc/systemd/system/jenkins.service > /dev/null
[Unit]
Description=Jenkins Automation Server
After=network.target

[Service]
User=jenkins
ExecStart=/usr/bin/java -Djava.awt.headless=true -jar /opt/jenkins/jenkins.war --httpPort=8080
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
    
    # Reload systemd
    sudo systemctl daemon-reload
  fi
}

# Check if Jenkins service is running
check_jenkins_running() {
  if [ "$OS" = "macOS" ]; then
    # Check if Jenkins is running on macOS
    if brew services list | grep jenkins | grep started &> /dev/null; then
      echo -e "${GREEN}✓ Jenkins service is running${NC}"
      return 0
    else
      echo -e "${YELLOW}✗ Jenkins service is not running${NC}"
      return 1
    fi
  else
    # Check if Jenkins is running on Linux
    if systemctl is-active --quiet jenkins || service jenkins status &> /dev/null; then
      echo -e "${GREEN}✓ Jenkins service is running${NC}"
      return 0
    else
      echo -e "${YELLOW}✗ Jenkins service is not running${NC}"
      return 1
    fi
  fi
}

# Start Jenkins service
start_jenkins() {
  if [ "$OS" = "macOS" ]; then
    echo "Starting Jenkins service on macOS..."
    brew services start jenkins
  else
    echo "Starting Jenkins service on Linux..."
    sudo systemctl start jenkins || sudo service jenkins start
  fi
}

# Wait for Jenkins to be up and responsive
wait_for_jenkins() {
  echo "Waiting for Jenkins to become responsive..."
  local max_attempts=60
  local attempt=1
  
  while [ $attempt -le $max_attempts ]; do
    if curl -s -I http://localhost:8080 &> /dev/null; then
      echo -e "${GREEN}✓ Jenkins is now running and responsive${NC}"
      return 0
    fi
    
    echo "Attempt $attempt/$max_attempts - Jenkins not yet responsive, waiting..."
    sleep 2
    attempt=$((attempt + 1))
  done
  
  echo -e "${YELLOW}⚠ Jenkins did not become responsive within the timeout period${NC}"
  echo "This is normal for the first run as Jenkins initializes."
  return 1
}

# Main execution flow
main() {
  # Check if Java is installed
  if ! check_java_installed; then
    echo "Installing Java (required for Jenkins)..."
    
    case "$OS" in
      "macOS")
        install_java_macos
        ;;
      "Linux"|"WSL")
        install_java_linux
        ;;
      *)
        echo "Unknown operating system. Cannot install Java."
        exit 1
        ;;
    esac
    
    # Verify Java installation
    if ! check_java_installed; then
      echo -e "${RED}Failed to install Java. Please install Java manually.${NC}"
      exit 1
    fi
  fi
  
  # Check if Jenkins is installed
  if ! check_jenkins_installed; then
    echo "Installing Jenkins..."
    
    case "$OS" in
      "macOS")
        install_jenkins_macos
        ;;
      "Linux"|"WSL")
        install_jenkins_linux
        ;;
      *)
        echo "Unknown operating system. Cannot install Jenkins."
        exit 1
        ;;
    esac
    
    # Verify Jenkins installation
    if ! check_jenkins_installed; then
      echo -e "${RED}Failed to install Jenkins. Please install manually.${NC}"
      exit 1
    fi
  fi
  
  # Check if Jenkins is running
  if ! check_jenkins_running; then
    echo "Starting Jenkins service..."
    start_jenkins
    
    # Wait for Jenkins to become responsive
    wait_for_jenkins
    jenkins_responsive=$?
  else
    jenkins_responsive=0
  fi
  
  # Final message
  echo -e "${GREEN}==================================================${NC}"
  echo -e "${GREEN}Jenkins is successfully installed!${NC}"
  echo -e "${GREEN}==================================================${NC}"
  
  # Display Jenkins info
  echo -e "\nJenkins URL: http://localhost:8080"
  
  if [ "$jenkins_responsive" -eq 1 ]; then
    # Display initial setup instructions
    echo -e "\n${YELLOW}Jenkins is starting for the first time and needs to be configured.${NC}"
    echo "Please follow these steps to complete the setup:"
    echo "1. Open http://localhost:8080 in your browser"
    
    # Locate the initialAdminPassword
    if [ "$OS" = "macOS" ]; then
      echo "2. For the initial admin password, check the file at:"
      echo "   ~/.jenkins/secrets/initialAdminPassword"
    else
      echo "2. For the initial admin password, check the file at:"
      echo "   /var/lib/jenkins/secrets/initialAdminPassword"
      echo "   You can view it with: sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
    fi
    
    echo "3. Follow the on-screen instructions to complete the Jenkins setup"
  fi
  
  echo -e "\nFor more information, visit: https://www.jenkins.io/doc/"
}

# Execute the main function
main
