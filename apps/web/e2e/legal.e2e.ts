import { expect, test } from '@playwright/test';

const pages = [
	{ path: '/podminky', doc: 'terms', cs: 'Podmínky užívání', en: 'Terms of service' },
	{ path: '/soukromi', doc: 'privacy', cs: 'Zásady ochrany osobních údajů', en: 'Privacy policy' },
	{ path: '/cookies', doc: 'cookies', cs: 'Zásady používání cookies', en: 'Cookie policy' },
	{
		path: '/dsa',
		doc: 'dsa',
		cs: 'Kontaktní místo podle DSA',
		en: 'DSA contact point'
	}
];

for (const p of pages) {
	test(`legal page ${p.path} renders in cs and en`, async ({ page }) => {
		await page.goto(p.path);
		await expect(page.getByTestId(`legal-${p.doc}`)).toBeVisible();
		await expect(page.getByRole('heading', { level: 1 })).toContainText(p.cs);
		await expect(page.getByTestId('legal-draft')).toBeVisible();
		// Drafts are not indexed until the legal sign-off.
		await expect(page.locator('meta[name="robots"]')).toHaveAttribute('content', /noindex/);

		await page.goto(`/en${p.path}`);
		await expect(page.getByRole('heading', { level: 1 })).toContainText(p.en);
	});
}

test('footer links to the legal pages', async ({ page }) => {
	await page.goto('/');
	const footer = page.getByTestId('footer-legal');
	await footer.getByRole('link', { name: 'Kontaktní místo DSA' }).click();
	await expect(page).toHaveURL(/\/dsa$/);
	await expect(page.getByRole('heading', { level: 1 })).toContainText('DSA');
});

test('cookie notice is dismissed and stays dismissed', async ({ page, context }) => {
	await context.clearCookies();
	await page.goto('/hledat');
	const banner = page.getByRole('region', { name: 'Cookies na tomto webu' });
	await expect(banner).toBeVisible();
	await expect(banner.getByRole('link', { name: 'Více o cookies' })).toHaveAttribute(
		'href',
		'/cookies'
	);

	await banner.getByRole('button', { name: 'Rozumím' }).focus();
	await page.keyboard.press('Enter');
	await expect(page.getByTestId('cookie-banner')).toHaveCount(0);
	await expect(page).toHaveURL(/\/hledat/);

	const consent = (await context.cookies()).find((c) => c.name === 'terra_consent');
	expect(consent?.value).toBe('v1');

	await page.reload();
	await expect(page.getByTestId('cookie-banner')).toHaveCount(0);
	await page.goto('/en/cookies');
	await expect(page.getByTestId('cookie-banner')).toHaveCount(0);
	await expect(page.getByTestId('cookie-saved')).toBeVisible();
});
