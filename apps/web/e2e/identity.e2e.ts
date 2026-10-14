import { expect, test } from '@playwright/test';
import {
	PASSWORD,
	linkPath,
	register,
	totp,
	uniqueEmail,
	verifyEmail,
	waitForMail
} from './helpers';

// Acceptance M1: registration → 2FA → organization → invitation of a member.
test('registration, two-factor login, organization and invitation', async ({ page, browser }) => {
	const owner = uniqueEmail('owner');
	await register(page, owner, 'Olga Testovací');
	await expect(page).toHaveURL(/\/admin$/);
	await expect(page.getByTestId('verify-banner')).toBeVisible();
	await expect(page.getByTestId('verification-level')).toHaveText('Neověřený');

	await verifyEmail(page, owner);
	await page.goto('/admin');
	await expect(page.getByTestId('verification-level')).toHaveText('E-mail ověřen');

	// Turn on TOTP.
	await page.goto('/admin/settings/security');
	await page.getByRole('button', { name: 'Zapnout' }).click();
	const secret = (await page.getByTestId('totp-secret').textContent())!.trim();
	await page.getByLabel('Kód').fill(totp(secret));
	await page.getByRole('button', { name: 'Potvrdit a zapnout' }).click();
	await expect(page.getByTestId('recovery-codes').locator('li')).toHaveCount(10);

	// Sign out and back in: the second factor is required.
	await page.getByRole('button', { name: 'Odhlásit se' }).click();
	await page.goto('/login');
	await page.getByLabel('E-mail').first().fill(owner);
	await page.getByLabel('Heslo').fill(PASSWORD);
	await page.getByRole('button', { name: 'Přihlásit se', exact: true }).click();
	await expect(page).toHaveURL(/\/login\/mfa/);
	// The enable step used the current code; the next step is accepted (±1 window).
	await page.getByLabel('Kód').fill(totp(secret, 1));
	await page.getByRole('button', { name: 'Ověřit' }).click();
	await expect(page).toHaveURL(/\/admin$/);

	// Create a company organization and invite an agent.
	await page.goto('/admin/orgs/new');
	await page.getByLabel('Název organizace').fill('Testovací Reality s.r.o.');
	await page.getByLabel('IČO').fill('12345678');
	await page.getByRole('button', { name: 'Vytvořit' }).click();
	await expect(page.getByTestId('org-name')).toHaveText('Testovací Reality s.r.o.');
	const agent = uniqueEmail('agent');
	await page.getByTestId('invitations').getByLabel('E-mail').fill(agent);
	await page.getByRole('button', { name: 'Pozvat' }).click();
	await expect(page.getByText('Pozvánku jsme poslali.')).toBeVisible();

	// The invitee registers from the link and joins.
	const invite = linkPath(await waitForMail(agent, 'Pozvánka'));
	const ctx = await browser.newContext();
	const p2 = await ctx.newPage();
	await p2.goto(invite);
	await expect(p2.getByTestId('invite-text')).toContainText('Testovací Reality s.r.o.');
	await p2.getByRole('link', { name: 'Registrace' }).last().click();
	await register(p2, agent, 'Adam Makléř', invite);
	await expect(p2).toHaveURL(/\/invite\//);
	await p2.getByRole('button', { name: 'Přijmout pozvánku' }).click();
	await expect(p2.getByTestId('org-name')).toHaveText('Testovací Reality s.r.o.');
	await ctx.close();

	await page.reload();
	await expect(page.getByTestId('members')).toContainText(agent);
});

// Acceptance M1: the BankID mock flow raises the verification level to identity.
test('BankID mock identity verification', async ({ page }) => {
	const email = uniqueEmail('bankid');
	await register(page, email, 'Jana Nováková');
	await expect(page).toHaveURL(/\/admin$/);
	await page.goto('/admin/settings/profile');
	await page.getByRole('button', { name: 'Ověřit přes BankID' }).click();
	await expect(page.getByRole('heading', { name: 'Mock bankid' })).toBeVisible();
	await page.getByLabel('Subject').fill(`e2e-${email}`);
	await page.getByRole('button', { name: 'Continue' }).click();
	await expect(page).toHaveURL(/verified=1/);
	await expect(page.getByTestId('identity-done')).toContainText('Jana Nováková');
	await page.goto('/admin');
	await expect(page.getByTestId('verification-level')).toHaveText('Identita ověřena (BankID)');
});

test('social login with the mock Google provider', async ({ page }) => {
	await page.goto('/login');
	await page.getByRole('link', { name: /Google/ }).click();
	await expect(page.getByRole('heading', { name: 'Mock google' })).toBeVisible();
	const email = uniqueEmail('google');
	await page.getByLabel('E-mail').fill(email);
	await page.getByRole('button', { name: 'Continue' }).click();
	await expect(page).toHaveURL(/\/admin$/);
	await expect(page.getByTestId('verification-level')).toHaveText('E-mail ověřen');
});

test('private areas redirect to login', async ({ page }) => {
	await page.goto('/admin/settings/security');
	await expect(page).toHaveURL(/\/login\?next=/);
	await page.goto('/backoffice');
	await expect(page).toHaveURL(/\/login/);
});
