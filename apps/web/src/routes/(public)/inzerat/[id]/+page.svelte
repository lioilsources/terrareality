<script lang="ts">
	import { m } from '#lib/paraglide/messages.js';
	import { getLocale, localizeHref } from '#lib/paraglide/runtime.js';
	import { formatMoney, kindLabel, t, valueLabel } from '#lib/catalog.js';
	import { fmtDate } from '#lib/labels.js';
	import Card from '#lib/components/Card.svelte';
	import type { PageProps } from './$types';

	let { data }: PageProps = $props();
	const locale = getLocale();
	const l = $derived(data.listing);
	const defOf = (key: string) => data.schema.attributes.find((a) => a.key === key);
	const title = $derived(t(l.title, locale) || kindLabel[l.unit.kind]());
	const jsonLd = $derived(
		JSON.stringify({
			'@context': 'https://schema.org',
			'@type': 'Offer',
			name: title,
			price: Math.round(l.rent_amount / 100),
			priceCurrency: l.currency,
			itemOffered: {
				'@type': 'Accommodation',
				floorSize: l.unit.floor_area
					? { '@type': 'QuantitativeValue', value: l.unit.floor_area, unitCode: 'MTK' }
					: undefined
			}
		}).replace(/</g, '\\u003c')
	);
</script>

<svelte:head>
	<title>{title} · {m.app_name()}</title>
	<meta name="description" content={t(l.description, locale).slice(0, 160)} />
	<!-- eslint-disable-next-line svelte/no-at-html-tags -- JSON-LD built from our data with < escaped -->
	{@html '<script type="application/ld+json">' + jsonLd + '</' + 'script>'}
</svelte:head>

<div class="grid gap-6 lg:grid-cols-[2fr_1fr]">
	<div class="grid content-start gap-4">
		{#if l.photos.length}
			<img
				src={l.photos[0].large}
				alt={title}
				class="aspect-[16/10] w-full rounded-[var(--radius-card)] object-cover"
			/>
			{#if l.photos.length > 1}
				<div class="grid grid-cols-4 gap-2">
					{#each l.photos.slice(1, 9) as p, i (i)}<img
							src={p.thumb}
							alt=""
							class="aspect-[4/3] w-full rounded object-cover"
							loading="lazy"
						/>{/each}
				</div>
			{/if}
		{/if}
		<h1 class="text-2xl font-semibold" data-testid="public-title">{title}</h1>
		<p class="text-[var(--muted)]">{l.area_names.slice(1).join(' · ')}</p>
		<p class="whitespace-pre-line">{t(l.description, locale)}</p>
		<Card>
			<ul class="grid gap-1 text-sm sm:grid-cols-2">
				{#each Object.entries(l.attributes) as [key, v] (key)}
					{#if defOf(key)}<li>
							<span class="text-[var(--muted)]">{t(defOf(key)?.label, locale)}:</span>
							{valueLabel(defOf(key), v, locale)}
						</li>{/if}
				{/each}
			</ul>
		</Card>
	</div>
	<div class="grid content-start gap-4">
		<Card>
			<p class="text-2xl font-semibold" data-testid="public-price">
				{m.price_per_month({ amount: formatMoney(l.rent_amount, locale) })}
			</p>
			<ul class="mt-2 grid gap-1 text-sm">
				{#if l.deposit_amount}<li>
						{m.listing_deposit({ amount: formatMoney(l.deposit_amount, locale) })}
					</li>{/if}
				{#if l.utilities_amount}<li>
						{m.listing_utilities({ amount: formatMoney(l.utilities_amount, locale) })}
					</li>{/if}
				{#if l.available_from}<li>
						{m.listing_available_from({ date: fmtDate(l.available_from, locale) })}
					</li>{/if}
				{#if l.min_term_months}<li>
						{m.listing_min_term({ months: String(l.min_term_months) })}
					</li>{/if}
			</ul>
			<p class="mt-3 text-sm text-[var(--muted)]">
				{l.location.address ?? m.listing_location_approx()}
			</p>
			<p class="mt-3 text-sm text-[var(--muted)]">{m.listing_contact_soon()}</p>
		</Card>
		{#if data.similar.length}
			<Card title={m.listing_similar()}>
				<ul class="grid gap-2 text-sm">
					{#each data.similar as s (s.id)}
						<li>
							<a href={localizeHref(`/inzerat/${s.id}`)}
								>{t(s.title, locale) || kindLabel[s.unit_kind]()}</a
							>
							· {formatMoney(s.rent_amount, locale)} Kč
						</li>
					{/each}
				</ul>
			</Card>
		{/if}
	</div>
</div>
