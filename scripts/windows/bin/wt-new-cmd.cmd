@echo off
REM wt-new-cmd — Generate a .cmd wrapper for a worktree .sh script
REM
REM Usage:
REM   wt-new-cmd <script-name>              Simple wrapper (no workdir)
REM   wt-new-cmd <script-name> --workdir    Wrapper that passes current directory
REM
REM Examples:
REM   wt-new-cmd wt-migrate        Creates wt-migrate.cmd (simple)
REM   wt-new-cmd wt-deploy --workdir   Creates wt-deploy.cmd (with workdir)
REM
REM The generated .cmd calls wt-config.cmd which provides:
REM   GIT_BASH, SCRIPTS_PATH, WORKTREE_ROOT, WORKTREE_SCRIPTS, WORKBENCH_ROOT

setlocal enabledelayedexpansion

if "%~1"=="" (
    echo Usage: wt-new-cmd ^<script-name^> [--workdir]
    echo.
    echo   wt-new-cmd wt-migrate            Simple wrapper
    echo   wt-new-cmd wt-deploy --workdir   Wrapper that passes current directory
    exit /b 1
)

set "NAME=%~1"
set "WORKDIR="
if /i "%~2"=="--workdir" set "WORKDIR=1"

set "OUT=%~dp0%NAME%.cmd"

if exist "%OUT%" (
    echo Error: %OUT% already exists.
    exit /b 1
)

REM Check that the .sh script exists
if not exist "%~dp0..\%NAME%.sh" (
    echo Warning: scripts\windows\%NAME%.sh not found. Creating .cmd anyway.
)

if defined WORKDIR (
    (
        echo @echo off
        echo setlocal enabledelayedexpansion
        echo call "%%~dp0wt-config.cmd"
        echo set "ORIG_DIR=%%CD%%"
        echo set "ORIG_DIR=!ORIG_DIR:\=/!"
        echo set "ORIG_DIR=!ORIG_DIR:C:/=/c/!"
        echo set "ORIG_DIR=!ORIG_DIR:D:/=/d/!"
        echo.
        echo "%%GIT_BASH%%" "%%SCRIPTS_PATH%%/%NAME%.sh" %%* --workdir "!ORIG_DIR!"
        echo endlocal
    ) > "%OUT%"
) else (
    (
        echo @echo off
        echo call "%%~dp0wt-config.cmd"
        echo "%%GIT_BASH%%" "%%SCRIPTS_PATH%%/%NAME%.sh" %%*
    ) > "%OUT%"
)

echo Created %OUT%
