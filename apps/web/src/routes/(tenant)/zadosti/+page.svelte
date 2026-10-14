<script lang="ts">
	import { m } from '#lib/paraglide/messages.js';
	import { getLocale, localizeHref } from '#lib/paraglide/runtime.js';
	import { t } from '#lib/catalog.js';
	import { fmtDate } from '#lib/labels.js';
	import { statusLabel } from '#lib/applications.js';
	import Card from '#lib/components/Card.svelte';
	import type { PageProps } from './$types';

	let { data }: PageProps = $props();
	const locale = getLocale();
</script>

<svelte:head><title>{m.app_mine()} · {m.app_name()}</title></svelte:head>
<Card title={m.app_mine()}>
	{#if data.applications.length === 0}<p class="text-sm text-[var(--muted)]">
			{m.app_empty()}
		</p>{/if}
	<ul class="grid gap-2" data-testid="applications">
		{#each data.applications as a (a.id)}
			<li>
				<a
					href={localizeHref(`/zadosti/${a.id}`)}
					class="flex flex-wrap items-center gap-3 rounded-lg border border-[var(--border)] px-3 py-2 text-[var(--text)] no-underline hover:border-[var(--accent)]"
				>
					<strong>{t(a.listing_title, locale)}</strong>
					{#if a.group_name}<span class="text-sm text-[var(--muted)]">{a.group_name}</span>{/if}
					<span class="text-sm text-[var(--muted)]">{fmtDate(a.created_at, locale)}</span>
					<span
						class="ml-auto rounded bg-[var(--border)]/60 px-2 py-0.5 text-sm"
						data-testid="app-status">{statusLabel[a.status]()}</span
					>
					{#if a.consent_needed && !a.my_consent_at && a.status === 'pending_consent'}
						<span class="rounded bg-amber-200 px-2 py-0.5 text-sm text-amber-950"
							>{m.app_consent_needed()}</span
						>
					{/if}
				</a>
			</li>
		{/each}
	</ul>
</Card>
