# One-time / refresh setup: MySQL (Docker), Maven build, npm install, seed from G:/mv
$ErrorActionPreference = "Stop"
$Root = Split-Path $PSScriptRoot -Parent
Set-Location $Root

Write-Host "=== XPlayer setup (MySQL) ==="
Remove-Item Env:SPRING_PROFILES_ACTIVE -ErrorAction SilentlyContinue

if (-not (& (Join-Path $PSScriptRoot "ensure-mysql.ps1"))) {
    throw "MySQL setup failed. Ensure Docker Desktop is running."
}

& (Join-Path $PSScriptRoot "build-backend.ps1")

Push-Location (Join-Path $Root "frontend")
npm install
Pop-Location

if (Test-Path "G:/mv") {
    & (Join-Path $PSScriptRoot "seed-from-mv.ps1")
} else {
    Write-Warning "G:/mv not found; using sql/init.sql seed only."
}

Write-Host "Setup complete. Run: .\scripts\run-all.ps1"
