@echo off
setlocal enabledelayedexpansion

echo Ansible Installation Helper for Windows
echo ======================================

:: Check if running as Administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo This script requires Administrator privileges.
    echo Please run this script as Administrator.
    pause
    exit /b 1
)

echo Note: Ansible is primarily designed for Linux/Unix systems.
echo On Windows, we'll install it using WSL (Windows Subsystem for Linux).

:: Check if WSL is installed
echo Checking if WSL is installed...
wsl --list >nul 2>&1
if %errorLevel% neq 0 (
    echo WSL is not installed. Installing WSL...
    
    :: Enable WSL feature
    echo Enabling Windows Subsystem for Linux feature...
    powershell -Command "& {Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart}"
    
    :: Enable Virtual Machine Platform feature
    echo Enabling Virtual Machine Platform feature...
    powershell -Command "& {Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart}"
    
    echo WSL features have been enabled.
    echo Please restart your computer and run this script again.
    pause
    exit /b 0
)

:: Check if WSL 2 is set as default
echo Checking WSL version...
for /f "tokens=*" %%a in ('wsl --status 2^>^&1 ^| findstr "Default Version"') do (
    set status_line=%%a
)

echo !status_line! | findstr "2" >nul
if %errorLevel% neq 0 (
    echo Setting WSL 2 as the default version...
    wsl --set-default-version 2
)

:: Check if Ubuntu is installed in WSL
echo Checking if Ubuntu is installed in WSL...
wsl --list | findstr "Ubuntu" >nul
if %errorLevel% neq 0 (
    echo Ubuntu is not installed in WSL. Installing Ubuntu...
    
    :: Create temporary directory
    set "tempDir=%TEMP%\WSLInstall_%RANDOM%"
    mkdir "%tempDir%"
    cd /d "%tempDir%"
    
    :: Download Ubuntu from Microsoft Store
    echo Downloading Ubuntu for WSL...
    powershell -Command "& {Invoke-WebRequest -Uri 'https://aka.ms/wslubuntu2204' -OutFile 'Ubuntu.appx' -UseBasicParsing}"
    
    :: Extract and install
    echo Installing Ubuntu for WSL...
    powershell -Command "& {Add-AppxPackage -Path 'Ubuntu.appx'}"
    
    :: Clean up
    cd /d "%USERPROFILE%"
    rmdir /s /q "%tempDir%"
    
    echo Ubuntu has been installed in WSL.
    echo Please complete the Ubuntu setup by running: ubuntu
    echo After setting up Ubuntu, run this script again to install Ansible.
    pause
    exit /b 0
)

:: Install Ansible inside WSL Ubuntu
echo Installing Ansible inside WSL Ubuntu...
wsl -d Ubuntu -e bash -c "
    # Update package lists
    sudo apt-get update

    # Install Python and pip if not installed
    sudo apt-get install -y python3 python3-pip

    # Install Ansible using pip
    sudo pip3 install ansible

    # Verify installation
    ansible --version
"

if %errorLevel% neq 0 (
    echo Failed to install Ansible in WSL Ubuntu.
    pause
    exit /b 1
)

echo.
echo =================================================
echo Ansible is now installed in WSL Ubuntu!
echo =================================================
echo.

:: Display how to use Ansible from Windows
echo To use Ansible from Windows:
echo.
echo 1. Open a command prompt and enter WSL:
echo    wsl
echo.
echo 2. Run Ansible commands within the WSL environment:
echo    ansible --version
echo    ansible-playbook playbook.yml
echo.
echo Note: Ansible will be running in the Linux environment.
echo      Windows paths can be accessed from WSL using /mnt/c/...
echo.
echo For more information, visit: https://docs.ansible.com/ansible/latest/installation_guide/

:: Keep the window open
pause
