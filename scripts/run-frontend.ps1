$ErrorActionPreference = "Stop"
$Frontend = Join-Path (Split-Path $PSScriptRoot -Parent) "frontend"
Push-Location $Frontend
try {
    if (-not (Test-Path "node_modules")) {
        npm install
    }
    npm run dev
} finally {
    Pop-Location
}
