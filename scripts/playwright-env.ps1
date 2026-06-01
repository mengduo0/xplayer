# 国内镜像 + 优先使用本机 Edge（免下载 Chromium）
$env:PLAYWRIGHT_DOWNLOAD_HOST = "https://npmmirror.com/mirrors/playwright"
$env:NPM_CONFIG_REGISTRY = "https://registry.npmmirror.com"
# 默认用本机 Edge；需下载内置 Chromium 时: $env:PW_CHANNEL = ""
if (-not $env:PW_CHANNEL) { $env:PW_CHANNEL = "msedge" }
