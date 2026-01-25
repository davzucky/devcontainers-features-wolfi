@echo off
setlocal

set "TEMP_DIR=%TEMP%"
if "%TEMP_DIR%"=="" set "TEMP_DIR=/tmp"

set "TARGET_DIR=%TEMP_DIR%\glab"
set "TARGET_CONFIG=%TARGET_DIR%\config.yml"
set "SOURCE_CONFIG=%USERPROFILE%\.config\glab-cli\config.yml"

if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%"

if exist "%SOURCE_CONFIG%" (
    copy /Y "%SOURCE_CONFIG%" "%TARGET_CONFIG%" >nul
)

endlocal
