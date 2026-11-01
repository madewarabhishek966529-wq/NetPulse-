@echo off
echo ========================================================
echo Launching NetPulse Desktop Application...
echo ========================================================

if exist "build\windows\x64\runner\Release\netpulse.exe" (
    echo Starting NetPulse Release build...
    start "" "build\windows\x64\runner\Release\netpulse.exe"
    exit /b 0
)

if exist "build\windows\x64\runner\Debug\netpulse.exe" (
    echo Starting NetPulse Debug build...
    start "" "build\windows\x64\runner\Debug\netpulse.exe"
    exit /b 0
)

flutter run -d windows
pause

