@echo off
setlocal

set "TEMP_DIR=%TEMP%"
if "%TEMP_DIR%"=="" set "TEMP_DIR=%TMP%"
if "%TEMP_DIR%"=="" set "TEMP_DIR=%SystemRoot%\Temp"
if "%TEMP_DIR%"=="" set "TEMP_DIR=%USERPROFILE%\AppData\Local\Temp"

set "TARGET_DIR=%TEMP_DIR%\claude"
set "TARGET_SETTINGS=%TARGET_DIR%\settings.json"

if not "%CLAUDE_CONFIG_DIR%"=="" (
    set "SOURCE_SETTINGS=%CLAUDE_CONFIG_DIR%\settings.json"
) else (
    set "SOURCE_SETTINGS=%USERPROFILE%\.claude\settings.json"
)

if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%"

if exist "%SOURCE_SETTINGS%" (
    copy /Y "%SOURCE_SETTINGS%" "%TARGET_SETTINGS%" >nul
)

endlocal
