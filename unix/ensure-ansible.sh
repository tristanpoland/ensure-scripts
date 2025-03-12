#!/usr/bin/env bash

# Script to ensure Ansible is installed on UNIX-like systems
# Works on macOS and Linux

set -e

# Text formatting
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "🎮 Ansible Installation Helper"
echo "============================="

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
        # Detect Linux distribution
        if [ -f /etc/os-release ]; then
          . /etc/os-release
          echo "$ID"
        elif [ -f /etc/debian_version ]; then
          echo "debian"
        elif [ -f /etc/redhat-release ]; then
          echo "rhel"
        else
          echo "linux"
        fi
      fi
      ;;
    *)
      echo "Unknown"
      ;;
  esac
}

OS=$(detect_os)
echo -e "${YELLOW}Detected operating system: ${OS}${NC}"

# Check if Ansible is installed
check_ansible_installed() {
  if command -v ansible &> /dev/null; then
    echo -e "${GREEN}✓ Ansible is already installed${NC}"
    ansible --version | head -n 1
    return 0
  else
    echo -e "${YELLOW}✗ Ansible is not installed${NC}"
    return 1
  fi
}

# Check if Python is installed
check_python_installed() {
  if command -v python3 &> /dev/null; then
    echo -e "${GREEN}✓ Python 3 is already installed${NC}"
    python3 --version
    return 0
  else
    echo -e "${YELLOW}✗ Python 3 is not installed${NC}"
    return 1
  fi
}

# Install Python if not installed
install_python() {
  echo "Installing Python 3..."
  
  case "$OS" in
    "macOS")
      if command -v brew &> /dev/null; then
        brew install python
      else
        echo "Homebrew is not installed. Please install Homebrew first."
        echo '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
        exit 1
      fi
      ;;
    "ubuntu"|"debian"|"WSL")
      sudo apt-get update
      sudo apt-get install -y python3 python3-pip
      ;;
    "fedora")
      sudo dnf install -y python3 python3-pip
      ;;
    "centos"|"rhel")
      sudo yum install -y python3 python3-pip
      ;;
    *)
      echo "Unknown operating system. Cannot install Python."
      exit 1
      ;;
  esac
}

# Install Ansible on macOS
install_ansible_macos() {
  echo "Installing Ansible for macOS..."
  
  if command -v brew &> /dev/null; then
    brew install ansible
  else
    # Install using pip if Homebrew is not available
    pip3 install --user ansible
    
    # Add pip bin directory to PATH if not already there
    if [[ ":$PATH:" != *":$HOME/Library/Python/3.*/bin:"* ]]; then
      echo 'export PATH="$PATH:$HOME/Library/Python/3.*/bin"' >> ~/.bash_profile
      echo "Please run 'source ~/.bash_profile' after this script completes."
    fi
  fi
}

# Install Ansible on Debian/Ubuntu
install_ansible_debian() {
  echo "Installing Ansible for Debian/Ubuntu..."
  
  # Add Ansible repository
  sudo apt-get update
  sudo apt-get install -y software-properties-common
  
  # Different commands depending on the exact distribution
  if [ "$OS" = "ubuntu" ]; then
    sudo apt-add-repository --yes --update ppa:ansible/ansible
  else
    # For Debian
    sudo apt-get install -y gnupg
    echo "deb http://ppa.launchpad.net/ansible/ansible/ubuntu focal main" | sudo tee /etc/apt/sources.list.d/ansible.list
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367
    sudo apt-get update
  fi
  
  # Install Ansible
  sudo apt-get install -y ansible
}

# Install Ansible on RHEL/CentOS
install_ansible_rhel() {
  echo "Installing Ansible for RHEL/CentOS..."
  
  # Enable EPEL repository if not already enabled
  sudo yum install -y epel-release || sudo dnf install -y epel-release
  
  # Install Ansible
  sudo yum install -y ansible || sudo dnf install -y ansible
}

# Install Ansible on Fedora
install_ansible_fedora() {
  echo "Installing Ansible for Fedora..."
  
  # Install Ansible
  sudo dnf install -y ansible
}

# Install Ansible using pip (fallback method)
install_ansible_pip() {
  echo "Installing Ansible using pip..."
  
  # Install pip if not already installed
  if ! command -v pip3 &> /dev/null; then
    if [ "$OS" = "macOS" ]; then
      curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
      python3 get-pip.py --user
      rm get-pip.py
    else
      sudo apt-get install -y python3-pip || sudo yum install -y python3-pip || sudo dnf install -y python3-pip
    fi
  fi
  
  # Install Ansible
  if [ "$OS" = "macOS" ]; then
    pip3 install --user ansible
  else
    sudo pip3 install ansible
  fi
}

# Create a simple test playbook
create_test_playbook() {
  echo "Creating a simple test playbook..."
  
  mkdir -p ~/ansible-test
  
  cat > ~/ansible-test/test-playbook.yml << EOF
---
- name: Ansible Test Playbook
  hosts: localhost
  connection: local
  gather_facts: true
  
  tasks:
    - name: Display system information
      debug:
        msg: "Running on {{ ansible_distribution }} {{ ansible_distribution_version }}"
    
    - name: Check uptime
      shell: uptime
      register: uptime_result
      changed_when: false
    
    - name: Display uptime
      debug:
        msg: "{{ uptime_result.stdout }}"
EOF
  
  echo -e "${GREEN}Test playbook created at ~/ansible-test/test-playbook.yml${NC}"
}

# Test Ansible installation
test_ansible() {
  echo "Testing Ansible installation..."
  
  if ansible --version &> /dev/null; then
    echo -e "${GREEN}✓ Ansible is working correctly${NC}"
    
    # Create and run a simple playbook to verify functionality
    create_test_playbook
    
    echo "Running test playbook..."
    ansible-playbook ~/ansible-test/test-playbook.yml
    
    return 0
  else
    echo -e "${RED}✗ Ansible installation test failed${NC}"
    return 1
  fi
}

# Main execution flow
main() {
  # Check if Python is installed
  if ! check_python_installed; then
    install_python
    
    # Verify Python installation
    if ! check_python_installed; then
      echo -e "${RED}Failed to install Python. Please install Python manually.${NC}"
      exit 1
    fi
  fi
  
  # Check if Ansible is installed
  if ! check_ansible_installed; then
    echo "Installing Ansible..."
    
    case "$OS" in
      "macOS")
        install_ansible_macos
        ;;
      "ubuntu"|"debian"|"WSL")
        install_ansible_debian
        ;;
      "fedora")
        install_ansible_fedora
        ;;
      "centos"|"rhel")
        install_ansible_rhel
        ;;
      *)
        echo "Using pip to install Ansible on unknown OS..."
        install_ansible_pip
        ;;
    esac
    
    # Verify Ansible installation
    if ! check_ansible_installed; then
      echo -e "${YELLOW}Failed to install Ansible using primary method. Trying pip installation...${NC}"
      install_ansible_pip
      
      if ! check_ansible_installed; then
        echo -e "${RED}Failed to install Ansible. Please install manually.${NC}"
        exit 1
      fi
    fi
  fi
  
  # Test Ansible installation
  test_ansible
  
  # Final message
  echo -e "${GREEN}==================================================${NC}"
  echo -e "${GREEN}Ansible is successfully installed and tested!${NC}"
  echo -e "${GREEN}==================================================${NC}"
  
  echo -e "\nAnsible version:"
  ansible --version | head -n 1
  
  echo -e "\nBasic Ansible commands:"
  echo "- ansible --version: Check Ansible version"
  echo "- ansible-playbook playbook.yml: Run an Ansible playbook"
  echo "- ansible-inventory --list: List inventory hosts"
  echo "- ansible-doc -l: List all available modules"
  
  echo -e "\nTest playbook created at: ~/ansible-test/test-playbook.yml"
  echo "Run it anytime with: ansible-playbook ~/ansible-test/test-playbook.yml"
  
  echo -e "\nFor more information, visit: https://docs.ansible.com/ansible/latest/user_guide/"
}

# Execute the main function
main
