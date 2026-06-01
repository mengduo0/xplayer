# CI-style smoke: build backend, MySQL (Docker), seed, API + stream check
$ErrorActionPreference = "Stop"
$Root = Split-Path $PSScriptRoot -Parent
Set-Location $Root

Write-Host "[1/5] Build backend"
& (Join-Path $PSScriptRoot "build-backend.ps1")

Write-Host "[2/5] Ensure MySQL (Docker)"
$useH2 = $false
if (& (Join-Path $PSScriptRoot "ensure-mysql.ps1")) {
    Remove-Item Env:SPRING_PROFILES_ACTIVE -ErrorAction SilentlyContinue
} else {
    Write-Warning "MySQL unavailable; fallback profile 'h2' (offline smoke only)."
    $useH2 = $true
    $env:SPRING_PROFILES_ACTIVE = "h2"
}

Write-Host "[3/5] Seed from G:/mv"
if (-not $useH2 -and (Test-Path "G:/mv")) {
    & (Join-Path $PSScriptRoot "seed-from-mv.ps1")
}

Write-Host "[4/5] Start backend"
$Jar = Join-Path $Root "backend\target\xplayer-backend-1.0.0.jar"
$java = if ($env:JAVA_HOME) { Join-Path $env:JAVA_HOME "bin\java.exe" } else { "java" }
$javaArgs = @("-jar", $Jar)
if ($useH2) {
    $javaArgs = @("-Dspring.profiles.active=h2") + $javaArgs
}
$proc = Start-Process -FilePath $java -ArgumentList $javaArgs -PassThru -WindowStyle Hidden

Write-Host "[5/5] Probe API"
try {
    $ok = $false
    for ($i = 0; $i -lt 45; $i++) {
        try {
            $health = Invoke-RestMethod "http://127.0.0.1:8080/api/health" -TimeoutSec 2
            if ($health.status -eq "ok") { $ok = $true; break }
        } catch { Start-Sleep -Seconds 1 }
    }
    if (-not $ok) { throw "Backend health check failed" }

    $db = if ($useH2) { "h2 (fallback)" } else { "mysql" }
    $videos = Invoke-RestMethod "http://127.0.0.1:8080/api/videos"
    Write-Host "DB: $db | Videos: $($videos.Count)"
    if ($videos.Count -gt 0) {
        $mediaRoot = "G:/mv"
        $pick = $videos |
            Where-Object { $_.fileName -match '\.mp4$' -and (Test-Path (Join-Path $mediaRoot $_.fileName)) } |
            Select-Object -First 1
        if (-not $pick) {
            $pick = $videos | Where-Object { Test-Path (Join-Path $mediaRoot $_.fileName) } | Select-Object -First 1
        }
        if (-not $pick) { $pick = $videos[0] }
        $streamUrl = "http://127.0.0.1:8080/api/videos/$($pick.id)/stream"
        $code = (curl.exe -s -o NUL -w "%{http_code}" $streamUrl)
        if ($code -ne "200") { throw "Stream check failed for $($pick.fileName): HTTP $code" }
        Write-Host "Stream ($($pick.fileName)): HTTP $code"
    }

    Write-Host "CRUD: add + delete"
    $file = "2.mp4"
    $existing = $videos | Where-Object { $_.fileName -eq $file }
    if ($existing) {
        Invoke-RestMethod -Method Delete -Uri "http://127.0.0.1:8080/api/videos/$($existing.id)" | Out-Null
    }
    $created = Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:8080/api/videos" -ContentType "application/json" -Body "{`"fileName`":`"$file`",`"title`":`"auto-test`"}"
    if (-not $created.id) { throw "POST /api/videos failed" }
    $del = Invoke-RestMethod -Method Delete -Uri "http://127.0.0.1:8080/api/videos/$($created.id)"
    if (-not $del.deleted) { throw "DELETE /api/videos failed" }
    Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:8080/api/videos" -ContentType "application/json" -Body "{`"fileName`":`"$file`",`"title`":`"2`"}" | Out-Null
    Write-Host "CRUD OK (id=$($created.id))"

    Write-Host "AUTOMATION PASSED"
    exit 0
} finally {
    if ($proc -and -not $proc.HasExited) {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    }
}
