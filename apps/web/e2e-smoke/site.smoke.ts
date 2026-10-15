import { SITE_URL, expect, open, test } from './env';

test('site landing renders', async ({ page, consoleErrors }) => {
	await open(page, `${SITE_URL}/`);
	await expect(page.locator('h1').first()).toBeVisible();
	await expect(page).toHaveTitle(/.+/);
	expect(consoleErrors).toEqual([]);
});

test('site Praha page lists offers', async ({ page, consoleErrors }) => {
	await open(page, `${SITE_URL}/pronajem-bytu/praha`);
	await expect(page.locator('h1').first()).toContainText('Praha');
	expect(consoleErrors).toEqual([]);
});

test('sitemap lists Praha pages with alternates', async ({ request }) => {
	const res = await request.get(`${SITE_URL}/sitemap.xml`);
	expect(res.status()).toBe(200);
	const xml = await res.text();
	expect(xml).toContain('<urlset');
	expect(xml).toContain('/pronajem-bytu/praha</loc>');
	expect(xml).toContain('hreflang="en"');
	// Absolute URLs must point at the production site, not localhost.
	expect(xml).not.toMatch(/<loc>https?:\/\/(localhost|127\.0\.0\.1)/);
});
