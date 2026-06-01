# Start Docker MySQL and wait until healthy. Returns $true on success.
$ErrorActionPreference = "Stop"
$Root = Split-Path $PSScriptRoot -Parent
Set-Location $Root

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Warning "Docker CLI not found."
    return $false
}

$prevEap = $ErrorActionPreference
$ErrorActionPreference = "Continue"
cmd /c "docker info >nul 2>nul"
$dockerOk = ($LASTEXITCODE -eq 0)
$ErrorActionPreference = $prevEap
if (-not $dockerOk) {
    Write-Warning "Docker daemon not running. Start Docker Desktop first."
    return $false
}

& (Join-Path $PSScriptRoot "pull-mysql-image.ps1")

Write-Host "Starting MySQL (docker compose) ..."
docker compose up -d mysql
if ($LASTEXITCODE -ne 0) {
    return $false
}

$deadline = (Get-Date).AddMinutes(3)
do {
    Start-Sleep -Seconds 2
    $healthy = docker inspect --format='{{.State.Health.Status}}' xplayer-mysql 2>$null
    if ($healthy -eq "healthy") {
        $portOk = (Test-NetConnection -ComputerName 127.0.0.1 -Port 3306 -WarningAction SilentlyContinue).TcpTestSucceeded
        if ($portOk) {
            Write-Host "MySQL ready (xplayer / xplayer @ 127.0.0.1:3306)"
            return $true
        }
    }
    Write-Host "  waiting... health=$healthy"
} while ((Get-Date) -lt $deadline)

Write-Warning "MySQL did not become healthy in time."
return $false
