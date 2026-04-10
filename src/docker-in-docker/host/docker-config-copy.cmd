@echo off
setlocal

set "TEMP_DIR=%TEMP%"
if "%TEMP_DIR%"=="" set "TEMP_DIR=%TMP%"
if "%TEMP_DIR%"=="" set "TEMP_DIR=%SystemRoot%\Temp"

set "TARGET_DIR=%TEMP_DIR%\docker-in-docker"
set "TARGET_CONFIG=%TARGET_DIR%\config.json"

if not "%DOCKER_CONFIG%"=="" (
    set "SOURCE_CONFIG=%DOCKER_CONFIG%\config.json"
) else (
    set "SOURCE_CONFIG=%USERPROFILE%\.docker\config.json"
)

if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%"

if exist "%SOURCE_CONFIG%" (
    copy /Y "%SOURCE_CONFIG%" "%TARGET_CONFIG%" >nul
)

endlocal
