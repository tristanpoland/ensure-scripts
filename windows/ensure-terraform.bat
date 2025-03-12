@echo off
setlocal enabledelayedexpansion

echo Terraform Installation Helper for Windows
echo ========================================

:: Check if running as Administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo This script requires Administrator privileges.
    echo Please run this script as Administrator.
    pause
    exit /b 1
)

:: Check if Terraform is installed
echo Checking if Terraform is already installed...
where terraform >nul 2>&1
if %errorLevel% equ 0 (
    echo Terraform is already installed.
    terraform version
    goto :terraform_ready
) else (
    echo Terraform is not installed. Installing now...
)

:: Create directory for Terraform if it doesn't exist
set "terraformDir=%ProgramFiles%\Terraform"
if not exist "%terraformDir%" (
    mkdir "%terraformDir%"
)

:: Create temporary directory for download
set "tempDir=%TEMP%\TerraformInstall_%RANDOM%"
mkdir "%tempDir%"
cd /d "%tempDir%"

:: Fetch the latest version
echo Fetching latest Terraform version...
powershell -Command "& {$latestVersion = (Invoke-RestMethod -Uri 'https://api.github.com/repos/hashicorp/terraform/releases/latest').tag_name; $latestVersion = $latestVersion.Replace('v', ''); Write-Output $latestVersion > version.txt}"
set /p TF_VERSION=<version.txt
echo Latest Terraform version: %TF_VERSION%

:: Download Terraform
echo Downloading Terraform %TF_VERSION%...
powershell -Command "& {Invoke-WebRequest -Uri 'https://releases.hashicorp.com/terraform/%TF_VERSION%/terraform_%TF_VERSION%_windows_amd64.zip' -OutFile 'terraform.zip'}"

if not exist "terraform.zip" (
    echo Failed to download Terraform.
    exit /b 1
)

:: Extract Terraform
echo Extracting Terraform...
powershell -Command "& {Expand-Archive -Path 'terraform.zip' -DestinationPath '%terraformDir%' -Force}"

:: Add Terraform to PATH
echo Adding Terraform to PATH...
setx PATH "%PATH%;%terraformDir%" /M

:: Clean up
cd /d "%USERPROFILE%"
rmdir /s /q "%tempDir%"

echo Terraform has been installed to %terraformDir%.
echo Please restart your command prompt to use Terraform.

:: Verify Terraform installation
:terraform_ready
echo.
echo =================================================
echo Terraform is ready to use!
echo =================================================
echo.

:: Display example Terraform commands
echo Example Terraform commands:
echo - terraform init: Initialize a Terraform working directory
echo - terraform plan: Show changes required by the current configuration
echo - terraform apply: Create or update infrastructure
echo - terraform destroy: Destroy previously-created infrastructure
echo.
echo For more information, visit: https://www.terraform.io/docs

:: Keep the window open
pause
