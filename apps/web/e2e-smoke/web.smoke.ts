import { expect, open, test } from './env';

test('web home renders and reaches the api', async ({ page, consoleErrors }) => {
	await open(page, '/');
	await expect(page.getByRole('heading', { level: 1 })).toBeVisible();
	await expect(page.getByTestId('api-status')).toBeVisible();
	expect(consoleErrors).toEqual([]);
});

// Plain filter search only (no chat search: that would call the LLM).
test('search returns results and a listing detail opens', async ({ page, consoleErrors }) => {
	await open(page, '/hledat');
	await expect(page.getByTestId('search-map')).toBeVisible();
	await expect(page.getByTestId('result-count')).toBeVisible();
	const results = page.getByTestId('results');
	await expect(results.getByRole('link').first()).toBeVisible();

	await results.getByRole('link').first().click();
	await expect(page).toHaveURL(/\/inzerat\/[0-9a-f-]{36}/);
	await expect(page.getByTestId('public-title')).toBeVisible();
	await expect(page.getByTestId('public-price')).toContainText('Kč');
	expect(consoleErrors).toEqual([]);
});

const legal = [
	{ path: '/podminky', doc: 'terms' },
	{ path: '/soukromi', doc: 'privacy' },
	{ path: '/cookies', doc: 'cookies' },
	{ path: '/dsa', doc: 'dsa' }
];

for (const p of legal) {
	test(`legal page ${p.path} is published`, async ({ page, consoleErrors }) => {
		await open(page, p.path);
		await expect(page.getByTestId(`legal-${p.doc}`)).toBeVisible();
		await expect(page.getByRole('heading', { level: 1 })).toBeVisible();
		await open(page, `/en${p.path}`);
		await expect(page.getByTestId(`legal-${p.doc}`)).toBeVisible();
		expect(consoleErrors).toEqual([]);
	});
}
