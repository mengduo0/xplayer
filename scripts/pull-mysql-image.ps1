# Pull MySQL image when Docker Hub times out (China mirror).
$ErrorActionPreference = "Stop"
if (docker images -q mysql:8.0 2>$null) {
    Write-Host "mysql:8.0 already present"
    exit 0
}
$mirror = "docker.m.daocloud.io/library/mysql:8.0"
Write-Host "Pulling $mirror ..."
docker pull $mirror
docker tag $mirror mysql:8.0
Write-Host "Tagged as mysql:8.0"
