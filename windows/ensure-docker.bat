@echo off
setlocal enabledelayedexpansion

echo Docker Installation ^& Startup Helper for Windows
echo ================================================

:: Check if running as Administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo This script requires Administrator privileges.
    echo Please run this script as Administrator.
    pause
    exit /b 1
)

:: Check if Docker is installed
echo Checking if Docker Desktop is installed...
set "dockerPath=%ProgramFiles%\Docker\Docker\Docker Desktop.exe"
if exist "%dockerPath%" (
    echo Docker Desktop is already installed.
) else (
    echo Docker Desktop is not installed. Installing now...
    
    :: Create temporary directory
    set "tempDir=%TEMP%\DockerInstall_%RANDOM%"
    mkdir "%tempDir%"
    cd /d "%tempDir%"
    
    :: Download Docker Desktop installer
    echo Downloading Docker Desktop installer...
    powershell -Command "& {Invoke-WebRequest -Uri 'https://desktop.docker.com/win/main/amd64/Docker%%20Desktop%%20Installer.exe' -OutFile 'DockerInstaller.exe'}"
    
    if not exist "DockerInstaller.exe" (
        echo Failed to download Docker Desktop installer.
        exit /b 1
    )
    
    :: Run the installer
    echo Running Docker Desktop installer...
    start /wait DockerInstaller.exe install --quiet
    
    :: Clean up
    cd /d "%USERPROFILE%"
    rmdir /s /q "%tempDir%"
    
    :: Verify installation
    if exist "%dockerPath%" (
        echo Docker Desktop has been successfully installed.
    ) else (
        echo Docker Desktop installation may have failed. Please check.
        pause
        exit /b 1
    )
)

:: Check if Docker service is running
echo Checking if Docker service is running...
tasklist /fi "imagename eq com.docker.service" | find "com.docker.service" > nul
if %errorLevel% equ 0 (
    echo Docker service is already running.
) else (
    echo Starting Docker Desktop...
    start "" "%dockerPath%"
)

:: Wait for Docker to be responsive
echo Waiting for Docker to become responsive...
set max_attempts=30
set attempt=1

:wait_loop
if %attempt% gtr %max_attempts% (
    echo Docker did not become responsive within the timeout period.
    pause
    exit /b 1
)

docker info >nul 2>&1
if %errorLevel% equ 0 (
    echo Docker is now running and responsive.
    goto :docker_ready
)

echo Attempt %attempt%/%max_attempts% - Docker not yet responsive, waiting...
timeout /t 2 >nul
set /a attempt+=1
goto :wait_loop

:docker_ready
echo.
echo =================================================
echo Docker is successfully installed and running!
echo =================================================
echo.

:: Display Docker info
echo Docker version:
docker version --format "{{.Server.Version}}" 2>nul

echo.
echo Docker info:
docker info --format "{{.ServerVersion}} running on {{.OperatingSystem}}" 2>nul

echo.
echo To verify installation, try running: docker run hello-world

:: Keep the window open
pause
