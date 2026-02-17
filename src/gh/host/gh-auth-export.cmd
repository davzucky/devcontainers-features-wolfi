@echo off
setlocal

set "TEMP_DIR=%TEMP%"
if "%TEMP_DIR%"=="" set "TEMP_DIR=%TMP%"
if "%TEMP_DIR%"=="" set "TEMP_DIR=%SystemRoot%\Temp"

set "TARGET_DIR=%TEMP_DIR%\gh"
set "TARGET_EXPORT=%TARGET_DIR%\auth-status.tsv"

if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%"

where gh >nul 2>nul
if errorlevel 1 goto :end

gh auth status --json hosts --show-token --jq ".hosts | to_entries[] | .key as $host | (.value | if type == \"array\" then .[] else . end) | (.oauth_token // .token // \"\") as $token | select($token != \"\") | [$host, $token] | @tsv" > "%TARGET_EXPORT%" 2>nul

if exist "%TARGET_EXPORT%" (
    icacls "%TARGET_EXPORT%" /inheritance:r >nul 2>nul
    icacls "%TARGET_EXPORT%" /grant:r "%USERNAME%:F" >nul 2>nul
)

for %%I in ("%TARGET_EXPORT%") do if exist "%%~fI" if %%~zI EQU 0 del /Q "%%~fI"

:end
endlocal
