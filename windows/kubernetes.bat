@echo off
setlocal enabledelayedexpansion

echo Kubernetes Installation ^& Startup Helper for Windows
echo ===================================================

:: Check if running as Administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo This script requires Administrator privileges.
    echo Please run this script as Administrator.
    pause
    exit /b 1
)

:: Check if Docker is installed (required for Kubernetes)
echo Checking if Docker Desktop is installed...
set "dockerPath=%ProgramFiles%\Docker\Docker\Docker Desktop.exe"
if not exist "%dockerPath%" (
    echo Docker Desktop is required for Kubernetes but is not installed.
    echo Please install Docker Desktop first.
    pause
    exit /b 1
)

:: Check if Docker is running
echo Checking if Docker service is running...
docker info >nul 2>&1
if %errorLevel% neq 0 (
    echo Starting Docker Desktop...
    start "" "%dockerPath%"
    
    :: Wait for Docker to be responsive
    echo Waiting for Docker to start...
    set max_attempts=30
    set attempt=1
    
    :docker_wait_loop
    if %attempt% gtr %max_attempts% (
        echo Docker did not become responsive within the timeout period.
        pause
        exit /b 1
    )
    
    docker info >nul 2>&1
    if %errorLevel% equ 0 (
        echo Docker is now running.
    ) else (
        timeout /t 2 >nul
        set /a attempt+=1
        goto :docker_wait_loop
    )
)

:: Check if Kubernetes is already enabled in Docker Desktop
echo Checking if Kubernetes is enabled in Docker Desktop...
docker info | findstr "Kubernetes" | findstr "running" >nul
if %errorLevel% equ 0 (
    echo Kubernetes is already running in Docker Desktop.
) else (
    echo Kubernetes needs to be enabled in Docker Desktop.
    echo Please perform the following steps:
    echo 1. Right-click Docker Desktop icon in system tray
    echo 2. Select "Settings"
    echo 3. Go to "Kubernetes" tab
    echo 4. Check "Enable Kubernetes"
    echo 5. Click "Apply & Restart"
    echo.
    echo Press any key after enabling Kubernetes in Docker Desktop...
    pause >nul
)

:: Install kubectl CLI
echo Checking for kubectl...
where kubectl >nul 2>&1
if %errorLevel% equ 0 (
    echo kubectl is already installed.
    kubectl version --client
) else (
    echo Installing kubectl...
    
    :: Create temporary directory
    set "tempDir=%TEMP%\KubeInstall_%RANDOM%"
    mkdir "%tempDir%"
    cd /d "%tempDir%"
    
    :: Download kubectl
    echo Downloading kubectl...
    powershell -Command "& {Invoke-WebRequest -Uri 'https://dl.k8s.io/release/v1.28.0/bin/windows/amd64/kubectl.exe' -OutFile 'kubectl.exe'}"
    
    if not exist "kubectl.exe" (
        echo Failed to download kubectl.
        exit /b 1
    )
    
    :: Create kubectl directory if it doesn't exist
    if not exist "%USERPROFILE%\.kubectl" (
        mkdir "%USERPROFILE%\.kubectl"
    )
    
    :: Move kubectl to user directory and add to PATH
    move kubectl.exe "%USERPROFILE%\.kubectl\"
    
    :: Add to PATH if not already there
    echo Adding kubectl to PATH...
    setx PATH "%PATH%;%USERPROFILE%\.kubectl" /M
    
    :: Clean up
    cd /d "%USERPROFILE%"
    rmdir /s /q "%tempDir%"
    
    echo kubectl has been installed. Please restart your command prompt to use it.
)

:: Wait for Kubernetes to be fully running
echo Checking if Kubernetes is running...
set max_attempts=30
set attempt=1

:k8s_wait_loop
if %attempt% gtr %max_attempts% (
    echo Kubernetes did not become responsive within the timeout period.
    pause
    exit /b 1
)

kubectl cluster-info >nul 2>&1
if %errorLevel% equ 0 (
    echo Kubernetes is now running and responsive.
    goto :k8s_ready
)

echo Attempt %attempt%/%max_attempts% - Kubernetes not yet responsive, waiting...
timeout /t 2 >nul
set /a attempt+=1
goto :k8s_wait_loop

:k8s_ready
echo.
echo =================================================
echo Kubernetes is successfully installed and running!
echo =================================================
echo.

:: Display Kubernetes info
echo Kubernetes cluster info:
kubectl cluster-info

echo.
echo Kubernetes version:
kubectl version --short

echo.
echo To verify installation, try running: kubectl get nodes

:: Keep the window open
pause
