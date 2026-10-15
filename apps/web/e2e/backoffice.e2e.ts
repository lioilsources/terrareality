import { expect, test } from '@playwright/test';

// Dev accounts from `terractl seed-dev` (make seed).
const STAFF = 'staff@terra.local';
const OWNER = 'owner@terra.local';
const PASSWORD = 'terra-dev-password';

test('staff impersonates a user with an audited reason', async ({ page }) => {
	await page.goto('/login?next=/backoffice');
	await page.getByLabel('E-mail').first().fill(STAFF);
	await page.getByLabel('Heslo', { exact: true }).fill(PASSWORD);
	await page.getByRole('button', { name: 'Přihlásit se', exact: true }).click();
	await page.waitForURL((u) => u.pathname === '/backoffice');

	await page.getByLabel('Hledat').fill(OWNER);
	await page.getByRole('button', { name: 'Hledat' }).click();
	await page.getByTestId('bo-users').getByRole('link').first().click();
	await page.getByLabel('Důvod').fill('E2E: kontrola nastavení účtu');
	await page.getByRole('button', { name: 'Přihlásit se jako uživatel' }).click();

	await expect(page.getByTestId('impersonation-banner')).toContainText(OWNER);
	await expect(page.getByTestId('impersonation-banner')).toContainText(STAFF);
	await page.getByRole('button', { name: 'Ukončit' }).click();
	await expect(page).toHaveURL(/\/backoffice$/);

	await page.goto('/backoffice/audit?entity=user');
	await expect(page.getByText('E2E: kontrola nastavení účtu').first()).toBeVisible();
});

test('staff sees metrics, toggles a flag, adds a promo product and decides a suggestion', async ({
	page
}) => {
	await page.goto('/login?next=/backoffice');
	await page.getByLabel('E-mail').first().fill(STAFF);
	await page.getByLabel('Heslo', { exact: true }).fill(PASSWORD);
	await page.getByRole('button', { name: 'Přihlásit se', exact: true }).click();
	await page.waitForURL((u) => u.pathname === '/backoffice');

	// Dashboard tiles
	const metrics = page.getByTestId('bo-metrics');
	await expect(metrics).toBeVisible();
	for (const id of ['users', 'orgs', 'revenue_30d', 'attribute_suggestions_open']) {
		await expect(page.getByTestId(`bo-metric-${id}`)).toBeVisible();
	}
	await expect(page.getByTestId('bo-metric-revenue_30d')).toContainText('Kč');

	// Feature flag round-trip (restored at the end)
	await page.goto('/backoffice/flags');
	const row = page.getByTestId('bo-flag-ai.cloud_fallback');
	const state = row.getByTestId('bo-flag-state');
	const before = (await state.textContent())?.trim();
	const after = before === 'Zapnuto' ? 'Vypnuto' : 'Zapnuto';
	await row.getByRole('button', { name: /ai\.cloud_fallback/ }).click();
	await expect(state).toHaveText(after);
	await expect(row).toContainText('Databáze');
	await page.reload();
	await expect(row.getByTestId('bo-flag-state')).toHaveText(after);
	await row.getByRole('button', { name: /ai\.cloud_fallback/ }).click();
	await expect(row.getByTestId('bo-flag-state')).toHaveText(before ?? '');

	// Promo product catalog
	await page.goto('/backoffice/promo');
	const code = `e2e_${Date.now().toString(36)}`;
	const create = page.locator('form[action="?/create"]');
	await create.getByLabel('Kód').fill(code);
	await create.getByLabel('Typ').selectOption('highlight');
	await create.getByLabel('Délka (dny)').fill('14');
	await create.getByLabel('Cena bez DPH (Kč)').fill('149');
	await create.getByLabel('Název (česky)').fill('E2E zvýraznění');
	await create.getByLabel('Název (anglicky)').fill('E2E highlight');
	await create.getByRole('button', { name: 'Přidat produkt' }).click();
	const product = page.getByTestId(`bo-promo-${code}`);
	await expect(product).toBeVisible();
	await expect(product).toContainText('149,00');
	await expect(product).toContainText('180,29'); // 149 + 21 % VAT

	// Deactivate it again so the owner catalog stays clean
	await product.getByText(`Upravit ${code}`).click();
	await product.getByLabel('Aktivní').uncheck();
	await product.getByRole('button', { name: `Uložit ${code}` }).click();
	await expect(page.getByTestId(`bo-promo-${code}`).getByTestId('bo-promo-active')).toHaveText(
		'Neaktivní'
	);

	// AI attribute suggestions: nothing produces rows deterministically, so decide one only if present
	await page.goto('/backoffice/atributy');
	await expect(page.getByText('nic se automaticky nezveřejní')).toBeVisible();
	const first = page.getByTestId('bo-attrs').locator('li').first();
	if (await first.isVisible()) {
		const id = (await first.getAttribute('data-testid'))!;
		await first.getByLabel('Poznámka (nepovinné)').fill('E2E: zamítnuto');
		await first.getByRole('button', { name: 'Zamítnout návrh' }).click();
		await expect(page.getByTestId(id)).toHaveCount(0);
		await page.goto('/backoffice/atributy?stav=rozhodnute');
		await expect(page.getByTestId(id).getByTestId('bo-attr-status')).toContainText('Zamítnuto');
	} else {
		await expect(page.getByTestId('bo-attrs-empty')).toBeVisible();
	}
});
