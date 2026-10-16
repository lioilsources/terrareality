<script lang="ts">
	import { m } from '#lib/paraglide/messages.js';
	import { getLocale, localizeHref } from '#lib/paraglide/runtime.js';
	import { formatMoney, kindLabel, statusLabel, t } from '#lib/catalog.js';
	import Card from '#lib/components/Card.svelte';
	import LoadMore from '#lib/components/LoadMore.svelte';
	import type { PageProps } from './$types';

	let { data }: PageProps = $props();
	const base = $derived(`/admin/orgs/${data.org.organization.id}/listings`);
</script>

<svelte:head><title>{m.listings_title()} · {data.org.organization.name}</title></svelte:head>

<div class="grid gap-6">
	<div class="flex flex-wrap items-center justify-between gap-3">
		<h1 class="text-2xl font-semibold">{m.listings_title()} · {data.org.organization.name}</h1>
		<a
			class="rounded-lg bg-[var(--accent)] px-4 py-2 text-sm font-medium text-white no-underline"
			href={localizeHref(`${base}/new`)}>+ {m.listings_new()}</a
		>
	</div>
	<nav class="flex flex-wrap gap-2 text-sm">
		<a href={localizeHref(base)} class:font-semibold={!data.status}>{m.listings_all()}</a>
		{#each data.statuses as s (s)}
			<a href={localizeHref(`${base}?status=${s}`)} class:font-semibold={data.status === s}
				>{statusLabel[s]()}</a
			>
		{/each}
	</nav>
	{#if data.listings.length === 0}
		<Card><p class="text-sm text-[var(--muted)]">{m.listings_empty()}</p></Card>
	{:else}
		<ul class="grid gap-3 sm:grid-cols-2 lg:grid-cols-3" data-testid="listing-list">
			{#each data.listings as l (l.id)}
				<li>
					<a
						href={localizeHref(`${base}/${l.id}`)}
						class="block overflow-hidden rounded-[var(--radius-card)] border border-[var(--border)] bg-[var(--surface)] no-underline hover:border-[var(--accent)]"
					>
						<div class="aspect-[4/3] bg-[var(--border)]/40">
							{#if l.cover_url}<img
									src={l.cover_url}
									alt=""
									class="h-full w-full object-cover"
									loading="lazy"
								/>{/if}
						</div>
						<div class="grid gap-1 p-3 text-sm">
							<strong class="text-[var(--text)]"
								>{t(l.title, getLocale()) ||
									`${kindLabel[l.unit_kind]()} · ${l.unit_label}`}</strong
							>
							<span class="text-[var(--muted)]">{l.address_label}</span>
							<span class="flex flex-wrap gap-2">
								<span class="rounded bg-[var(--border)]/60 px-2 py-0.5 text-xs text-[var(--text)]"
									>{statusLabel[l.status]()}</span
								>
								{#if l.pending_review && l.status !== 'review'}<span class="text-xs text-amber-700"
										>{m.pending_review()}</span
									>{/if}
								{#if l.rent_amount}<span class="text-[var(--text)]"
										>{m.price_per_month({
											amount: formatMoney(l.rent_amount, l.currency, getLocale())
										})}</span
									>{/if}
							</span>
						</div>
					</a>
				</li>
			{/each}
		</ul>
	{/if}
	<LoadMore next={data.paging.next} first={data.paging.first} testid="listings-more" />
</div>
