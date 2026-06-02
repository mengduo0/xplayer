# 停止 open-preview / run-all 启动的前后端
$ErrorActionPreference = "SilentlyContinue"
Get-NetTCPConnection -LocalPort 8080, 5173 -ErrorAction SilentlyContinue |
    ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }
Write-Host "Stopped processes on ports 8080 and 5173."
