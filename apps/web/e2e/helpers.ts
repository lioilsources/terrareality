import { createHmac, randomUUID } from 'node:crypto';
import { expect, type Page } from '@playwright/test';

const MAILPIT = process.env.MAILPIT_URL ?? 'http://localhost:8025';

export function uniqueEmail(prefix: string): string {
	return `${prefix}-${randomUUID().slice(0, 8)}@example.com`;
}

/** Waits for the newest e-mail to `to` and returns its plain-text body. */
export async function waitForMail(to: string, subjectPart?: string): Promise<string> {
	const query = encodeURIComponent(`to:"${to}"`);
	for (let i = 0; i < 60; i++) {
		const res = await fetch(`${MAILPIT}/api/v1/search?query=${query}`);
		if (res.ok) {
			const body = (await res.json()) as { messages: { ID: string; Subject: string }[] };
			const msg = body.messages.find((m) => !subjectPart || m.Subject.includes(subjectPart));
			if (msg) {
				const full = (await (await fetch(`${MAILPIT}/api/v1/message/${msg.ID}`)).json()) as {
					Text: string;
				};
				return full.Text;
			}
		}
		await new Promise((r) => setTimeout(r, 500));
	}
	throw new Error(`no e-mail to ${to}`);
}

/** First link in a text body, reduced to path + query so it opens on the test server. */
export function linkPath(text: string): string {
	const url = text.match(/https?:\/\/\S+/)?.[0];
	if (!url) throw new Error('no link in e-mail');
	const u = new URL(url);
	return u.pathname + u.search;
}

/** RFC 6238 TOTP (SHA-1, 30 s, 6 digits) for a base32 secret. */
export function totp(secret: string, offsetSteps = 0): string {
	const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
	let bits = '';
	for (const c of secret.replace(/=+$/, ''))
		bits += alphabet.indexOf(c).toString(2).padStart(5, '0');
	const key = Buffer.from(bits.match(/.{8}/g)!.map((b) => parseInt(b, 2)));
	const step = Math.floor(Date.now() / 1000 / 30) + offsetSteps;
	const msg = Buffer.alloc(8);
	msg.writeBigUInt64BE(BigInt(step));
	const h = createHmac('sha1', key).update(msg).digest();
	const off = h[h.length - 1] & 0x0f;
	const v = (h.readUInt32BE(off) & 0x7fffffff) % 1_000_000;
	return v.toString().padStart(6, '0');
}

export const PASSWORD = 'E2e-secret-pass';

export async function register(page: Page, email: string, name: string, next?: string) {
	await page.goto(next ? `/register?next=${encodeURIComponent(next)}` : '/register');
	await page.getByLabel('Jméno a příjmení').fill(name);
	await page.getByLabel('E-mail', { exact: true }).fill(email);
	await page.getByLabel('Heslo', { exact: true }).fill(PASSWORD);
	await page.getByLabel('Souhlasím s obchodními podmínkami').check();
	await page.getByLabel('Beru na vědomí zásady ochrany osobních údajů').check();
	await page.getByRole('button', { name: 'Vytvořit účet' }).click();
}

export async function verifyEmail(page: Page, email: string) {
	const text = await waitForMail(email, 'Potvrďte');
	await page.goto(linkPath(text));
	await expect(page.getByTestId('email-verified')).toBeVisible();
}
