# Downloads Apache Maven locally if not on PATH (Windows).
$ErrorActionPreference = "Stop"
$MavenVersion = "3.9.6"
$ToolsDir = Join-Path (Split-Path $PSScriptRoot -Parent) ".tools"
$MavenHome = Join-Path $ToolsDir "apache-maven-$MavenVersion"
$MvnCmd = Join-Path $MavenHome "bin\mvn.cmd"

if (Test-Path $MvnCmd) {
    return $MvnCmd
}

$zipName = "apache-maven-$MavenVersion-bin.zip"
$zipPath = Join-Path $ToolsDir $zipName
$mirrors = @(
    "https://repo.huaweicloud.com/apache/maven/maven-3/$MavenVersion/binaries/$zipName",
    "https://mirrors.tuna.tsinghua.edu.cn/apache/maven/maven-3/$MavenVersion/binaries/$zipName",
    "https://archive.apache.org/dist/maven/maven-3/$MavenVersion/binaries/$zipName"
)

New-Item -ItemType Directory -Force -Path $ToolsDir | Out-Null
if (-not (Test-Path $zipPath)) {
    $downloaded = $false
    foreach ($url in $mirrors) {
        try {
            Write-Host "Downloading Maven $MavenVersion from $url ..."
            Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing -TimeoutSec 120
            if ((Get-Item $zipPath).Length -gt 1000000) {
                $downloaded = $true
                break
            }
        } catch {
            Write-Warning "Mirror failed: $url"
            Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
        }
    }
    if (-not $downloaded) {
        throw "Could not download Maven. Install Maven manually or set MVN_CMD env var."
    }
}
if (-not (Test-Path $MavenHome)) {
    Expand-Archive -Path $zipPath -DestinationPath $ToolsDir -Force
}

if (-not (Test-Path $MvnCmd)) {
    throw "Maven install failed: $MvnCmd"
}
return $MvnCmd
