@echo off
REM skill-add.cmd — Import a skill
setlocal
set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%..\..\..\"

set "GIT_BASH="
if exist "C:\Program Files\Git\bin\bash.exe" (
    set "GIT_BASH=C:\Program Files\Git\bin\bash.exe"
) else (
    where bash >nul 2>&1 && set "GIT_BASH=bash"
)

if "%GIT_BASH%"=="" (
    echo Error: Git Bash not found.
    exit /b 1
)

"%GIT_BASH%" "%REPO_ROOT%scripts\skill-add.sh" %*
