<script lang="ts">
	import type { components } from '@terra/contracts';
	import { m } from '#lib/paraglide/messages.js';
	import { localizeHref } from '#lib/paraglide/runtime.js';
	import { formatMoney, kindLabel, t } from '#lib/catalog.js';
	import DemoBadge from '#lib/components/DemoBadge.svelte';

	let { card: c, locale }: { card: components['schemas']['ListingCard']; locale: string } =
		$props();
</script>

<a
	href={localizeHref(`/inzerat/${c.id}`)}
	class="block overflow-hidden rounded-[var(--radius-card)] border bg-[var(--surface)] no-underline hover:border-[var(--accent)] {c.highlighted
		? 'border-amber-500 shadow-md ring-2 ring-amber-400/60 dark:border-amber-400'
		: 'border-[var(--border)]'}"
	data-testid="listing-card"
	data-promoted={c.promoted ? 'true' : undefined}
	data-highlighted={c.highlighted ? 'true' : undefined}
	data-demo={c.is_demo ? 'true' : undefined}
>
	<div class="relative aspect-[4/3] bg-[var(--border)]/40">
		{#if c.cover_url}<img
				src={c.cover_url}
				alt=""
				class="h-full w-full object-cover"
				loading="lazy"
			/>{/if}
		{#if c.promoted}
			<!-- Transparent disclosure of paid placement: text, not only color. -->
			<span
				class="absolute top-2 left-2 rounded bg-zinc-900/85 px-2 py-0.5 text-xs font-semibold text-white"
				data-testid="promoted-label">{m.billing_promoted()}</span
			>
		{/if}
		{#if c.is_demo}
			<DemoBadge class="absolute right-2 bottom-2 left-2 text-center shadow" />
		{/if}
	</div>
	<div
		class="grid gap-0.5 p-3 text-sm text-[var(--text)] {c.highlighted
			? 'bg-amber-50 dark:bg-amber-950/40'
			: ''}"
	>
		<strong>{t(c.title, locale) || kindLabel[c.unit_kind]()}</strong>
		{#if c.promoted}<span class="sr-only">{m.billing_promoted_hint()}</span>{/if}
		<span class="text-[var(--muted)]"
			>{c.city_part ?? c.city}{c.floor_area ? ` · ${c.floor_area} m²` : ''}</span
		>
		<span class="font-semibold">{formatMoney(c.rent_amount, c.currency, locale)}</span>
	</div>
</a>
