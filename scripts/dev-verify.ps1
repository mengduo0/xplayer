# 每次改码后的统一自测入口：编译 → API 冒烟 → 浏览器 E2E
param([switch]$Headless)

$ErrorActionPreference = "Stop"
$Root = Split-Path $PSScriptRoot -Parent
Set-Location $Root

Write-Host "=== dev-verify: build ==="
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
$browserArgs = @()
if ($Headless) { $browserArgs += "-Headless" }
& (Join-Path $PSScriptRoot "run-browser-test.ps1") @browserArgs
if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "=== DEV-VERIFY PASSED ==="
exit 0
