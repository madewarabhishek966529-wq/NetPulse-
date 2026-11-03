<#
.SYNOPSIS
    NetPulse Single-Command Launcher for Windows 10/11.
.DESCRIPTION
    Launches the complete NetPulse desktop system:
    1. Terminates any stale aria2c or backend processes
    2. Initializes data directories
    3. Launches the FastAPI backend (127.0.0.1:8000)
    4. Waits for backend health status confirmation
    5. Starts the NetPulse Flutter Windows desktop application
    6. Gracefully shuts down background services upon exit
#>

[CmdletBinding()]
param (
    [switch]$Release,
    [switch]$HeadlessBackend
)

$ErrorActionPreference = "Stop"
$WorkspaceRoot = $PSScriptRoot
Set-Location $WorkspaceRoot

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   NETPULSE - SMART WEB DOWNLOAD MANAGER                  " -ForegroundColor Cyan
Write-Host "   Download Smarter. Download Faster.                     " -ForegroundColor DarkCyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Kill any orphaned or stale processes
Write-Host "[1/5] Checking and cleaning stale background processes..." -ForegroundColor Yellow
try {
    Stop-Process -Name "aria2c" -Force -ErrorAction SilentlyContinue
} catch {}

# 2. Check Prerequisites
Write-Host "[2/5] Validating runtime environment..." -ForegroundColor Yellow

# Check Python
$PythonCmd = Get-Command python -ErrorAction SilentlyContinue
if (-not $PythonCmd) {
    Write-Error "Python 3 is required but was not found in PATH. Please install Python 3.10+."
    exit 1
}
$PythonExe = $PythonCmd.Source
Write-Host "   + Python detected: $PythonExe" -ForegroundColor Green

# Check aria2c binary
$AriaBinary = Join-Path $WorkspaceRoot "assets\bin\aria2c.exe"
if (-not (Test-Path $AriaBinary)) {
    Write-Warning "aria2c.exe not found at assets\bin\aria2c.exe. Checking system PATH..."
    $AriaCmd = Get-Command aria2c -ErrorAction SilentlyContinue
    if ($AriaCmd) {
        $AriaBinary = $AriaCmd.Source
    } else {
        Write-Error "aria2c executable not found. Please run .\setup.ps1 to configure binaries."
        exit 1
    }
}
Write-Host "   + aria2c engine detected: $AriaBinary" -ForegroundColor Green

# Ensure data directories
$DataDir = Join-Path $WorkspaceRoot ".netpulse_data"
if (-not (Test-Path $DataDir)) {
    New-Item -ItemType Directory -Path $DataDir -Force | Out-Null
}

# 3. Launch FastAPI Backend
Write-Host "[3/5] Starting NetPulse Core FastAPI Backend on 127.0.0.1:8000..." -ForegroundColor Yellow

$BackendScript = @"
import uvicorn
import sys
import os

sys.path.insert(0, os.path.abspath('backend'))
os.environ['NETPULSE_DATA_DIR'] = os.path.abspath('.netpulse_data')

if __name__ == '__main__':
    uvicorn.run('app.main:app', host='127.0.0.1', port=8000, log_level='info')
"@

$BackendRunnerPath = Join-Path $WorkspaceRoot ".netpulse_data\start_backend.py"
Set-Content -Path $BackendRunnerPath -Value $BackendScript -Encoding UTF8

$BackendProcess = Start-Process -FilePath "python" -ArgumentList "`"$BackendRunnerPath`"" -WorkingDirectory $WorkspaceRoot -PassThru -WindowStyle Hidden

# 4. Wait for Backend Health
Write-Host "[4/5] Waiting for FastAPI Backend health check..." -ForegroundColor Yellow
$BackendOnline = $false
$Attempts = 0
$MaxAttempts = 30

while (-not $BackendOnline -and $Attempts -lt $MaxAttempts) {
    Start-Sleep -Milliseconds 500
    $Attempts++
    try {
        $HealthRes = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/health" -Method Get -TimeoutSec 2 -ErrorAction Stop
        if ($HealthRes.status -eq "ok") {
            $BackendOnline = $true
            Write-Host "   + FastAPI Backend is ONLINE (v$($HealthRes.version))" -ForegroundColor Green
        }
    } catch {
        Write-Host -NoNewline "."
    }
}

if (-not $BackendOnline) {
    Write-Error "FastAPI Backend failed to become healthy within 15 seconds."
    Stop-Process -Id $BackendProcess.Id -Force -ErrorAction SilentlyContinue
    exit 1
}

# 5. Launch Flutter Desktop Application
Write-Host "[5/5] Launching NetPulse Desktop UI..." -ForegroundColor Yellow

$ReleaseExe = Join-Path $WorkspaceRoot "build\windows\x64\runner\Release\netpulse.exe"

try {
    if ($Release -and (Test-Path $ReleaseExe)) {
        Write-Host "   + Running optimized release binary..." -ForegroundColor Green
        & $ReleaseExe
    } else {
        Write-Host "   + Starting Flutter application..." -ForegroundColor Green
        flutter run -d windows
    }
} finally {
    Write-Host "`nStopping NetPulse background services..." -ForegroundColor Yellow
    if ($BackendProcess -and -not $BackendProcess.HasExited) {
        Stop-Process -Id $BackendProcess.Id -Force -ErrorAction SilentlyContinue
    }
    Stop-Process -Name "aria2c" -Force -ErrorAction SilentlyContinue
    Write-Host "NetPulse stopped cleanly. Goodbye!" -ForegroundColor Cyan
}

