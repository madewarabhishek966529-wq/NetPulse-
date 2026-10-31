@echo off
setlocal
echo ========================================================
echo NetPulse Native Messaging Host Registration
echo ========================================================

set HOST_DIR=%~dp0
set MANIFEST_PATH=%HOST_DIR%com.netpulse.downloader.json
set FF_MANIFEST_PATH=%HOST_DIR%firefox\com.netpulse.downloader.json

:: Register for Google Chrome
REG ADD "HKCU\Software\Google\Chrome\NativeMessagingHosts\com.netpulse.downloader" /ve /t REG_SZ /d "%MANIFEST_PATH%" /f
if %ERRORLEVEL% equ 0 (
    echo [OK] Registered for Google Chrome
) else (
    echo [ERROR] Failed to register for Google Chrome
)

:: Register for Microsoft Edge
REG ADD "HKCU\Software\Microsoft\Edge\NativeMessagingHosts\com.netpulse.downloader" /ve /t REG_SZ /d "%MANIFEST_PATH%" /f
if %ERRORLEVEL% equ 0 (
    echo [OK] Registered for Microsoft Edge
) else (
    echo [ERROR] Failed to register for Microsoft Edge
)

:: Register for Mozilla Firefox
REG ADD "HKCU\Software\Mozilla\NativeMessagingHosts\com.netpulse.downloader" /ve /t REG_SZ /d "%FF_MANIFEST_PATH%" /f
if %ERRORLEVEL% equ 0 (
    echo [OK] Registered for Mozilla Firefox
) else (
    echo [ERROR] Failed to register for Mozilla Firefox
)

echo.
echo Registration Complete!
pause
