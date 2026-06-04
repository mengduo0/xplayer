# 启动 MySQL + 后端 + 前端，Playwright E2E（本机 Edge，默认弹出浏览器窗口）
param([switch]$Headless)

$ErrorActionPreference = "Stop"
$Root = Split-Path $PSScriptRoot -Parent
$Jar = Join-Path $Root "backend\target\xplayer-backend-1.0.0.jar"
$Frontend = Join-Path $Root "frontend"

. (Join-Path $PSScriptRoot "playwright-env.ps1")
if ($Headless) { Remove-Item Env:PW_HEADED -ErrorAction SilentlyContinue } else { $env:PW_HEADED = "1" }
Remove-Item Env:SPRING_PROFILES_ACTIVE -ErrorAction SilentlyContinue

function Stop-Port([int]$Port) {
    Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue |
        ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }
}

function Wait-Url([string]$Url, [int]$Seconds = 45) {
    $deadline = (Get-Date).AddSeconds($Seconds)
    do {
        try {
            $r = Invoke-WebRequest $Url -UseBasicParsing -TimeoutSec 2
            if ($r.StatusCode -eq 200) { return $true }
        } catch { Start-Sleep -Seconds 1 }
    } while ((Get-Date) -lt $deadline)
    return $false
}

if (-not (Test-Path $Jar)) {
    & (Join-Path $PSScriptRoot "build-backend.ps1")
}

Write-Host "=== browser-test: MySQL ==="
if (& (Join-Path $PSScriptRoot "ensure-mysql.ps1")) {
    Remove-Item Env:SPRING_PROFILES_ACTIVE -ErrorAction SilentlyContinue
} else {
    Write-Warning "MySQL unavailable; browser E2E uses h2 profile."
    $env:SPRING_PROFILES_ACTIVE = "h2"
}

Write-Host "=== browser-test: stop old services ==="
Stop-Port 8080
Stop-Port 5173
Start-Sleep -Seconds 1

$java = if ($env:JAVA_HOME) { Join-Path $env:JAVA_HOME "bin\java.exe" } else { "java" }
$backendProc = Start-Process -FilePath $java -ArgumentList "-jar", $Jar -PassThru -WindowStyle Hidden
$frontendProc = & (Join-Path $PSScriptRoot "start-vite-dev.ps1") -FrontendDir $Frontend

try {
    Write-Host "=== browser-test: wait services ==="
    if (-not (Wait-Url "http://127.0.0.1:8080/api/health")) {
        throw "Backend did not start on :8080"
    }
    if (-not (Wait-Url "http://127.0.0.1:5173")) {
        throw "Frontend did not start on :5173"
    }
    if (-not (Wait-Url "http://127.0.0.1:5173/api/health")) {
        throw "Vite proxy to backend not ready (5173/api/health)"
    }
    if (-not (Wait-Url "http://127.0.0.1:5173/src/main.js")) {
        throw "Frontend dev assets not ready (/src/main.js)"
    }

    if (-not $env:SPRING_PROFILES_ACTIVE -and (Test-Path "G:/mv")) {
        & (Join-Path $PSScriptRoot "seed-from-mv.ps1")
    }

    Push-Location $Frontend
    if (-not (Test-Path "node_modules")) {
        cmd /c "npm install"
        if ($LASTEXITCODE -ne 0) { throw "npm install failed" }
    }

    $channel = if ($env:PW_CHANNEL) { $env:PW_CHANNEL } else { "msedge (system)" }
    $mode = if ($env:PW_HEADED -eq "1") { "headed (visible browser)" } else { "headless" }
    Write-Host "=== browser-test: Playwright channel=$channel, $mode ==="

    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    cmd /c "npm run test:e2e"
    $testExit = $LASTEXITCODE
    $ErrorActionPreference = $prevEap

    if ($testExit -ne 0 -and $env:PW_CHANNEL -eq "msedge") {
        Write-Warning "msedge failed; retry with bundled Chromium (npmmirror)..."
        $env:PW_CHANNEL = ""
        & (Join-Path $PSScriptRoot "install-playwright.ps1")
        cmd /c "npm run test:e2e"
        $testExit = $LASTEXITCODE
    }

    if ($testExit -ne 0) { throw "Playwright tests failed (exit $testExit)" }

    Write-Host "=== BROWSER-TEST PASSED ==="
    exit 0
} finally {
    Pop-Location -ErrorAction SilentlyContinue
    if ($frontendProc -and -not $frontendProc.HasExited) {
        Stop-Process -Id $frontendProc.Id -Force -ErrorAction SilentlyContinue
    }
    if ($backendProc -and -not $backendProc.HasExited) {
        Stop-Process -Id $backendProc.Id -Force -ErrorAction SilentlyContinue
    }
    Stop-Port 8080
    Stop-Port 5173
}
