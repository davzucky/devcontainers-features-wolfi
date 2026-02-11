@echo off
setlocal

set "TEMP_DIR=%TEMP%"
if "%TEMP_DIR%"=="" set "TEMP_DIR=/tmp"

:trim_temp_dir
if "%TEMP_DIR:~-1%"=="\" (
    if /I not "%TEMP_DIR:~1,2%"==":\" (
        set "TEMP_DIR=%TEMP_DIR:~0,-1%"
        goto trim_temp_dir
    )
)
if "%TEMP_DIR:~-1%"=="/" (
    if /I not "%TEMP_DIR:~1,2%"==":/" (
        set "TEMP_DIR=%TEMP_DIR:~0,-1%"
        goto trim_temp_dir
    )
)

set "TARGET_DIR=%TEMP_DIR%\opencode"

if "%TARGET_DIR%"=="" (
    echo Refusing unsafe target path: %TARGET_DIR%
    exit /b 1
)
if "%TARGET_DIR%"=="\" (
    echo Refusing unsafe target path: %TARGET_DIR%
    exit /b 1
)
if "%TARGET_DIR%"=="/" (
    echo Refusing unsafe target path: %TARGET_DIR%
    exit /b 1
)
if "%TARGET_DIR%"=="." (
    echo Refusing unsafe target path: %TARGET_DIR%
    exit /b 1
)
if "%TARGET_DIR%"==".." (
    echo Refusing unsafe target path: %TARGET_DIR%
    exit /b 1
)

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
