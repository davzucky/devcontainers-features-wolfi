@echo off
setlocal

set "TEMP_DIR=%TEMP%"
if "%TEMP_DIR%"=="" set "TEMP_DIR=/tmp"

set "TARGET_DIR=%TEMP_DIR%\cursor"
set "TARGET_AUTH=%TARGET_DIR%\auth.json"

set "SOURCE_AUTH=%USERPROFILE%\.config\cursor\auth.json"

if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%"

if exist "%SOURCE_AUTH%" (
    copy /Y "%SOURCE_AUTH%" "%TARGET_AUTH%" >nul
)

endlocal
