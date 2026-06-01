import { test, expect } from '@playwright/test';

test.describe('XPlayer 页面', () => {
  test('加载列表、点击播放、video 可加载元数据', async ({ page }) => {
    await page.goto('/');

    const status = page.getByTestId('backend-status');
    await expect(status).toHaveText(/服务正常/, { timeout: 20_000 });

    const playlist = page.getByTestId('playlist');
    const items = playlist.locator('li:not(.empty)');
    await expect(items.first()).toBeVisible({ timeout: 15_000 });
    const count = await items.count();
    expect(count).toBeGreaterThan(0);

    await items.first().click();

    const video = page.getByTestId('video-player');
    await expect(video).toHaveAttribute('src', /\/api\/videos\/\d+\/stream/, { timeout: 10_000 });

    await page.waitForFunction(() => {
      const el = document.querySelector('[data-testid="video-player"]');
      return el && el.readyState >= 1;
    }, { timeout: 45_000 });

    const nowPlaying = page.locator('#now-playing');
    await expect(nowPlaying).not.toHaveText(/请选择/);
  });
});
