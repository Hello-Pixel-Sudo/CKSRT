@echo off
setlocal enabledelayedexpansion
title CKSRT - Registry Blocker

set "TARGET_DIR=C:\Program Files (x86)\NetSupport\classroom.cloud"
set "CACHE_FILE=%~dp0blocked_cache.txt"
set "DEADDEBUG=C:\Windows\System32\NonExistentDebugger.exe"

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Run as Administrator.
    pause
    exit /b
)

echo ==========================================
echo  Pre-Scanning Directory...
echo ==========================================

:: Count how many EXEs are in the folder
set "TOTAL_EXES=0"
for /f %%C in ('dir /s /b /a-d "%TARGET_DIR%\*.exe" 2^>nul ^| find /c /v ""') do set "TOTAL_EXES=%%C"

echo [INFO] Total .exe files found: !TOTAL_EXES!
echo.
echo ==========================================
echo  Applying Registry Execution Blocks...
echo ==========================================

if not exist "%CACHE_FILE%" type nul > "%CACHE_FILE%"
set "COUNT=0"

:: 1. Scan and apply IFEO Registry blocks
for /f "usebackq delims=" %%F in (`dir /s /b /a-d "%TARGET_DIR%\*.exe" 2^>nul`) do (
    findstr /x /c:"%%F" "%CACHE_FILE%" >nul
    if !errorLevel! neq 0 (
        echo [BLOCKING] %%~nxF
        
        :: Changed to point to a non-existent file to guarantee crash
        reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\%%~nxF" /v Debugger /t REG_SZ /d "%DEADDEBUG%" /f >nul 2>&1
        
        if !errorLevel! equ 0 (
            echo %%F >> "%CACHE_FILE%"
            set /a COUNT+=1
        ) else (
            echo [FAILED] Registry locked for %%~nxF
        )
    )
)

:: 2. Sniper Kill
echo.
echo [INFO] Terminating running processes from target folder...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-Process | Where-Object { $_.Path -like '*classroom.cloud*' } | Stop-Process -Force" >nul 2>&1

echo.
echo ==========================================
echo  DONE! !COUNT! files blocked from running.
echo ==========================================
pause