$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root
flutter pub get
flutter run --dart-define=AI_BACKEND_URL=http://10.0.2.2:8080/api/nutrition --dart-define=NUTRITION_API_BASE_URL=http://10.0.2.2:8080/api
