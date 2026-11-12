$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Backend = Join-Path $Root 'backend'
if (-not (Test-Path (Join-Path $Backend '.env'))) {
  Copy-Item (Join-Path $Backend '.env.example') (Join-Path $Backend '.env')
  Write-Host 'Created backend\.env. Add GEMINI_API_KEY and USDA_API_KEY. The template enables local-only auth bypass for easier testing; never expose this server or use that setting in production.' -ForegroundColor Yellow
}
Set-Location $Backend
npm start
