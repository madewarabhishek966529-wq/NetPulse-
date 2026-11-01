@echo off
echo ========================================================
echo Installing Visual Studio C++ Build Tools for Flutter
echo ========================================================
echo.
echo Windows will show a User Account Control (UAC) prompt.
echo Please click "Yes" to grant administrator permission to install.
echo.

winget install Microsoft.VisualStudio.2022.BuildTools --override "--passive --wait --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended" --accept-source-agreements --accept-package-agreements

echo.
echo ========================================================
echo Done! Please restart your terminal, then run:
echo   flutter run -d windows
echo ========================================================
pause

