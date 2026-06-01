# 仅当本机无 Edge/Chrome 时：从 npmmirror 下载 Playwright Chromium
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "playwright-env.ps1")
$Frontend = Join-Path (Split-Path $PSScriptRoot -Parent) "frontend"
Push-Location $Frontend
try {
    Write-Host "PLAYWRIGHT_DOWNLOAD_HOST=$env:PLAYWRIGHT_DOWNLOAD_HOST"
    cmd /c "npx playwright install chromium"
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    Write-Host "Chromium installed (mirror)."
} finally {
    Pop-Location
}
