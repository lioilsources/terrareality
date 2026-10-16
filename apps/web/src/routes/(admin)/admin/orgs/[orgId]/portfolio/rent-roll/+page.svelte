<script lang="ts">
	import { goto } from '$app/navigation';
	import { m } from '#lib/paraglide/messages.js';
	import { getLocale, localizeHref } from '#lib/paraglide/runtime.js';
	import { field } from '#lib/applications.js';
	import { fmtDate } from '#lib/labels.js';
	import { stateLabel } from '#lib/leasing.js';
	import { money } from '#lib/portfolio.js';
	import Alert from '#lib/components/Alert.svelte';
	import Button from '#lib/components/Button.svelte';
	import Card from '#lib/components/Card.svelte';
	import PortfolioMap, { type MapPoint } from '#lib/components/portfolio/PortfolioMap.svelte';
	import RiskBadge from '#lib/components/portfolio/RiskBadge.svelte';
	import type { PageProps } from './$types';

	let { data, params }: PageProps = $props();
	const locale = getLocale();
	const base = $derived(`/admin/orgs/${params.orgId}`);
	let view = $state<'table' | 'map'>('table');
	const roll = $derived(data.roll);
	// Totals are summed in one currency; rows carry it.
	const currency = $derived(roll?.rows[0]?.currency ?? 'CZK');
	const canOpen = $derived(roll && roll.role !== 'investor');
	const groupName = $derived(new Map((roll?.groups ?? []).map((g) => [g.id, g])));
	const points = $derived<MapPoint[]>(
		(roll?.rows ?? [])
			.filter((r) => r.lat !== undefined && r.lng !== undefined)
			.map((r) => ({
				id: r.lease_id ?? r.unit_id ?? '',
				lat: r.lat!,
				lng: r.lng!,
				label:
					r.kind === 'vacant'
						? `${r.unit} · ${m.pf_vacant_row()}`
						: `${r.risk_score ?? ''} ${r.unit}`,
				band: r.risk_band,
				vacant: r.kind === 'vacant'
			}))
	);
	const exportHref = (format: string) =>
		`${base}/portfolio/rent-roll/export.${format}${data.query ?? ''}`;
</script>

<svelte:head><title>{m.pf_rent_roll()} · {m.app_name()}</title></svelte:head>
<p class="mb-2 text-sm"><a href={localizeHref(`${base}/portfolio`)}>← {m.pf_title()}</a></p>
<div class="mb-4 flex flex-wrap items-center gap-4">
	<h1 class="text-2xl font-semibold">{m.pf_rent_roll()}</h1>
	<span class="ml-auto flex gap-3 text-sm">
		<a href={exportHref('csv')} data-testid="export-csv">{m.pf_export_csv()}</a>
		<a href={exportHref('xlsx')} data-testid="export-xlsx">{m.pf_export_xlsx()}</a>
	</span>
</div>

{#if !roll}
	<Alert kind="error">{data.error}</Alert>
{:else}
	<form method="GET" class="mb-4 flex flex-wrap items-end gap-3">
		<select name="municipality" class={field} aria-label={m.pf_col_city()}>
			<option value="">{m.pf_filter_all_cities()}</option>
			{#each data.municipalities as c (c.path)}
				<option value={c.path} selected={data.filter.municipality === c.path}>{c.name}</option>
			{/each}
		</select>
		<select name="region" class={field} aria-label={m.pf_filter_all_regions()}>
			<option value="">{m.pf_filter_all_regions()}</option>
			{#each data.regions as c (c.path)}
				<option value={c.path} selected={data.filter.region === c.path}>{c.name}</option>
			{/each}
		</select>
		{#if roll.groups.length}
			<select name="group_id" class={field} aria-label={m.pf_groups()}>
				<option value="">{m.pf_filter_all_groups()}</option>
				{#each roll.groups as g (g.id)}
					<option value={g.id} selected={data.filter.group_id === g.id}>{g.name}</option>
				{/each}
			</select>
		{/if}
		<Button type="submit" variant="secondary">{m.pf_filter()}</Button>
		<span
			class="ml-auto flex gap-1 rounded-lg border border-[var(--border)] p-1 text-sm"
			role="tablist"
		>
			{#each [['table', m.pf_view_table], ['map', m.pf_view_map]] as const as [v, label] (v)}
				<button
					type="button"
					role="tab"
					aria-selected={view === v}
					class="rounded-md px-3 py-1 {view === v ? 'bg-[var(--accent)] text-white' : ''}"
					onclick={() => (view = v)}>{label()}</button
				>
			{/each}
		</span>
	</form>

	{#if view === 'map'}
		<PortfolioMap
			{points}
			onPoint={(id) => {
				const row = roll.rows.find((r) => r.lease_id === id);
				if (row && canOpen) goto(localizeHref(`${base}/smlouvy/${id}`));
			}}
		/>
	{:else}
		<Card>
			<div class="-mx-2 overflow-x-auto">
				<table class="w-full min-w-[900px] text-sm" data-testid="rent-roll">
					<thead class="text-left text-[var(--muted)]">
						<tr>
							<th class="px-2 py-1">{m.pf_col_city()}</th>
							<th class="px-2 py-1">{m.pf_col_address()}</th>
							<th class="px-2 py-1">{m.pf_col_tenant()}</th>
							<th class="px-2 py-1 text-right">{m.pf_col_rent()}</th>
							<th class="px-2 py-1">{m.pf_col_due()}</th>
							<th class="px-2 py-1">{m.pf_col_end()}</th>
							<th class="px-2 py-1 text-right">{m.pf_col_deposit()}</th>
							<th class="px-2 py-1 text-right">{m.pf_col_debt()}</th>
							<th class="px-2 py-1">{m.pf_col_state()}</th>
							<th class="px-2 py-1">{m.pf_col_risk()}</th>
						</tr>
					</thead>
					<tbody>
						{#each roll.rows as r, i (r.lease_id ?? r.unit_id ?? i)}
							<tr
								class="border-t border-[var(--border)]"
								data-kind={r.kind}
								data-city={r.municipality}
							>
								<td class="px-2 py-2">{r.municipality || m.pf_unknown_city()}</td>
								<td class="px-2 py-2">
									{#if r.lease_id && canOpen}
										<a href={localizeHref(`${base}/smlouvy/${r.lease_id}`)}>{r.address}</a>
									{:else}{r.address}{/if}
									<span class="block text-xs text-[var(--muted)]"
										>{r.unit}{#each r.group_ids as g (g)}
											{@const grp = groupName.get(g)}
											{#if grp}
												<span class="ml-1 rounded px-1 text-white" style="background: {grp.color}"
													>{grp.name}</span
												>
											{/if}
										{/each}</span
									>
								</td>
								<td class="px-2 py-2">{r.tenants ?? ''}</td>
								{#if r.kind === 'vacant'}
									<td class="px-2 py-2 text-right text-[var(--muted)]"
										>{r.asking_rent
											? m.pf_asking({ amount: money(r.asking_rent, r.currency, locale) })
											: ''}</td
									>
									<td class="px-2 py-2"></td>
									<td class="px-2 py-2"></td>
									<td class="px-2 py-2"></td>
									<td class="px-2 py-2"></td>
									<td class="px-2 py-2">{m.pf_vacant_row()}</td>
									<td class="px-2 py-2"></td>
								{:else}
									<td class="px-2 py-2 text-right whitespace-nowrap tabular-nums"
										>{money((r.rent ?? 0) + (r.services ?? 0), r.currency, locale)}</td
									>
									<td class="px-2 py-2 whitespace-nowrap"
										>{m.pf_due_day({ day: r.due_day ?? 0 })}</td
									>
									<td class="px-2 py-2 whitespace-nowrap"
										>{r.ends_on ? fmtDate(r.ends_on, locale) : m.pf_indefinite()}</td
									>
									<td class="px-2 py-2 text-right whitespace-nowrap tabular-nums"
										>{money(r.deposit_paid, r.currency, locale)} / {money(
											r.deposit,
											r.currency,
											locale
										)}</td
									>
									<td
										class="px-2 py-2 text-right whitespace-nowrap tabular-nums {(r.debt ?? 0) > 0
											? 'font-semibold text-red-600 dark:text-red-400'
											: ''}"
										data-testid="row-debt">{money(r.debt, r.currency, locale)}</td
									>
									<td class="px-2 py-2">{stateLabel[r.state]?.() ?? r.state}</td>
									<td class="px-2 py-2"><RiskBadge score={r.risk_score} band={r.risk_band} /></td>
								{/if}
							</tr>
						{/each}
					</tbody>
					<tfoot>
						<tr class="border-t-2 border-[var(--border)] font-semibold">
							<td class="px-2 py-2" colspan="3"
								>{m.pf_totals()}: {roll.totals.leases} · {m.pf_vacant()} {roll.totals.vacant}</td
							>
							<td class="px-2 py-2 text-right whitespace-nowrap tabular-nums"
								>{money(roll.totals.monthly, currency, locale)}</td
							>
							<td colspan="3"></td>
							<td
								class="px-2 py-2 text-right whitespace-nowrap tabular-nums"
								data-testid="total-debt">{money(roll.totals.debt, currency, locale)}</td
							>
							<td colspan="2"></td>
						</tr>
					</tfoot>
				</table>
			</div>
		</Card>
	{/if}
{/if}
