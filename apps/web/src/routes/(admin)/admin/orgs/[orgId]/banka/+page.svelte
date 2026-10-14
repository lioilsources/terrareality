<script lang="ts">
	import { enhance } from '$app/forms';
	import { m } from '#lib/paraglide/messages.js';
	import { getLocale } from '#lib/paraglide/runtime.js';
	import { formatMoney } from '#lib/catalog.js';
	import { fmtDate, fmtDateTime } from '#lib/labels.js';
	import { field } from '#lib/applications.js';
	import { matchLabel } from '#lib/leasing.js';
	import Alert from '#lib/components/Alert.svelte';
	import Button from '#lib/components/Button.svelte';
	import Card from '#lib/components/Card.svelte';
	import type { PageProps } from './$types';

	let { data, form }: PageProps = $props();
	const locale = getLocale();
</script>

<svelte:head><title>{m.bank_title()} · {m.app_name()}</title></svelte:head>
<div class="grid gap-6">
	<Card title={m.bank_title()}>
		<p class="mb-4 text-sm text-[var(--muted)]">{m.bank_lead()}</p>
		{#if form?.error}<div class="mb-3"><Alert kind="error">{form.error}</Alert></div>{/if}
		{#if form?.synced}<div class="mb-3">
				<Alert kind="success"
					>{m.bank_synced({
						new: String(form.synced.new),
						matched: String(form.synced.matched),
						suggested: String(form.synced.suggested)
					})}</Alert
				>
			</div>{/if}
		{#if data.bank.connections.length === 0}<p class="mb-3 text-sm">{m.bank_none()}</p>{/if}
		<ul class="mb-4 grid gap-1 text-sm" data-testid="bank-connections">
			{#each data.bank.connections as c (c.id)}
				<li>
					{c.iban || c.provider} · {c.status}
					{#if c.last_synced_at}· {fmtDateTime(c.last_synced_at, locale)}{/if}
				</li>
			{/each}
		</ul>
		<div class="flex flex-wrap gap-3">
			<form method="POST" action="?/connect" use:enhance class="flex gap-2">
				<input name="institution_id" placeholder={m.bank_institution()} class={field} />
				<Button type="submit" variant="secondary">{m.bank_connect()}</Button>
			</form>
			{#if data.bank.connections.length}
				<form method="POST" action="?/sync" use:enhance>
					<Button type="submit">{m.bank_sync()}</Button>
				</form>
			{/if}
		</div>
	</Card>
	<Card title={m.bank_transactions()}>
		<ul class="grid gap-2 text-sm" data-testid="bank-transactions">
			{#each data.bank.transactions as t (t.id)}
				<li
					class="flex flex-wrap items-center gap-3 rounded-lg border border-[var(--border)] px-3 py-2"
				>
					<span>{fmtDate(t.booked_on, locale)}</span>
					<strong>{formatMoney(t.amount, locale)} Kč</strong>
					<span class="text-[var(--muted)]"
						>{t.counterparty_name}
						{#if t.variable_symbol}· VS {t.variable_symbol}{/if}
						{#if t.specific_symbol}· SS {t.specific_symbol}{/if}</span
					>
					<span class="ml-auto rounded bg-[var(--border)]/60 px-2 py-0.5"
						>{matchLabel[t.match_status]()}</span
					>
					{#if t.match_status === 'suggested' && t.share_id}
						<form method="POST" action="?/match" use:enhance>
							<input type="hidden" name="transaction_id" value={t.id} />
							<input type="hidden" name="share_id" value={t.share_id} />
							<Button type="submit">{m.bank_confirm()}</Button>
						</form>
					{/if}
					{#if t.match_status === 'suggested' || t.match_status === 'unmatched'}
						<form method="POST" action="?/match" use:enhance>
							<input type="hidden" name="transaction_id" value={t.id} />
							<input type="hidden" name="ignore" value="true" />
							<Button type="submit" variant="secondary">{m.bank_ignore()}</Button>
						</form>
					{/if}
					{#if t.match_note}<span class="w-full text-xs text-[var(--muted)]">{t.match_note}</span
						>{/if}
				</li>
			{/each}
		</ul>
	</Card>
</div>
