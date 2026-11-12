$ErrorActionPreference = 'Continue'
$Root = Split-Path -Parent $PSScriptRoot
$Backend = Join-Path $Root 'backend'
Write-Host '=== NutriVision local diagnostics (secret-safe) ===' -ForegroundColor Cyan
foreach ($tool in @('node', 'npm', 'flutter')) {
  $cmd = Get-Command $tool -ErrorAction SilentlyContinue
  if ($cmd) { Write-Host "$tool : available" -ForegroundColor Green } else { Write-Host "$tool : NOT FOUND in PATH" -ForegroundColor Yellow }
}
$envFile = Join-Path $Backend '.env'
if (Test-Path $envFile) {
  $lines = Get-Content $envFile
  foreach ($key in @('GEMINI_API_KEY', 'USDA_API_KEY')) {
    $line = $lines | Where-Object { $_ -match "^\s*$key\s*=" } | Select-Object -First 1
    $configured = $false
    if ($line) { $value = ($line -split '=', 2)[1].Trim().Trim('"').Trim("'"); $configured = -not [string]::IsNullOrWhiteSpace($value) }
    Write-Host "$key configured: $configured"
  }
  $authLine = $lines | Where-Object { $_ -match '^\s*REQUIRE_FIREBASE_AUTH\s*=' } | Select-Object -First 1
  if ($authLine) { Write-Host "Auth setting: $($authLine.Trim())" } else { Write-Host 'Auth setting: not explicitly set (server default applies)' }
} else { Write-Host 'backend/.env missing. Copy backend/.env.example to backend/.env.' -ForegroundColor Yellow }
Write-Host 'Port 8080 listeners:' -ForegroundColor Cyan
netstat -ano | findstr ':8080'
Write-Host 'Health check (if Backend is running):' -ForegroundColor Cyan
try { Invoke-RestMethod 'http://localhost:8080/api/health' -TimeoutSec 3 | ConvertTo-Json -Compress } catch { Write-Host 'No successful local health response. Start backend and retry.' -ForegroundColor Yellow }
Write-Host 'Secret values are never displayed by this script.' -ForegroundColor Green
