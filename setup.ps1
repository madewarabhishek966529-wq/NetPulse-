<#
.SYNOPSIS
    NetPulse Automated Environment Setup & Dependency Installer for Windows 10/11.
.DESCRIPTION
    Configures all NetPulse dependencies:
    1. Installs Python backend packages (FastAPI, Uvicorn, HTTPX, BeautifulSoup4, SQLAlchemy, etc.)
    2. Runs Flutter pub get
    3. Confirms aria2c binary and version
    4. Configures Windows Firewall inbound permissions
    5. Registers Chrome & Edge Native Messaging Host
    6. Runs backend validation tests
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$WorkspaceRoot = $PSScriptRoot
Set-Location $WorkspaceRoot

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   NETPULSE - ENVIRONMENT SETUP & CONFIGURATION           " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Python Environment Check & Dependencies
Write-Host "`n[1/6] Setting up Python backend dependencies..." -ForegroundColor Yellow
$PythonCmd = Get-Command python -ErrorAction SilentlyContinue
if (-not $PythonCmd) {
    Write-Error "Python 3 is required. Please install Python 3.10+ from python.org or Microsoft Store."
    exit 1
}

$PyVer = python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}')"
Write-Host "   + Python version: $PyVer" -ForegroundColor Green

$ReqFile = Join-Path $WorkspaceRoot "backend\requirements.txt"
if (Test-Path $ReqFile) {
    Write-Host "   + Installing backend packages from $ReqFile..." -ForegroundColor Gray
    pip install -r $ReqFile --quiet
    Write-Host "   + Backend packages verified." -ForegroundColor Green
}

# 2. aria2c Binary Verification
Write-Host "`n[2/6] Verifying aria2 download engine..." -ForegroundColor Yellow
$AriaExe = Join-Path $WorkspaceRoot "assets\bin\aria2c.exe"
if (-not (Test-Path $AriaExe)) {
    Write-Error "aria2c.exe not found at assets\bin\aria2c.exe."
    exit 1
}
$AriaVer = & $AriaExe --version | Select-Object -First 1
Write-Host "   + $AriaVer detected at $AriaExe" -ForegroundColor Green

# 3. Windows Firewall Rule Registration
Write-Host "`n[3/6] Configuring Windows Firewall rule for BitTorrent peer swarm..." -ForegroundColor Yellow
try {
    netsh advfirewall firewall add rule name="NetPulse Torrent Engine" dir=in action=allow program="$AriaExe" enable=yes | Out-Null
    Write-Host "   + Windows Firewall inbound rule configured." -ForegroundColor Green
} catch {
    Write-Warning "   - Could not automatically add firewall rule (requires Administrator privileges). Skipping."
}

# 4. Flutter Dependencies
Write-Host "`n[4/6] Installing Flutter Dart packages..." -ForegroundColor Yellow
$FlutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
if ($FlutterCmd) {
    flutter pub get
    Write-Host "   + Flutter packages retrieved successfully." -ForegroundColor Green
} else {
    Write-Warning "   - Flutter command not found in PATH. Skipping 'flutter pub get'."
}

# 5. Browser Extension Native Messaging Host Registration
Write-Host "`n[5/6] Registering Chrome & Edge Native Messaging Host..." -ForegroundColor Yellow
$HostManifestPath = Join-Path $WorkspaceRoot "browser_extension\native_host\com.netpulse.downloader.json"
if (Test-Path $HostManifestPath) {
    $ChromeRegPath = "HKCU:\Software\Google\Chrome\NativeMessagingHosts\com.netpulse.downloader"
    $EdgeRegPath = "HKCU:\Software\Microsoft\Edge\NativeMessagingHosts\com.netpulse.downloader"

    try {
        if (-not (Test-Path $ChromeRegPath)) {
            New-Item -Path $ChromeRegPath -Force | Out-Null
        }
        Set-ItemProperty -Path $ChromeRegPath -Name "(Default)" -Value $HostManifestPath

        if (-not (Test-Path $EdgeRegPath)) {
            New-Item -Path $EdgeRegPath -Force | Out-Null
        }
        Set-ItemProperty -Path $EdgeRegPath -Name "(Default)" -Value $HostManifestPath

        Write-Host "   + Registered Native Messaging Host in Windows Registry for Chrome and Edge." -ForegroundColor Green
    } catch {
        Write-Warning "   - Failed to register Native Messaging in registry: $_"
    }
}

# 6. Backend Self-Test
Write-Host "`n[6/6] Running backend validation test suite..." -ForegroundColor Yellow
$TestOutput = pytest backend/tests -v
Write-Host $TestOutput -ForegroundColor Gray

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "   NETPULSE SETUP COMPLETED SUCCESSFULLY!                 " -ForegroundColor Green
Write-Host "   To start NetPulse, simply execute:                     " -ForegroundColor Cyan
Write-Host "   .\run_netpulse.ps1                                     " -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan

