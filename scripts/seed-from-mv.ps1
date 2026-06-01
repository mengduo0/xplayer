# 仅灌入固定素材：1.mp4、2.mp4、3.mp4（目录 G:/mv）

param(

    [string]$MediaRoot = "G:/mv",

    [string[]]$AllowedFiles = @("1.mp4", "2.mp4", "3.mp4")

)



$ErrorActionPreference = "Stop"

$lines = New-Object System.Collections.Generic.List[string]

$lines.Add("USE xplayer;")

$lines.Add("SET NAMES utf8mb4;")

$lines.Add("DELETE FROM video;")



$order = 1

$added = 0

foreach ($name in $AllowedFiles) {

    $path = Join-Path $MediaRoot $name

    if (-not (Test-Path $path)) {

        Write-Warning "Skip missing file: $path"

        continue

    }

    $title = [System.IO.Path]::GetFileNameWithoutExtension($name)

    $escapedTitle = $title.Replace("'", "''")

    $escapedName = $name.Replace("'", "''")

    $lines.Add("INSERT INTO video (title, file_name, sort_order) VALUES ('$escapedTitle', '$escapedName', $order);")

    $order++

    $added++

}



if ($added -eq 0) {

    Write-Warning "No allowed files found under $MediaRoot ($($AllowedFiles -join ', '))"

    exit 1

}



$outSql = Join-Path (Split-Path $PSScriptRoot -Parent) "sql\seed-generated.sql"

$utf8 = New-Object System.Text.UTF8Encoding $false

[System.IO.File]::WriteAllLines($outSql, $lines.ToArray(), $utf8)

Write-Host "Wrote $added entries (1.mp4, 2.mp4, 3.mp4) to $outSql"



$container = "xplayer-mysql"

if (docker ps --format "{{.Names}}" 2>$null | Select-String -Quiet "^$container`$") {

    docker cp $outSql "${container}:/tmp/seed-generated.sql"

    docker exec $container mysql -uxplayer -pxplayer --default-character-set=utf8mb4 xplayer -e "source /tmp/seed-generated.sql"

    Write-Host "Applied seed to MySQL container $container"

} else {

    Write-Host "MySQL container not running. Start with: docker compose up -d mysql"

}

