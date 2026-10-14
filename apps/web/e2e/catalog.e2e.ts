import { expect, test, type Page } from '@playwright/test';
import { register, uniqueEmail, verifyEmail } from './helpers';

const STAFF = 'staff@terra.local';
const PASSWORD = 'terra-dev-password';

async function newListing(page: Page, kind: 'apartment' | 'room') {
	await page.getByRole('link', { name: '+ Nový inzerát' }).click();
	await page.getByLabel('Adresa', { exact: true }).fill('dejvick');
	await page.getByRole('option').first().getByRole('button').click();
	if (kind === 'room') {
		await page.getByText('Pokoj', { exact: true }).click();
		await page.getByLabel('Název pokoje').fill('Pokoj A');
		await page.getByLabel('Plocha (m²)', { exact: true }).fill('16');
	} else {
		await page.getByLabel('Plocha (m²)').fill('54');
	}
	await page.getByLabel('Podlaží').fill('3');
	await page.getByRole('button', { name: 'Pokračovat' }).click();
	await expect(page).toHaveURL(/step=attributes/);
}

/** Clicks a submit button and waits for its form action to finish. */
async function save(page: Page, action: string, button = 'Uložit') {
	const done = page.waitForResponse(
		(r) => r.url().includes(`&/${action}`) && r.request().method() === 'POST'
	);
	await page.getByRole('button', { name: button }).click();
	expect((await done).ok()).toBeTruthy();
}

async function fillBasics(page: Page, rent: string, description: string, title = '') {
	await page.getByLabel('Nájem (Kč měsíčně)').fill(rent);
	await page.getByLabel('Kauce (Kč)').fill(String(Number(rent) * 2));
	await save(page, 'attributes');
	await page.getByRole('link', { name: '5. Text' }).click();
	await page.getByLabel('Popis (česky)').fill(description);
	if (title) await page.getByLabel('Titulek (česky)').fill(title);
	await save(page, 'text');
}

async function uploadPhoto(page: Page, file: string) {
	await page.getByRole('link', { name: '4. Fotky' }).click();
	await page.getByLabel('Nahrát fotky').setInputFiles(`e2e/fixtures/${file}`);
	await page.locator('button[type=submit]', { hasText: 'Nahrát fotky' }).click();
	await expect(page.getByTestId('photo').first()).toHaveAttribute('data-status', 'ready', {
		timeout: 30_000
	});
}

// Acceptance M2: an owner creates a flat and a room with photos, gets AI
// suggestions for attributes and text, submits; the backoffice approves and
// the version is stored.
test('owner lists a flat and a room, backoffice approves', async ({ page, browser }) => {
	test.setTimeout(180_000);
	const email = uniqueEmail('lister');
	const tag = email.slice(7, 15); // unique per run, keeps titles apart in the shared queue
	const flatTitle = `Byt 2+kk Dejvice ${tag}`;
	const roomTitle = `Pokoj A v Dejvicích ${tag}`;
	await register(page, email, 'Petra Pronajímatelka');
	await expect(page).toHaveURL(/\/admin$/);
	await verifyEmail(page, email);
	await page.goto('/admin');
	await page.getByTestId('org-list').getByRole('link', { name: 'Inzeráty' }).first().click();

	// Flat.
	await newListing(page, 'apartment');
	const flatUrl = page.url().split('?')[0];
	await fillBasics(
		page,
		'22000',
		'Světlý byt 2+kk v cihlovém domě s výtahem, balkon do dvora, myčka a pračka. Pejsek vítán, metro Dejvická blízko.'
	);

	// AI attribute suggestions need an explicit decision.
	await page.goto(`${flatUrl}?step=attributes`);
	await page.getByRole('button', { name: /Navrhnout parametry/ }).click();
	const ai = page.getByTestId('ai-attributes');
	await expect(ai.getByRole('checkbox').first()).toBeVisible({ timeout: 30_000 });
	await expect(ai).toContainText('Výtah');
	await ai.getByRole('button', { name: 'Použít vybrané' }).click();
	await expect(page.getByRole('combobox', { name: 'Výtah', exact: true })).toHaveValue('true');

	await uploadPhoto(page, 'flat.jpg');

	// AI text draft.
	await page.getByRole('link', { name: '5. Text' }).click();
	await page.getByRole('button', { name: /Navrhnout text/ }).click();
	const textAi = page.getByTestId('ai-text');
	await expect(textAi.getByRole('button', { name: 'Použít' })).toBeVisible({ timeout: 30_000 });
	await textAi.getByRole('button', { name: 'Použít' }).click();
	await expect(page.getByLabel('Titulek (česky)')).toHaveValue(/Pronájem bytu 2\+kk/);
	await page.getByLabel('Titulek (česky)').fill(flatTitle);
	await save(page, 'text');

	await page.getByRole('link', { name: '6. Náhled a odeslání' }).click();
	await page.getByRole('button', { name: 'Odeslat ke schválení' }).click();
	await expect(page.getByTestId('listing-status')).toHaveText('Ke schválení');

	// Room in a shared flat.
	await page.goto(flatUrl.replace(/\/[^/]+$/, ''));
	await newListing(page, 'room');
	const roomUrl = page.url().split('?')[0];
	await fillBasics(
		page,
		'9500',
		'Pokoj ve sdíleném bytě se třemi spolubydlícími, uzamykatelný, vlastní koupelna, klidná ulice.',
		roomTitle
	);
	await uploadPhoto(page, 'room.jpg');
	await page.getByRole('link', { name: '6. Náhled a odeslání' }).click();
	await page.getByRole('button', { name: 'Odeslat ke schválení' }).click();
	await expect(page.getByTestId('listing-status')).toHaveText('Ke schválení');

	// Backoffice approves both.
	const staffCtx = await browser.newContext();
	const staff = await staffCtx.newPage();
	await staff.goto('/login?next=/backoffice/reviews');
	await staff.getByLabel('E-mail').first().fill(STAFF);
	await staff.getByLabel('Heslo', { exact: true }).fill(PASSWORD);
	await staff.getByRole('button', { name: 'Přihlásit se', exact: true }).click();
	await staff.waitForURL((u) => u.pathname === '/backoffice/reviews');
	for (const title of [flatTitle, roomTitle]) {
		await staff.goto('/backoffice/reviews');
		await staff.getByTestId('review-queue').getByRole('link', { name: title, exact: true }).click();
		await staff.getByRole('button', { name: 'Schválit a zveřejnit' }).click();
		await staff.waitForURL((u) => u.pathname === '/backoffice/reviews');
	}
	await staffCtx.close();

	for (const url of [flatUrl, roomUrl]) {
		await page.goto(`${url}?step=preview`);
		await expect(page.getByTestId('listing-status')).toHaveText('Zveřejněný');
		await expect(page.getByTestId('versions')).toContainText('v1 · schválena');
	}
});
