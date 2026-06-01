param(
    [switch]$Build,
    [switch]$UseH2
)

$ErrorActionPreference = "Stop"
$Root = Split-Path $PSScriptRoot -Parent
$Jar = Join-Path $Root "backend\target\xplayer-backend-1.0.0.jar"

if ($Build -or -not (Test-Path $Jar)) {
    & (Join-Path $PSScriptRoot "build-backend.ps1")
}

if (-not $UseH2 -and $env:SPRING_PROFILES_ACTIVE -eq "h2") {
    Write-Host "Clearing SPRING_PROFILES_ACTIVE=h2 (use -UseH2 to force in-memory DB)"
    Remove-Item Env:SPRING_PROFILES_ACTIVE -ErrorAction SilentlyContinue
}

if (-not $UseH2) {
    $mysqlOk = & (Join-Path $PSScriptRoot "ensure-mysql.ps1")
    if (-not $mysqlOk) {
        throw "MySQL is not available. Start Docker Desktop and retry, or pass -UseH2 for offline smoke."
    }
}

$java = if ($env:JAVA_HOME) { Join-Path $env:JAVA_HOME "bin\java.exe" } else { "java" }
$javaArgs = @("-jar", $Jar)
if ($UseH2) {
    $javaArgs = @("-Dspring.profiles.active=h2") + $javaArgs
    Write-Host "Starting backend (profile=h2) http://127.0.0.1:8080 ..."
} else {
    Write-Host "Starting backend (MySQL) http://127.0.0.1:8080 ..."
}
& $java @javaArgs
