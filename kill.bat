@echo off
setlocal enabledelayedexpansion
title CKSRT - Restore System

set "TARGET_DIR=C:\Program Files (x86)\NetSupport\classroom.cloud"
set "CACHE_FILE=%~dp0blocked_cache.txt"

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Run as Administrator.
    pause
    exit /b
)

echo ==========================================
echo  Restoring System...
echo ==========================================

:: 1. Restore folder permissions (Remove the Deny Execute rule)
if exist "%TARGET_DIR%" (
    echo [ACL] Restoring permissions...
    icacls "%TARGET_DIR%" /remove:d *S-1-1-0 /T /C /Q >nul 2>&1
)

:: 2. Remove the IFEO Registry blocks
echo [IFEO] Removing registry blocks...
if exist "%CACHE_FILE%" (
    :: If cache exists, remove exactly what is in the cache
    for /f "usebackq delims=" %%F in ("%CACHE_FILE%") do (
        reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\%%~nxF" /f >nul 2>&1
    )
    :: Delete the cache file so the next run starts fresh
    del /f /q "%CACHE_FILE%" >nul 2>&1
) else (
    :: Fallback: If cache is missing, strip all EXEs in the folder
    for /f "usebackq delims=" %%F in (`dir /s /b /a-d "%TARGET_DIR%\*.exe" 2^>nul`) do (
        reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\%%~nxF" /f >nul 2>&1
    )
)

:: 3. Try to start the service back up (Optional, but helpful)
echo [SERVICE] Attempting to restart the agent...
sc start "classroom.cloud Student" >nul 2>&1

echo.
echo ==========================================
echo  DONE! System fully restored.
echo ==========================================
pause