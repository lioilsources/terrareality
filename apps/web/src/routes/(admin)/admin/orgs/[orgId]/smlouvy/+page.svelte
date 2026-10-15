<script lang="ts">
	import { m } from '#lib/paraglide/messages.js';
	import { getLocale, localizeHref } from '#lib/paraglide/runtime.js';
	import { formatMoney } from '#lib/catalog.js';
	import { fmtDate } from '#lib/labels.js';
	import { stateLabel } from '#lib/leasing.js';
	import Card from '#lib/components/Card.svelte';
	import type { PageProps } from './$types';

	let { data, params }: PageProps = $props();
	const locale = getLocale();
	const base = $derived(`/admin/orgs/${params.orgId}`);
</script>

<svelte:head><title>{m.lease_title()} · {m.app_name()}</title></svelte:head>
<div class="mb-4 flex flex-wrap items-center gap-4">
	<h1 class="text-2xl font-semibold">{m.lease_title()}</h1>
	<a href={localizeHref(`${base}/banka`)} class="text-sm">{m.nav_bank()}</a>
	<a
		href={localizeHref(`${base}/smlouvy/nova`)}
		class="ml-auto rounded-lg bg-[var(--accent)] px-4 py-2 text-sm text-white no-underline"
		>{m.lease_new()}</a
	>
</div>
<Card>
	{#if data.leases.length === 0}<p class="text-sm text-[var(--muted)]">{m.lease_empty()}</p>{/if}
	<ul class="grid gap-2" data-testid="leases">
		{#each data.leases as l (l.id)}
			<li>
				<a
					href={localizeHref(`${base}/smlouvy/${l.id}`)}
					class="flex flex-wrap items-center gap-3 rounded-lg border border-[var(--border)] px-3 py-2 text-[var(--text)] no-underline hover:border-[var(--accent)]"
				>
					<strong>{l.property_address}</strong>
					<span class="text-sm text-[var(--muted)]">{l.tenant_names}</span>
					<span class="text-sm"
						>{formatMoney(l.rent_amount, l.currency, locale)} · {fmtDate(l.starts_on, locale)}</span
					>
					<span class="ml-auto rounded bg-[var(--border)]/60 px-2 py-0.5 text-sm"
						>{stateLabel[l.state]()}</span
					>
				</a>
			</li>
		{/each}
	</ul>
</Card>
