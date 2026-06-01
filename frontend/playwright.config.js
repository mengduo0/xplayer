import { defineConfig } from '@playwright/test';

// 默认本机 Edge（免下载）；PW_CHANNEL= 时用 install-playwright.ps1 装的 Chromium
const raw = process.env.PW_CHANNEL;
const channel = raw === '' ? undefined : (raw || 'msedge');

export default defineConfig({
  testDir: './e2e',
  timeout: 60_000,
  retries: 0,
  use: {
    baseURL: 'http://127.0.0.1:5173',
    channel,
    headless: true,
    locale: 'zh-CN',
    screenshot: 'only-on-failure',
    trace: 'retain-on-failure',
  },
  reporter: [['list']],
});
