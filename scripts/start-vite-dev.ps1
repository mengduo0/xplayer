# Start Vite dev server (node vite.js). npm.cmd often exits immediately when spawned hidden on Windows.
param([string]$FrontendDir)

$ErrorActionPreference = "Stop"
if (-not $FrontendDir) {
    $FrontendDir = Join-Path (Split-Path $PSScriptRoot -Parent) "frontend"
}

$node = (Get-Command node -ErrorAction SilentlyContinue).Source
if (-not $node) { throw "node not found on PATH" }

$vite = Join-Path $FrontendDir "node_modules\vite\bin\vite.js"
if (-not (Test-Path $vite)) {
    throw "Vite not installed. Run: cd frontend; npm install"
}

Start-Process -FilePath $node -ArgumentList $vite -WorkingDirectory $FrontendDir -PassThru -WindowStyle Hidden
