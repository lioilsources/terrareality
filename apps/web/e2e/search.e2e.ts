import { expect, test } from '@playwright/test';

// Acceptance M3 (needs search data: `terractl seed-search`, done by make e2e).
test('drill down from region to neighbourhood', async ({ page }) => {
	await page.goto('/hledat');
	await expect(page.getByTestId('search-map')).toBeVisible();
	const chips = page.locator('a[href*="area="]');
	for (const name of ['Hlavní město Praha', 'Praha', 'Praha 6', 'Dejvice']) {
		await chips
			.filter({ hasText: new RegExp(`^${name} · \\d+$`) })
			.first()
			.click();
		await expect(page).toHaveURL(
			new RegExp(
				`area=[^&]*${name.toLowerCase().replace(/ /g, '_').replace('hlavní', 'hlavni').replace('město', 'mesto')}`
			)
		);
	}
	await expect(page.getByTestId('result-count')).toContainText('nabíd');
	await page.getByTestId('results').getByRole('link').first().click();
	await expect(page.getByTestId('public-title')).toBeVisible();
	await expect(page.getByTestId('public-price')).toContainText('Kč');
});

test('chat-first search sets filters and the map area', async ({ page }) => {
	await page.goto('/hledat');
	await page
		.getByRole('textbox', { name: /Popište, co hledáte/ })
		.fill('2+kk do 18 000 v Praze 6 se psem');
	await page.getByRole('button', { name: 'Hledat', exact: true }).click();
	await expect(page.getByTestId('chat-reply')).toContainText('Praha 6');
	await expect(page).toHaveURL(/area=[^&]*praha_6/);
	const filters = page.getByTestId('filters');
	await expect(filters.getByLabel('Byt')).toBeChecked();
	await expect(filters.getByLabel('2+kk', { exact: false }).first()).toBeChecked();
	await expect(filters.getByRole('spinbutton', { name: 'Nájem (Kč) do' })).toHaveValue('18000');
	await expect(filters.getByLabel(/psi/).first()).toBeChecked();
});
