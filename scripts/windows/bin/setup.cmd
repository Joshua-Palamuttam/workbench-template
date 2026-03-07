@echo off
REM setup.cmd — Windows entry point for workbench setup
REM Finds Git Bash and delegates to scripts/setup.sh

setlocal

set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%..\..\..\"

REM Find Git Bash
set "GIT_BASH="
if exist "C:\Program Files\Git\bin\bash.exe" (
    set "GIT_BASH=C:\Program Files\Git\bin\bash.exe"
) else if exist "C:\Program Files (x86)\Git\bin\bash.exe" (
    set "GIT_BASH=C:\Program Files (x86)\Git\bin\bash.exe"
) else (
    where bash >nul 2>&1 && set "GIT_BASH=bash"
)

if "%GIT_BASH%"=="" (
    echo Error: Git Bash not found. Install Git for Windows first.
    exit /b 1
)

"%GIT_BASH%" "%REPO_ROOT%scripts\setup.sh" %*
