# 每次改码后的统一自测入口：编译 → API 冒烟 → 浏览器 E2E → 打开浏览器目视验收
param([switch]$NoPreview)

$ErrorActionPreference = "Stop"
$Root = Split-Path $PSScriptRoot -Parent
Set-Location $Root

Write-Host "=== dev-verify: build ==="
function Stop-Port([int]$Port) {
    Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue |
        ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }
}
Stop-Port 8080
Start-Sleep -Seconds 1
& (Join-Path $PSScriptRoot "build-backend.ps1")

Push-Location (Join-Path $Root "frontend")
try {
    if (-not (Test-Path "node_modules")) { npm install }
    npm run build
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} finally {
    Pop-Location
}

Write-Host "=== dev-verify: API automation ==="
& (Join-Path $PSScriptRoot "run-automation.ps1")
if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "=== dev-verify: browser E2E ==="
$browserArgs = @("-Headless")
& (Join-Path $PSScriptRoot "run-browser-test.ps1") @browserArgs
if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if (-not $NoPreview) {
    Write-Host "=== dev-verify: open browser preview ==="
    & (Join-Path $PSScriptRoot "open-preview.ps1")
    if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Write-Host "=== DEV-VERIFY PASSED ==="
exit 0
