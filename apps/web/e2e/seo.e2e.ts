import { expect, test } from '@playwright/test';

test('robots.txt keeps private areas out of crawlers', async ({ request }) => {
	const robots = await (await request.get('/robots.txt')).text();
	for (const path of ['/admin', '/backoffice', '/zpravy', '/smlouvy', '/en/admin']) {
		expect(robots).toContain(`Disallow: ${path}`);
	}
	expect(robots).not.toMatch(/^Disallow: \/hledat/m);
});

test('filtered search is noindex with a canonical to /hledat', async ({ page }) => {
	await page.goto('/hledat');
	await expect(page.locator('link[rel="canonical"]')).toHaveAttribute('href', /\/hledat$/);
	await expect(page.locator('meta[name="robots"]')).toHaveCount(0);

	await page.goto('/hledat?kind=apartment&rent_max=20000');
	await expect(page.locator('link[rel="canonical"]')).toHaveAttribute('href', /\/hledat$/);
	await expect(page.locator('meta[name="robots"]')).toHaveAttribute('content', /noindex/);
});

test('language switch keeps the search query', async ({ page }) => {
	await page.goto('/hledat?kind=apartment&rent_max=20000');
	await page.getByRole('link', { name: /^en$/i }).click();
	await expect(page).toHaveURL(/\/en\/hledat\?kind=apartment&rent_max=20000/);
});

test('login guard redirect carries the security headers', async ({ request }) => {
	const res = await request.get('/admin', { maxRedirects: 0 });
	expect(res.status()).toBe(303);
	expect(res.headers()['location']).toContain('/login?next=');
	expect(res.headers()['x-frame-options']).toBe('DENY');
	expect(res.headers()['x-content-type-options']).toBe('nosniff');
});
