@echo off
setlocal

set "TEMP_DIR=%TEMP%"
if "%TEMP_DIR%"=="" set "TEMP_DIR=/tmp"

set "TARGET_DIR=%TEMP_DIR%\opencode"

if not "%OPENCODE_CONFIG_DIR%"=="" (
    set "SOURCE_DIR=%OPENCODE_CONFIG_DIR%"
) else (
    set "SOURCE_DIR=%USERPROFILE%\.local\share\opencode"
)

if exist "%SOURCE_DIR%\" (
    if exist "%TARGET_DIR%" (
        rmdir /S /Q "%TARGET_DIR%" >nul 2>&1
    )

    mklink /J "%TARGET_DIR%" "%SOURCE_DIR%" >nul 2>&1
    if errorlevel 1 (
        if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%"
    )
) else (
    if exist "%TARGET_DIR%" (
        rmdir /S /Q "%TARGET_DIR%" >nul 2>&1
    )
    if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%"
)

endlocal
