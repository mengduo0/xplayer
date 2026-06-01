import { test, expect } from '@playwright/test';

test.describe('播放列表增删', () => {
  test('删除后添加再删除', async ({ page }) => {
    await page.goto('/');
    await expect(page.getByTestId('backend-status')).toHaveText(/服务正常/, { timeout: 20_000 });

    const playlist = page.getByTestId('playlist');
    const targetFile = '1.mp4';

    const existing = playlist.locator('li', { hasText: targetFile });
    if ((await existing.count()) > 0) {
      await existing.first().getByTestId('delete-video').click();
      await expect(playlist.locator('li', { hasText: targetFile })).toHaveCount(0, { timeout: 10_000 });
    }

    await page.getByTestId('add-file').fill(targetFile);
    await page.getByTestId('add-title').fill('E2E测试');
    await page.getByTestId('add-submit').click();

    await expect(playlist.locator('li', { hasText: 'E2E测试' })).toBeVisible({ timeout: 10_000 });

    const row = playlist.locator('li', { hasText: 'E2E测试' });
    await row.getByTestId('delete-video').click();
    await expect(playlist.locator('li', { hasText: 'E2E测试' })).toHaveCount(0, { timeout: 10_000 });
  });
});
