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
	await expect(page).toHaveURL(/\/backoffice$/);

	await page.getByLabel('Hledat').fill(OWNER);
	await page.getByRole('button', { name: 'Hledat' }).click();
	await page.getByTestId('bo-users').getByRole('link').first().click();
	await page.getByLabel('Důvod').fill('E2E: kontrola nastavení účtu');
	await page.getByRole('button', { name: 'Přihlásit se jako uživatel' }).click();

	await expect(page.getByTestId('impersonation-banner')).toContainText(OWNER);
	await expect(page.getByTestId('impersonation-banner')).toContainText(STAFF);
	await page.getByRole('button', { name: 'Ukončit' }).click();
	await expect(page).toHaveURL(/\/backoffice$/);

	await page.goto('/backoffice/audit');
	await expect(page.getByText('E2E: kontrola nastavení účtu').first()).toBeVisible();
});
