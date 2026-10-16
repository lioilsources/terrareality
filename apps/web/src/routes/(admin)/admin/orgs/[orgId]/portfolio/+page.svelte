<script lang="ts">
	import { enhance } from '$app/forms';
	import { m } from '#lib/paraglide/messages.js';
	import { getLocale, localizeHref } from '#lib/paraglide/runtime.js';
	import { field } from '#lib/applications.js';
	import { fmtDate, fmtDateTime } from '#lib/labels.js';
	import { attentionLabel, bandColor, money, pct } from '#lib/portfolio.js';
	import Alert from '#lib/components/Alert.svelte';
	import Button from '#lib/components/Button.svelte';
	import Card from '#lib/components/Card.svelte';
	import RiskBadge from '#lib/components/portfolio/RiskBadge.svelte';
	import type { PageProps } from './$types';

	let { data, form, params }: PageProps = $props();
	const locale = getLocale();
	const base = $derived(`/admin/orgs/${params.orgId}`);
	const d = $derived(data.dashboard);
	let busy = $state(false);

	const maxBar = $derived(
		Math.max(1, ...(d?.trend ?? []).map((t) => Math.max(t.expected, t.received)))
	);
	const monthLabel = (period: string) =>
		new Date(`${period}-01`).toLocaleDateString(locale === 'en' ? 'en-GB' : 'cs-CZ', {
			month: 'short'
		});
	const leaseHref = (id?: string) => (id ? localizeHref(`${base}/smlouvy/${id}`) : undefined);
</script>

<svelte:head><title>{m.pf_title()} · {m.app_name()}</title></svelte:head>

<div class="mb-4 flex flex-wrap items-center gap-4">
	<h1 class="text-2xl font-semibold">{m.pf_title()}</h1>
	<a href={localizeHref(`${base}/portfolio/rent-roll`)} class="text-sm">{m.pf_rent_roll()}</a>
	<a href={localizeHref(`${base}/portfolio/nastaveni`)} class="text-sm">{m.pf_settings()}</a>
</div>
<p class="mb-6 text-sm text-[var(--muted)]">{m.pf_subtitle()}</p>

{#if !d}
	<Alert kind="error">{data.error}</Alert>
{:else}
	{#if d.role === 'investor' || d.role === 'viewer'}
		<div class="mb-4"><Alert kind="info">{m.pf_readonly()}</Alert></div>
	{/if}
	<form method="GET" class="mb-6 flex flex-wrap items-end gap-3" data-testid="pf-filter">
		<select name="municipality" class={field} aria-label={m.pf_col_city()}>
			<option value="">{m.pf_filter_all_cities()}</option>
			{#each data.cities as c (c.path)}
				<option value={c.path} selected={data.filter.municipality === c.path}>{c.name}</option>
			{/each}
		</select>
		{#if data.groups.length}
			<select name="group_id" class={field} aria-label={m.pf_groups()}>
				<option value="">{m.pf_filter_all_groups()}</option>
				{#each data.groups as g (g.id)}
					<option value={g.id} selected={data.filter.group_id === g.id}>{g.name}</option>
				{/each}
			</select>
		{/if}
		<Button type="submit" variant="secondary">{m.pf_filter()}</Button>
	</form>

	<div class="mb-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
		<Card testid="pf-kpi-risk">
			<p class="text-sm text-[var(--muted)]" title={m.pf_weighted_hint()}>{m.pf_weighted_risk()}</p>
			<p class="mt-1 text-2xl font-semibold" data-testid="pf-weighted">
				<RiskBadge score={d.weighted_risk} band={d.band} />
			</p>
		</Card>
		<Card>
			<p class="text-sm text-[var(--muted)]">{m.pf_leases()} · {m.pf_vacant()}</p>
			<p class="mt-1 text-2xl font-semibold">{d.leases} · {d.vacant}</p>
		</Card>
		<Card>
			<p class="text-sm text-[var(--muted)]">{m.pf_monthly()}</p>
			<p class="mt-1 text-2xl font-semibold">{money(d.monthly, d.currency, locale)}</p>
			<p class="text-sm text-[var(--muted)]">{m.pf_debt()}: {money(d.debt, d.currency, locale)}</p>
		</Card>
		<Card>
			<p class="text-sm text-[var(--muted)]">{m.pf_this_month()}</p>
			<p class="mt-1 text-2xl font-semibold">{money(d.received, d.currency, locale)}</p>
			<p class="text-sm text-[var(--muted)]">
				{m.pf_of_expected({ amount: money(d.expected, d.currency, locale) })}
			</p>
		</Card>
	</div>

	<div class="grid gap-6 lg:grid-cols-[2fr_1fr]">
		<div class="grid content-start gap-6">
			<Card title={m.pf_cities()} testid="pf-cities">
				<ul class="grid gap-3 sm:grid-cols-2">
					{#each d.cities as c (c.path || '?')}
						<li
							class="grid gap-1 rounded-lg border border-[var(--border)] p-3"
							style="border-left: 4px solid {c.band ? bandColor[c.band] : 'var(--border)'}"
							data-testid="pf-city"
							data-city={c.name}
						>
							<div class="flex items-center justify-between gap-2">
								<a
									href={c.path ? `?municipality=${encodeURIComponent(c.path)}` : undefined}
									class="font-semibold">{c.name || m.pf_unknown_city()}</a
								>
								<RiskBadge score={c.weighted_risk} band={c.band} />
							</div>
							<span class="text-sm text-[var(--muted)]"
								>{c.region} · {m.pf_city_leases({
									count: c.leases
								})}{#if c.vacant}<span> · </span>{m.pf_city_vacant({
										count: c.vacant
									})}{/if}</span
							>
							<span class="text-sm"
								>{money(c.monthly, d.currency, locale)} · {m.pf_city_share({
									share: pct(c.share)
								})}</span
							>
							<span class="text-sm text-[var(--muted)]"
								>{m.pf_this_month()}: {money(c.received, d.currency, locale)} / {money(
									c.expected,
									d.currency,
									locale
								)}{#if c.debt}<span> · </span>{m.pf_debt()}
									{money(c.debt, d.currency, locale)}{/if}</span
							>
						</li>
					{/each}
				</ul>
			</Card>

			<Card title={m.pf_trend()} testid="pf-trend">
				<div class="flex h-40 items-end gap-1" role="img" aria-label={m.pf_trend()}>
					{#each d.trend as t (t.period)}
						<div class="flex h-full flex-1 flex-col items-center justify-end gap-1">
							<div class="flex h-full w-full items-end justify-center gap-0.5">
								<div
									class="w-1/2 rounded-t bg-[var(--border)]"
									style="height: {(t.expected / maxBar) * 100}%"
									title="{m.pf_trend_expected()}: {money(t.expected, d.currency, locale)}"
								></div>
								<div
									class="w-1/2 rounded-t bg-[var(--accent)]"
									style="height: {(t.received / maxBar) * 100}%"
									title="{m.pf_trend_received()}: {money(t.received, d.currency, locale)}"
								></div>
							</div>
							<span class="text-[10px] text-[var(--muted)]">{monthLabel(t.period)}</span>
							<span class="text-[10px] tabular-nums" title={m.pf_trend_risk()}
								>{t.weighted_risk ?? '·'}</span
							>
						</div>
					{/each}
				</div>
				<p class="mt-2 flex gap-4 text-xs text-[var(--muted)]">
					<span
						><span class="inline-block size-2 rounded bg-[var(--border)]"></span>
						{m.pf_trend_expected()}</span
					>
					<span
						><span class="inline-block size-2 rounded bg-[var(--accent)]"></span>
						{m.pf_trend_received()}</span
					>
					<span>123 = {m.pf_trend_risk()}</span>
				</p>
			</Card>

			<Card title={m.pf_ai_title()} testid="pf-ai">
				<p class="mb-3 text-sm text-[var(--muted)]">{m.pf_ai_hint()}</p>
				{#if form?.error}<Alert kind="error">{form.error}</Alert>{/if}
				{#if data.summary}
					<div class="mb-3 grid gap-2 rounded-lg border border-dashed border-[var(--border)] p-3">
						<p data-testid="pf-ai-summary">{data.summary.summary}</p>
						{#if data.summary.changes.length}
							<p class="text-sm font-medium">{m.pf_ai_changes()}</p>
							<ul class="list-disc pl-5 text-sm">
								{#each data.summary.changes as c, i (i)}<li>{c}</li>{/each}
							</ul>
						{/if}
						{#if data.summary.actions.length}
							<p class="text-sm font-medium">{m.pf_ai_actions()}</p>
							<ul class="list-disc pl-5 text-sm">
								{#each data.summary.actions as a, i (i)}<li>{a}</li>{/each}
							</ul>
						{/if}
						<p class="text-xs text-[var(--muted)]">
							{m.pf_ai_meta({
								model: data.summary.model,
								date: fmtDateTime(data.summary.created_at, locale)
							})}
						</p>
					</div>
				{/if}
				<form
					method="POST"
					action="?/summarize"
					use:enhance={() => {
						busy = true;
						return async ({ update }) => {
							await update();
							busy = false;
						};
					}}
				>
					<Button type="submit" variant="secondary" disabled={busy}
						>{data.summary ? m.pf_ai_regenerate() : m.pf_ai_generate()}</Button
					>
				</form>
			</Card>
		</div>

		<div class="grid content-start gap-6">
			<Card title={m.pf_attention()} testid="pf-attention">
				{#if d.attention.length === 0}
					<p class="text-sm text-[var(--muted)]">{m.pf_attention_empty()}</p>
				{/if}
				<ul class="grid gap-2">
					{#each d.attention as a, i (i)}
						<li
							class="grid gap-0.5 rounded-lg border border-[var(--border)] px-3 py-2 text-sm"
							data-kind={a.kind}
						>
							<span class="flex items-center justify-between gap-2">
								<strong class={a.severity >= 3 ? 'text-red-600 dark:text-red-400' : ''}
									>{attentionLabel[a.kind]()}</strong
								>
								{#if a.amount}<span class="tabular-nums">{money(a.amount, d.currency, locale)}</span
									>{/if}
							</span>
							{#if a.lease_id}
								<a href={leaseHref(a.lease_id)}>{a.label}</a>
							{:else}
								<span>{a.label}</span>
							{/if}
							<span class="text-xs text-[var(--muted)]"
								>{a.city}{#if a.date}<span> · </span>{fmtDate(a.date, locale)}{/if}</span
							>
						</li>
					{/each}
				</ul>
			</Card>

			<Card title={m.pf_concentration()} testid="pf-concentration">
				<dl class="grid gap-2 text-sm">
					{#if d.concentration.top_city}
						<div>
							<dt class="text-[var(--muted)]">{m.pf_top_city()}</dt>
							<dd>
								{d.concentration.top_city.name || m.pf_unknown_city()} · {pct(
									d.concentration.top_city.share
								)} %
							</dd>
						</div>
					{/if}
					{#if d.concentration.top_tenant}
						<div>
							<dt class="text-[var(--muted)]">{m.pf_top_tenant()}</dt>
							<dd>
								{d.concentration.top_tenant.name} · {pct(d.concentration.top_tenant.share)} %
							</dd>
						</div>
					{/if}
					{#if d.concentration.ending_peak}
						<div>
							<dt class="text-[var(--muted)]">{m.pf_ending_peak()}</dt>
							<dd>
								{m.pf_ending_peak_value({
									period: d.concentration.ending_peak.name,
									count: d.concentration.ending_peak.count,
									share: pct(d.concentration.ending_peak.share)
								})}
							</dd>
						</div>
					{/if}
					<div>
						<dt class="text-[var(--muted)]">{m.pf_hhi()}</dt>
						<dd>{d.concentration.hhi.toLocaleString(locale === 'en' ? 'en-GB' : 'cs-CZ')}</dd>
					</div>
				</dl>
			</Card>
		</div>
	</div>
{/if}
