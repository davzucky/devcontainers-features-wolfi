@echo off
setlocal

set "TEMP_DIR=%TEMP%"
if "%TEMP_DIR%"=="" set "TEMP_DIR=/tmp"

set "TARGET_DIR=%TEMP_DIR%\opencode"
set "TARGET_AUTH=%TARGET_DIR%\auth.json"

if not "%OPENCODE_CONFIG_DIR%"=="" (
    set "SOURCE_AUTH=%OPENCODE_CONFIG_DIR%\auth.json"
) else (
    set "SOURCE_AUTH=%USERPROFILE%\.local\share\opencode\auth.json"
)

if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%"

if exist "%SOURCE_AUTH%" (
    copy /Y "%SOURCE_AUTH%" "%TARGET_AUTH%" >nul
)

endlocal
