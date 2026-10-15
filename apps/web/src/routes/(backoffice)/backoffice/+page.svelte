<script lang="ts">
	import { m } from '#lib/paraglide/messages.js';
	import { getLocale, localizeHref } from '#lib/paraglide/runtime.js';
	import { fmtDate, levelLabel } from '#lib/labels.js';
	import { formatMoney } from '#lib/catalog.js';
	import Alert from '#lib/components/Alert.svelte';
	import Button from '#lib/components/Button.svelte';
	import Card from '#lib/components/Card.svelte';
	import Field from '#lib/components/Field.svelte';
	import type { PageProps } from './$types';

	let { data }: PageProps = $props();
	const locale = getLocale();
	const num = (n: number) => new Intl.NumberFormat(locale === 'en' ? 'en-GB' : 'cs-CZ').format(n);

	type Tile = { id: string; label: string; value: string; href?: string };
	const tiles = $derived.by((): Tile[] => {
		const x = data.metrics;
		if (!x) return [];
		const cur = x.revenue_30d.currency === 'CZK' ? 'Kč' : x.revenue_30d.currency;
		return [
			{ id: 'users', label: m.bo_m_users(), value: num(x.users), href: '#bo-users-heading' },
			{ id: 'orgs', label: m.bo_m_orgs(), value: num(x.orgs) },
			{
				id: 'listings_published',
				label: m.bo_m_listings_published(),
				value: num(x.listings_published)
			},
			{
				id: 'listings_promoted',
				label: m.bo_m_listings_promoted(),
				value: num(x.listings_promoted),
				href: localizeHref('/backoffice/promo')
			},
			{ id: 'applications_30d', label: m.bo_m_applications_30d(), value: num(x.applications_30d) },
			{
				id: 'leases_signed_30d',
				label: m.bo_m_leases_signed_30d(),
				value: num(x.leases_signed_30d)
			},
			{
				id: 'moderation_open',
				label: m.bo_m_moderation_open(),
				value: num(x.moderation_open),
				href: localizeHref('/backoffice/moderation')
			},
			{
				id: 'attribute_suggestions_open',
				label: m.bo_m_attribute_suggestions_open(),
				value: num(x.attribute_suggestions_open),
				href: localizeHref('/backoffice/atributy')
			},
			{
				id: 'revenue_30d',
				label: m.bo_m_revenue_30d(),
				value: `${formatMoney(x.revenue_30d.gross_amount, locale)} ${cur}`
			},
			{ id: 'orders_paid_30d', label: m.bo_m_orders_paid_30d(), value: num(x.orders_paid_30d) }
		];
	});
	const tileClass =
		'grid gap-1 rounded-xl border border-[var(--border)] bg-[var(--surface)] p-4 text-[var(--text)] no-underline';
</script>

<svelte:head><title>{m.bo_dashboard()} · {m.nav_backoffice()}</title></svelte:head>

<div class="grid gap-6">
	<h1 class="text-2xl font-semibold">{m.bo_dashboard()}</h1>
	{#if data.metrics}
		<ul class="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-5" data-testid="bo-metrics">
			{#each tiles as tile (tile.id)}
				<li data-testid="bo-metric-{tile.id}">
					{#if tile.href}
						<a
							href={tile.href}
							class="{tileClass} h-full hover:border-[var(--accent)] focus-visible:outline-2 focus-visible:outline-[var(--accent)]"
						>
							<span class="text-xs text-[var(--muted)]">{tile.label}</span>
							<span class="text-2xl font-semibold tabular-nums">{tile.value}</span>
						</a>
					{:else}
						<div class="{tileClass} h-full">
							<span class="text-xs text-[var(--muted)]">{tile.label}</span>
							<span class="text-2xl font-semibold tabular-nums">{tile.value}</span>
						</div>
					{/if}
				</li>
			{/each}
		</ul>
	{:else}
		<Alert kind="error">{m.bo_metrics_error()}</Alert>
	{/if}
	<h2 id="bo-users-heading" class="text-xl font-semibold">{m.bo_users()}</h2>
	{#if data.error}<Alert kind="error">{data.error}</Alert>{/if}
	<form method="GET" class="flex max-w-lg items-end gap-3">
		<div class="flex-1">
			<Field label={m.field_search()} name="q" value={data.q} type="search" />
		</div>
		<Button type="submit" variant="secondary">{m.field_search()}</Button>
	</form>
	<Card>
		<ul class="grid gap-2" data-testid="bo-users">
			{#each data.page.items as u (u.id)}
				<li
					class="flex flex-wrap items-center justify-between gap-2 rounded-lg border border-[var(--border)] px-3 py-2 text-sm"
				>
					<span>
						<strong>{u.display_name || '—'}</strong> · {u.email} · {levelLabel[
							u.verification_level
						]()}
						{#if u.is_staff}· <em>{m.bo_staff()}</em>{/if}
						{#if u.pseudonymized}· <em>{m.bo_erased()}</em>{/if}
						<span class="text-[var(--muted)]">· {fmtDate(u.created_at, locale)}</span>
					</span>
					<a href={localizeHref(`/backoffice/users/${u.id}`)}>{m.org_open()}</a>
				</li>
			{/each}
		</ul>
		{#if data.page.next_before}
			<a
				class="mt-4 inline-block text-sm"
				href="?q={encodeURIComponent(data.q)}&before={data.page.next_before}">{m.bo_more()}</a
			>
		{/if}
	</Card>
</div>
