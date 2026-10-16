<script lang="ts">
	import type { components } from '@terra/contracts';
	import { m } from '#lib/paraglide/messages.js';
	import { formatMoney } from '#lib/catalog.js';
	import { fmtDate } from '#lib/labels.js';
	import { roleLabel, stateLabel } from '#lib/leasing.js';
	import Card from '#lib/components/Card.svelte';

	let {
		detail,
		chain,
		locale
	}: {
		detail: components['schemas']['LeaseDetail'];
		chain: { valid: boolean; count: number; head: string } | null;
		locale: string;
	} = $props();
	const l = $derived(detail.lease);
</script>

<Card>
	<div class="flex flex-wrap items-baseline gap-3">
		<h1 class="text-xl font-semibold">{l.property_address} {l.unit_label}</h1>
		<span class="rounded bg-[var(--border)]/60 px-2 py-0.5 text-sm" data-testid="lease-state"
			>{stateLabel[l.state]()}</span
		>
	</div>
	<p class="mt-1 text-sm text-[var(--muted)]">
		{m.lease_code()}: <strong data-testid="lease-code">{l.code}</strong> · {fmtDate(
			l.starts_on,
			locale
		)}
		{#if l.ends_on}– {fmtDate(l.ends_on, locale)}{/if}
		· {formatMoney(l.rent_amount, l.currency, locale)} + {formatMoney(
			detail.services_amount,
			l.currency,
			locale
		)}
	</p>
	<ul class="mt-3 grid gap-1 text-sm" data-testid="lease-parties">
		{#each detail.parties as p (p.id)}
			<li>
				<strong>{p.name}</strong> · {roleLabel[p.role]()}
				{#if p.role !== 'landlord' && p.role !== 'guarantor'}· {p.share_bps / 100} %{/if}
				·
				<span data-testid="signature"
					>{p.signed_at ? `✓ ${m.lease_signed_badge()}` : m.lease_not_signed()}</span
				>
				{#if p.debt}<span class="text-red-700">· {formatMoney(p.debt, l.currency, locale)}</span
					>{/if}
			</li>
		{/each}
	</ul>
	<p class="mt-3 text-sm" data-testid="lease-debt">
		{m.lease_debt()}:
		{#if detail.total_debt > 0}<strong class="text-red-700"
				>{formatMoney(detail.total_debt, l.currency, locale)}</strong
			>{:else}<strong>{formatMoney(0, l.currency, locale)}</strong> · {m.lease_debt_none()}{/if}
	</p>
	{#if detail.documents.length}
		<p class="mt-3 text-sm">
			{m.lease_documents()}:
			{#each detail.documents as d (d.id)}
				<a href={d.url} target="_blank" rel="noopener" class="mr-3">{d.filename}</a>
			{/each}
		</p>
	{/if}
	{#if chain}
		<p class="mt-3 text-xs {chain.valid ? 'text-emerald-700' : 'text-red-700'}" data-testid="chain">
			{m.lease_chain()}: {chain.valid
				? m.lease_chain_ok({ count: String(chain.count) })
				: m.lease_chain_broken()}
			<span class="font-mono">{chain.head.slice(0, 16)}…</span>
		</p>
	{/if}
	<p class="mt-2 text-xs text-[var(--muted)]">{m.lease_money_note()}</p>
</Card>
