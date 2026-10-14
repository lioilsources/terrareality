import { expect, test } from '@playwright/test';

test('home shows platform status from the API', async ({ page }) => {
	await page.goto('/');
	await expect(page.getByRole('heading', { level: 1 })).toHaveText('TerraReality');
	await expect(page.getByTestId('api-status')).toBeVisible();
});

test('english locale is served under /en', async ({ page }) => {
	await page.goto('/en');
	await expect(page.getByText('Platform status')).toBeVisible();
});

test('route groups render placeholders', async ({ page }) => {
	for (const path of ['/admin', '/tenant', '/backoffice']) {
		await page.goto(path);
		await expect(page.getByRole('heading', { level: 1 })).toBeVisible();
	}
});
