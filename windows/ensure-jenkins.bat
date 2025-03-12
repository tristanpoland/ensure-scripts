@echo off
setlocal enabledelayedexpansion

echo Jenkins Installation ^& Startup Helper for Windows
echo ================================================

:: Check if running as Administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo This script requires Administrator privileges.
    echo Please run this script as Administrator.
    pause
    exit /b 1
)

:: Check if Java is installed (required for Jenkins)
echo Checking if Java is installed...
java -version >nul 2>&1
if %errorLevel% neq 0 (
    echo Java is required for Jenkins but is not installed.
    echo Installing Java...
    
    :: Create temporary directory
    set "tempDir=%TEMP%\JavaInstall_%RANDOM%"
    mkdir "%tempDir%"
    cd /d "%tempDir%"
    
    :: Download AdoptOpenJDK
    echo Downloading OpenJDK...
    powershell -Command "& {Invoke-WebRequest -Uri 'https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.18%%2B10/OpenJDK11U-jdk_x64_windows_hotspot_11.0.18_10.msi' -OutFile 'OpenJDK11.msi'}"
    
    if not exist "OpenJDK11.msi" (
        echo Failed to download Java.
        exit /b 1
    )
    
    :: Install Java
    echo Installing Java...
    start /wait msiexec /i OpenJDK11.msi /qn
    
    :: Clean up
    cd /d "%USERPROFILE%"
    rmdir /s /q "%tempDir%"
    
    :: Verify Java installation
    java -version >nul 2>&1
    if %errorLevel% neq 0 (
        echo Failed to install Java. Please install manually.
        pause
        exit /b 1
    ) else (
        echo Java installed successfully.
    )
) else (
    echo Java is already installed.
    java -version
)

:: Check if Jenkins is installed
echo Checking if Jenkins is installed...
set "jenkinsDir=C:\Program Files\Jenkins"
if exist "%jenkinsDir%\jenkins.war" (
    echo Jenkins is already installed.
) else (
    echo Jenkins is not installed. Installing now...
    
    :: Create Jenkins directory if it doesn't exist
    if not exist "%jenkinsDir%" (
        mkdir "%jenkinsDir%"
    )
    
    :: Create temporary directory
    set "tempDir=%TEMP%\JenkinsInstall_%RANDOM%"
    mkdir "%tempDir%"
    cd /d "%tempDir%"
    
    :: Download Jenkins
    echo Downloading Jenkins...
    powershell -Command "& {Invoke-WebRequest -Uri 'https://get.jenkins.io/war-stable/latest/jenkins.war' -OutFile 'jenkins.war'}"
    
    if not exist "jenkins.war" (
        echo Failed to download Jenkins.
        exit /b 1
    )
    
    :: Copy Jenkins to installation directory
    copy jenkins.war "%jenkinsDir%\"
    
    :: Create Jenkins service
    echo Installing Jenkins as a Windows service...
    
    :: Download WinSW (Windows Service Wrapper)
    powershell -Command "& {Invoke-WebRequest -Uri 'https://github.com/winsw/winsw/releases/download/v2.11.0/WinSW-x64.exe' -OutFile '%jenkinsDir%\jenkins-service.exe'}"
    
    :: Create service configuration file
    (
        echo ^<service^>
        echo   ^<id^>jenkins^</id^>
        echo   ^<name^>Jenkins^</name^>
        echo   ^<description^>Jenkins Automation Server^</description^>
        echo   ^<executable^>java^</executable^>
        echo   ^<arguments^>-Xrs -Xmx512m -jar "%jenkinsDir%\jenkins.war" --httpPort=8080^</arguments^>
        echo   ^<logmode^>rotate^</logmode^>
        echo ^</service^>
    ) > "%jenkinsDir%\jenkins-service.xml"
    
    :: Install service
    cd /d "%jenkinsDir%"
    jenkins-service.exe install
    
    :: Clean up
    cd /d "%USERPROFILE%"
    rmdir /s /q "%tempDir%"
    
    echo Jenkins has been installed as a Windows service.
)

:: Check if Jenkins service is running
echo Checking if Jenkins service is running...
sc query jenkins | find "RUNNING" > nul
if %errorLevel% equ 0 (
    echo Jenkins service is already running.
) else (
    echo Starting Jenkins service...
    net start jenkins
)

:: Wait for Jenkins to be responsive
echo Waiting for Jenkins to become responsive...
set max_attempts=60
set attempt=1

:jenkins_wait_loop
if %attempt% gtr %max_attempts% (
    echo Jenkins did not become responsive within the timeout period.
    echo This is normal for the first run as Jenkins initializes.
    goto :jenkins_initial_setup
)

powershell -Command "& {try { $response = Invoke-WebRequest -Uri 'http://localhost:8080' -TimeoutSec 1; exit 0 } catch { exit 1 }}"
if %errorLevel% equ 0 (
    echo Jenkins is now running and responsive.
    goto :jenkins_ready
)

echo Attempt %attempt%/%max_attempts% - Jenkins not yet responsive, waiting...
timeout /t 2 >nul
set /a attempt+=1
goto :jenkins_wait_loop

:jenkins_initial_setup
echo Jenkins is starting for the first time and needs to be configured.
echo Please follow these steps to complete the setup:

echo 1. Open http://localhost:8080 in your browser
echo 2. For the initial admin password, check the file at:
echo    %JENKINS_HOME%\secrets\initialAdminPassword
echo    or
echo    C:\Windows\System32\config\systemprofile\.jenkins\secrets\initialAdminPassword

echo 3. Follow the on-screen instructions to complete the Jenkins setup

goto :jenkins_info

:jenkins_ready
echo.
echo =================================================
echo Jenkins is successfully installed and running!
echo =================================================
echo.

:: Display Jenkins info
:jenkins_info
echo Jenkins URL: http://localhost:8080
echo Jenkins service name: jenkins
echo Jenkins installation directory: %jenkinsDir%

echo.
echo Jenkins service commands:
echo - net start jenkins: Start Jenkins service
echo - net stop jenkins: Stop Jenkins service
echo - sc query jenkins: Check Jenkins service status

echo.
echo For more information, visit: https://www.jenkins.io/doc/

:: Keep the window open
pause
