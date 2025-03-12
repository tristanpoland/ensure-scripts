#!/usr/bin/env bash

# Script to ensure Terraform is installed on UNIX-like systems
# Works on macOS and Linux

set -e

# Text formatting
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "🏗️  Terraform Installation Helper"
echo "================================="

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

# Check if Terraform is installed
check_terraform_installed() {
  if command -v terraform &> /dev/null; then
    echo -e "${GREEN}✓ Terraform is already installed${NC}"
    terraform version
    return 0
  else
    echo -e "${YELLOW}✗ Terraform is not installed${NC}"
    return 1
  fi
}

# Install Terraform on macOS
install_terraform_macos() {
  echo "Installing Terraform for macOS..."
  
  if command -v brew &> /dev/null; then
    echo "Using Homebrew to install Terraform..."
    brew tap hashicorp/tap
    brew install hashicorp/tap/terraform
  else
    echo "Homebrew not found, installing Terraform using direct download..."
    install_terraform_binary
  fi
}

# Install Terraform on Linux
install_terraform_linux() {
  echo "Installing Terraform for Linux..."
  
  # Check for common package managers
  if command -v apt-get &> /dev/null; then
    echo "Using apt to install Terraform..."
    
    # Add HashiCorp GPG key
    wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    
    # Add HashiCorp repository
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    
    # Install Terraform
    sudo apt-get update
    sudo apt-get install -y terraform
    
  elif command -v yum &> /dev/null; then
    echo "Using yum to install Terraform..."
    
    # Add HashiCorp repository
    sudo yum install -y yum-utils
    sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
    
    # Install Terraform
    sudo yum install -y terraform
    
  elif command -v dnf &> /dev/null; then
    echo "Using dnf to install Terraform..."
    
    # Add HashiCorp repository
    sudo dnf install -y dnf-plugins-core
    sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
    
    # Install Terraform
    sudo dnf install -y terraform
    
  else
    echo "No supported package manager found, installing Terraform using direct download..."
    install_terraform_binary
  fi
}

# Install Terraform from binary
install_terraform_binary() {
  echo "Installing Terraform from binary..."
  
  # Create a temporary directory
  TMP_DIR=$(mktemp -d)
  cd "$TMP_DIR"
  
  # Get latest version
  LATEST_VERSION=$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
  echo "Latest Terraform version: $LATEST_VERSION"
  
  # Download appropriate package for the OS
  if [ "$OS" = "macOS" ]; then
    TERRAFORM_ZIP="terraform_${LATEST_VERSION}_darwin_amd64.zip"
  else
    TERRAFORM_ZIP="terraform_${LATEST_VERSION}_linux_amd64.zip"
  fi
  
  echo "Downloading $TERRAFORM_ZIP..."
  curl -LO "https://releases.hashicorp.com/terraform/${LATEST_VERSION}/${TERRAFORM_ZIP}"
  
  # Unzip the package
  unzip "$TERRAFORM_ZIP"
  
  # Move terraform to a directory in PATH
  echo "Installing Terraform to /usr/local/bin..."
  chmod +x terraform
  sudo mv terraform /usr/local/bin/
  
  # Clean up
  cd -
  rm -rf "$TMP_DIR"
  
  echo "Terraform binary installed successfully"
}

# Verify Terraform installation
verify_terraform() {
  echo "Verifying Terraform installation..."
  
  if command -v terraform &> /dev/null; then
    echo -e "${GREEN}✓ Terraform installed successfully${NC}"
    terraform version
    return 0
  else
    echo -e "${RED}✗ Terraform installation failed${NC}"
    return 1
  fi
}

# Main execution flow
main() {
  # Check if Terraform is installed
  if ! check_terraform_installed; then
    echo "Installing Terraform..."
    
    case "$OS" in
      "macOS")
        install_terraform_macos
        ;;
      "Linux"|"WSL")
        install_terraform_linux
        ;;
      *)
        echo "Unknown operating system. Cannot install Terraform."
        exit 1
        ;;
    esac
    
    # Verify installation
    if ! verify_terraform; then
      echo -e "${RED}Failed to install Terraform. Please install manually.${NC}"
      exit 1
    fi
  fi
  
  # Final message
  echo -e "${GREEN}==================================================${NC}"
  echo -e "${GREEN}Terraform is successfully installed!${NC}"
  echo -e "${GREEN}==================================================${NC}"
  
  # Display Terraform info
  echo -e "\nTerraform version:"
  terraform version
  
  echo -e "\nExample Terraform commands:"
  echo "- terraform init: Initialize a Terraform working directory"
  echo "- terraform plan: Show changes required by the current configuration"
  echo "- terraform apply: Create or update infrastructure"
  echo "- terraform destroy: Destroy previously-created infrastructure"
  
  echo -e "\nFor more information, visit: https://www.terraform.io/docs"
}

# Execute the main function
main
