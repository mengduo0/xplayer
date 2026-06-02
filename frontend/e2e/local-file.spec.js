import { test, expect } from '@playwright/test';
import fs from 'fs';

const fixture = 'G:/mv/default.mp4';

test.describe('本地文件播放', () => {
  test('打开资源管理器选择文件并播放', async ({ page }) => {
    test.skip(!fs.existsSync(fixture), `fixture missing: ${fixture}`);

    await page.goto('/');
    await expect(page.getByTestId('backend-status')).toHaveText(/服务正常/, { timeout: 20_000 });

    const fileChooserPromise = page.waitForEvent('filechooser');
    await page.getByTestId('open-local-file').click();
    const fileChooser = await fileChooserPromise;
    await fileChooser.setFiles(fixture);

    const video = page.getByTestId('video-player');
    await expect(video).toHaveAttribute('src', /^blob:/, { timeout: 10_000 });
    await expect(page.locator('#now-playing')).toContainText(/本地文件/);
    await expect(page.getByTestId('add-local-to-playlist')).toBeEnabled();
  });
});
