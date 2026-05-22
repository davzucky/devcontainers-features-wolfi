@echo off
setlocal

set "TEMP_DIR=%TEMP%"
if "%TEMP_DIR%"=="" set "TEMP_DIR=/tmp"

set "TARGET_ROOT=%TEMP_DIR%\pi"
set "TARGET_AGENT=%TARGET_ROOT%\agent"

if not "%PI_CODING_AGENT_DIR%"=="" (
    set "SOURCE_AGENT=%PI_CODING_AGENT_DIR%"
) else (
    set "SOURCE_AGENT=%USERPROFILE%\.pi\agent"
)

if not exist "%TARGET_ROOT%" mkdir "%TARGET_ROOT%"
if exist "%TARGET_AGENT%" rmdir /S /Q "%TARGET_AGENT%"
mkdir "%TARGET_AGENT%"

if not exist "%SOURCE_AGENT%" (
    echo Pi agent directory not found; created empty staging directory: %SOURCE_AGENT%
    exit /B 0
)

if exist "%SOURCE_AGENT%\settings.json" copy /Y "%SOURCE_AGENT%\settings.json" "%TARGET_AGENT%\settings.json" >nul
if exist "%SOURCE_AGENT%\auth.json" copy /Y "%SOURCE_AGENT%\auth.json" "%TARGET_AGENT%\auth.json" >nul
if exist "%SOURCE_AGENT%\models.json" copy /Y "%SOURCE_AGENT%\models.json" "%TARGET_AGENT%\models.json" >nul
if exist "%SOURCE_AGENT%\keybindings.json" copy /Y "%SOURCE_AGENT%\keybindings.json" "%TARGET_AGENT%\keybindings.json" >nul
if exist "%SOURCE_AGENT%\AGENTS.md" copy /Y "%SOURCE_AGENT%\AGENTS.md" "%TARGET_AGENT%\AGENTS.md" >nul
if exist "%SOURCE_AGENT%\SYSTEM.md" copy /Y "%SOURCE_AGENT%\SYSTEM.md" "%TARGET_AGENT%\SYSTEM.md" >nul
if exist "%SOURCE_AGENT%\APPEND_SYSTEM.md" copy /Y "%SOURCE_AGENT%\APPEND_SYSTEM.md" "%TARGET_AGENT%\APPEND_SYSTEM.md" >nul
if exist "%SOURCE_AGENT%\prompts" xcopy /E /I /Y "%SOURCE_AGENT%\prompts" "%TARGET_AGENT%\prompts" >nul
if exist "%SOURCE_AGENT%\skills" xcopy /E /I /Y "%SOURCE_AGENT%\skills" "%TARGET_AGENT%\skills" >nul
if exist "%SOURCE_AGENT%\extensions" xcopy /E /I /Y "%SOURCE_AGENT%\extensions" "%TARGET_AGENT%\extensions" >nul
if exist "%SOURCE_AGENT%\themes" xcopy /E /I /Y "%SOURCE_AGENT%\themes" "%TARGET_AGENT%\themes" >nul

endlocal
