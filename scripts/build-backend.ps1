$ErrorActionPreference = "Stop"
$Root = Split-Path $PSScriptRoot -Parent
$Backend = Join-Path $Root "backend"
$Mvn = if ($env:MVN_CMD -and (Test-Path $env:MVN_CMD)) { $env:MVN_CMD } else { & (Join-Path $PSScriptRoot "ensure-maven.ps1") }

Push-Location $Backend
try {
    & $Mvn -q -DskipTests package
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    Write-Host "Backend build OK: backend\target\xplayer-backend-1.0.0.jar"
} finally {
    Pop-Location
}
