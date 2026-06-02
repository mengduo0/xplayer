# 启动 MySQL + 后端 + 前端，并用系统默认浏览器打开页面（改码后目视验收）
param([switch]$SkipBrowser)

$ErrorActionPreference = "Stop"
$Root = Split-Path $PSScriptRoot -Parent
$Jar = Join-Path $Root "backend\target\xplayer-backend-1.0.0.jar"
$Frontend = Join-Path $Root "frontend"
$PreviewUrl = "http://127.0.0.1:5173/"

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

function Test-PreviewReady {
    try {
        $h = Invoke-WebRequest "http://127.0.0.1:8080/api/health" -UseBasicParsing -TimeoutSec 2
        $p = Invoke-WebRequest "http://127.0.0.1:5173/api/health" -UseBasicParsing -TimeoutSec 2
        return ($h.StatusCode -eq 200 -and $p.StatusCode -eq 200)
    } catch { return $false }
}

if (-not (Test-Path $Jar)) {
    & (Join-Path $PSScriptRoot "build-backend.ps1")
}

if (Test-PreviewReady) {
    Write-Host "=== preview: services already up ==="
} else {
    Write-Host "=== preview: start stack ==="
    Remove-Item Env:SPRING_PROFILES_ACTIVE -ErrorAction SilentlyContinue

    if (& (Join-Path $PSScriptRoot "ensure-mysql.ps1")) {
        if (Test-Path "G:/mv") {
            & (Join-Path $PSScriptRoot "seed-from-mv.ps1")
        }
    } else {
        Write-Warning "MySQL unavailable; preview uses h2 profile."
        $env:SPRING_PROFILES_ACTIVE = "h2"
    }

    Stop-Port 8080
    Stop-Port 5173
    Start-Sleep -Seconds 1

    $java = if ($env:JAVA_HOME) { Join-Path $env:JAVA_HOME "bin\java.exe" } else { "java" }
    $javaArgs = @("-jar", $Jar)
    if ($env:SPRING_PROFILES_ACTIVE -eq "h2") {
        $javaArgs = @("-Dspring.profiles.active=h2") + $javaArgs
    }
    Start-Process -FilePath $java -ArgumentList $javaArgs -PassThru -WindowStyle Hidden | Out-Null

    $npm = (Get-Command npm.cmd -ErrorAction SilentlyContinue).Source
    if (-not $npm) { $npm = "npm.cmd" }
    Start-Process -FilePath $npm -ArgumentList "run", "dev" -WorkingDirectory $Frontend -PassThru -WindowStyle Hidden | Out-Null

    if (-not (Wait-Url "http://127.0.0.1:8080/api/health")) {
        throw "Backend did not start on :8080"
    }
    if (-not (Wait-Url "http://127.0.0.1:5173")) {
        throw "Frontend did not start on :5173"
    }
    if (-not (Wait-Url "http://127.0.0.1:5173/api/health")) {
        throw "Vite proxy not ready"
    }
    Write-Host "=== preview: stack ready ==="
}

if (-not $SkipBrowser) {
    Write-Host "=== preview: open browser (foreground) -> $PreviewUrl ==="
    & (Join-Path $PSScriptRoot "open-browser-front.ps1") -Url $PreviewUrl
}

Write-Host ""
Write-Host "目视验收: $PreviewUrl"
Write-Host "停止服务: .\scripts\stop-preview.ps1"
Write-Host ""
