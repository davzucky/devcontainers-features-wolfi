@echo off
setlocal

set "TEMP_DIR=%TEMP%"
if "%TEMP_DIR%"=="" set "TEMP_DIR=/tmp"

set "TARGET_ROOT=%TEMP_DIR%\agent-skills"
set "TARGET_SKILLS=%TARGET_ROOT%\skills"
set "SOURCE_SKILLS=%USERPROFILE%\.agents\skills"

if not exist "%TARGET_ROOT%" mkdir "%TARGET_ROOT%"
if exist "%TARGET_SKILLS%" rmdir /S /Q "%TARGET_SKILLS%"
mkdir "%TARGET_SKILLS%"

if not exist "%SOURCE_SKILLS%" (
    echo Shared agent skills directory not found; created empty staging directory: %SOURCE_SKILLS%
    exit /B 0
)

xcopy /E /I /Y "%SOURCE_SKILLS%" "%TARGET_SKILLS%" >nul

endlocal
