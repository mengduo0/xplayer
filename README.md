# XPlayer

本机编译测试用 Web 视频播放器：前端 HTML5 播放，Java Spring Boot 提供列表与流式接口，**播放列表来自 Docker MySQL**，媒体文件目录默认 `G:/mv/`。

## 架构

```
浏览器 (Vite :5173)  →  /api/* 代理  →  Java (:8080)  →  MySQL (:3306, Docker)
                                              ↓
                                         G:/mv/*.mp4
```

## 快速开始

```powershell
cd H:\work\xplayer
# 先启动 Docker Desktop
.\scripts\setup.ps1      # MySQL 容器 + 构建 + npm + 从 G:/mv 灌库
.\scripts\run-all.ps1    # 后端(MySQL) + 前端
```

浏览器：**http://127.0.0.1:5173**

## 常用脚本

| 脚本 | 说明 |
|------|------|
| `scripts/ensure-mysql.ps1` | 启动并等待 MySQL 容器就绪 |
| `scripts/setup.ps1` | 一键初始化（依赖 MySQL） |
| `scripts/build-backend.ps1` | Maven 打包 |
| `scripts/run-backend.ps1` | 运行 jar（默认连 MySQL） |
| `scripts/run-frontend.ps1` | Vite 开发服务器 |
| `scripts/run-all.ps1` | MySQL + 后端 + 前端 |
| `scripts/seed-from-mv.ps1` | 扫描 `G:/mv` 写入 MySQL |
| `scripts/run-automation.ps1` | 冒烟自测（优先 MySQL） |
| `scripts/dev-verify.ps1` | **改码后必跑**：编译 + API 冒烟 + 浏览器 E2E |
| `scripts/run-browser-test.ps1` | Playwright E2E（默认本机 **Edge**，免下载） |
| `scripts/install-playwright.ps1` | 可选：从 **npmmirror** 下载内置 Chromium |

## 配置

`backend/src/main/resources/application.yml`：

- `spring.datasource.*` — MySQL（`xplayer` / `xplayer` @ `127.0.0.1:3306`）
- `xplayer.media-root` — 本地视频根目录（默认 `G:/mv`）

Docker：`docker compose up -d mysql`，初始化脚本 `sql/init.sql`。

## 离线冒烟（无 Docker 时）

```powershell
.\scripts\run-backend.ps1 -UseH2
.\scripts\run-automation.ps1   # MySQL 不可用时会自动 fallback h2
```

## API

- `GET /api/health`
- `GET /api/videos` — 播放列表（MySQL）
- `GET /api/videos/{id}/stream` — 视频流（支持 Range）
