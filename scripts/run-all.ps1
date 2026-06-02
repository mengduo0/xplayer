# Start backend (MySQL) + frontend
$ErrorActionPreference = "Stop"
$Root = Split-Path $PSScriptRoot -Parent
$Jar = Join-Path $Root "backend\target\xplayer-backend-1.0.0.jar"

Remove-Item Env:SPRING_PROFILES_ACTIVE -ErrorAction SilentlyContinue

if (-not (Test-Path $Jar)) {
    & (Join-Path $PSScriptRoot "build-backend.ps1")
}

if (-not (& (Join-Path $PSScriptRoot "ensure-mysql.ps1"))) {
    throw "MySQL is not available. Start Docker Desktop, then retry."
}

$java = if ($env:JAVA_HOME) { Join-Path $env:JAVA_HOME "bin\java.exe" } else { "java" }
$backendJob = Start-Job -ScriptBlock {
    param($Java, $JarPath)
    & $Java -jar $JarPath 2>&1
} -ArgumentList $java, $Jar

Start-Sleep -Seconds 6
try {
    $r = Invoke-WebRequest -Uri "http://127.0.0.1:8080/api/health" -UseBasicParsing -TimeoutSec 10
    Write-Host "Backend health: $($r.Content)"
} catch {
    Write-Warning "Backend not ready yet: $_"
}

Write-Host "Open: http://127.0.0.1:5173"
& (Join-Path $PSScriptRoot "open-browser-front.ps1")
Write-Host "Press Ctrl+C to stop frontend; backend job will be stopped."

try {
    Push-Location (Join-Path $Root "frontend")
    if (-not (Test-Path "node_modules")) { npm install }
    npm run dev
} finally {
    Stop-Job $backendJob -ErrorAction SilentlyContinue
    Remove-Job $backendJob -Force -ErrorAction SilentlyContinue
    Pop-Location
}
