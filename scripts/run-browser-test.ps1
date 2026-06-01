# 启动 MySQL + 后端 + 前端，Playwright E2E（本机 Edge，国内 npm 镜像）
$ErrorActionPreference = "Stop"
$Root = Split-Path $PSScriptRoot -Parent
$Jar = Join-Path $Root "backend\target\xplayer-backend-1.0.0.jar"
$Frontend = Join-Path $Root "frontend"

. (Join-Path $PSScriptRoot "playwright-env.ps1")
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
if (-not (& (Join-Path $PSScriptRoot "ensure-mysql.ps1"))) {
    throw "MySQL required for browser E2E."
}

Write-Host "=== browser-test: stop old services ==="
Stop-Port 8080
Stop-Port 5173
Start-Sleep -Seconds 1

$java = if ($env:JAVA_HOME) { Join-Path $env:JAVA_HOME "bin\java.exe" } else { "java" }
$backendProc = Start-Process -FilePath $java -ArgumentList "-jar", $Jar -PassThru -WindowStyle Hidden
$npm = (Get-Command npm.cmd -ErrorAction SilentlyContinue).Source
if (-not $npm) { $npm = "npm.cmd" }
$frontendProc = Start-Process -FilePath $npm -ArgumentList "run", "dev" -WorkingDirectory $Frontend -PassThru -WindowStyle Hidden

try {
    Write-Host "=== browser-test: wait services ==="
    if (-not (Wait-Url "http://127.0.0.1:8080/api/health")) {
        throw "Backend did not start on :8080"
    }
    if (-not (Wait-Url "http://127.0.0.1:5173")) {
        throw "Frontend did not start on :5173"
    }

    Push-Location $Frontend
    if (-not (Test-Path "node_modules")) {
        cmd /c "npm install"
        if ($LASTEXITCODE -ne 0) { throw "npm install failed" }
    }

    $channel = if ($env:PW_CHANNEL) { $env:PW_CHANNEL } else { "msedge (system)" }
    Write-Host "=== browser-test: Playwright channel=$channel (skip Chromium download) ==="

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
