# PowerShell script to extract Psiphon config from Windows GUI app
Write-Host "Searching for Psiphon config in Windows GUI app..." -ForegroundColor Cyan

$psiphonConfig = "$env:LOCALAPPDATA\Psiphon3\psiphon.config"
$altConfig = "$env:APPDATA\Psiphon3\psiphon.config"

if (Test-Path $psiphonConfig) {
    Write-Host "✅ Found config: $psiphonConfig" -ForegroundColor Green
    Write-Host ""
    Write-Host "Copying to psiphon_config.json..." -ForegroundColor Yellow
    Copy-Item $psiphonConfig -Destination ".\psiphon_config.json"
    Write-Host "✅ Copied to .\psiphon_config.json" -ForegroundColor Green
    exit 0
}
elseif (Test-Path $altConfig) {
    Write-Host "✅ Found config: $altConfig" -ForegroundColor Green
    Write-Host ""
    Write-Host "Copying to psiphon_config.json..." -ForegroundColor Yellow
    Copy-Item $altConfig -Destination ".\psiphon_config.json"
    Write-Host "✅ Copied to .\psiphon_config.json" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "❌ Config file not found" -ForegroundColor Red
    Write-Host ""
    Write-Host "Make sure you have the Psiphon Windows GUI app installed and have run it at least once." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Checked locations:" -ForegroundColor Yellow
    Write-Host "  - $psiphonConfig"
    Write-Host "  - $altConfig"
    Write-Host ""
    Write-Host "Alternative: Email Psiphon at info@psiphon.ca for a config file." -ForegroundColor Yellow
    exit 1
}
