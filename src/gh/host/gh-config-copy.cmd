@echo off
setlocal

set "TEMP_DIR=%TEMP%"
if "%TEMP_DIR%"=="" set "TEMP_DIR=%TMP%"
if "%TEMP_DIR%"=="" set "TEMP_DIR=%SystemRoot%\Temp"

set "TARGET_DIR=%TEMP_DIR%\gh"
set "TARGET_CONFIG=%TARGET_DIR%\hosts.yml"
set "SOURCE_CONFIG=%USERPROFILE%\.config\gh\hosts.yml"

if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%"

if exist "%SOURCE_CONFIG%" (
    copy /Y "%SOURCE_CONFIG%" "%TARGET_CONFIG%" >nul
)

endlocal
