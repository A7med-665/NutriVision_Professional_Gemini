$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

function Test-Command($Name, $VersionArgs = @('--version')) {
  $cmd = Get-Command $Name -ErrorAction SilentlyContinue
  if (-not $cmd) {
    Write-Host "MISSING: $Name is not in PATH" -ForegroundColor Red
    return $false
  }
  try { & $Name @VersionArgs } catch { Write-Host "Could not run $Name : $_" -ForegroundColor Yellow }
  return $true
}

Write-Host "=== NutriVision Windows setup ===" -ForegroundColor Cyan
$flutterOk = Test-Command 'flutter' @('--version')
$nodeOk = Test-Command 'node' @('--version')
$npmOk = Test-Command 'npm' @('--version')
if (-not $nodeOk -or -not $npmOk) { throw 'Install Node.js 20+ then reopen PowerShell.' }
if (-not $flutterOk) { throw 'Install Flutter stable and add flutter\bin to PATH, then reopen PowerShell.' }

if (-not (Test-Path (Join-Path $Root 'backend\.env'))) {
  Copy-Item (Join-Path $Root 'backend\.env.example') (Join-Path $Root 'backend\.env')
  Write-Host 'Created backend\.env from .env.example. Add your own API credentials later.' -ForegroundColor Yellow
} else {
  Write-Host 'backend\.env already exists; leaving it unchanged.' -ForegroundColor Green
}

if (-not (Test-Path (Join-Path $Root 'android'))) {
  Write-Host 'Generating missing Flutter platform folders (Android, Web, Windows)...' -ForegroundColor Cyan
  flutter create . --platforms=android,web,windows
}

Write-Host 'Installing Backend dependencies...' -ForegroundColor Cyan
Push-Location (Join-Path $Root 'backend')
try {
  npm install --no-audit --no-fund
  npm run check
} finally { Pop-Location }

Write-Host 'Fetching Flutter packages...' -ForegroundColor Cyan
flutter pub get
Write-Host 'Running Flutter analyzer...' -ForegroundColor Cyan
flutter analyze
Write-Host 'Running Flutter tests...' -ForegroundColor Cyan
flutter test

Write-Host ''
Write-Host 'Setup completed. Next read START_HERE_AR.md for Firebase/Gemini configuration and run commands.' -ForegroundColor Green
