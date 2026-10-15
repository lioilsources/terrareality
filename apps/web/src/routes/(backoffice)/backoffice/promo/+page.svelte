<script lang="ts">
	import { enhance } from '$app/forms';
	import { m } from '#lib/paraglide/messages.js';
	import { getLocale } from '#lib/paraglide/runtime.js';
	import { t } from '#lib/catalog.js';
	import { fmtAmount, fmtVatRate } from '#lib/billing.js';
	import Alert from '#lib/components/Alert.svelte';
	import Button from '#lib/components/Button.svelte';
	import Card from '#lib/components/Card.svelte';
	import Field from '#lib/components/Field.svelte';
	import type { PageProps } from './$types';

	let { data, form }: PageProps = $props();
	const locale = getLocale();
	const kindLabel: Record<string, () => string> = {
		top: m.bo_promo_kind_top,
		highlight: m.bo_promo_kind_highlight,
		bundle: m.bo_promo_kind_bundle
	};
	const crowns = (minor: number) => String(minor / 100);
	const selectId = $props.id();
</script>

<svelte:head><title>{m.bo_promo()} · {m.nav_backoffice()}</title></svelte:head>

<div class="grid gap-6">
	<h1 class="text-2xl font-semibold">{m.bo_promo()}</h1>
	<p class="text-sm text-[var(--muted)]">{m.bo_promo_hint()}</p>
	{#if data.error}<Alert kind="error">{data.error}</Alert>{/if}
	{#if form?.error}<Alert kind="error">{form.error}</Alert>{/if}
	{#if form && 'invalid' in form && form.invalid}<Alert kind="error">{m.bo_promo_invalid()}</Alert
		>{/if}
	{#if form && 'saved' in form && form.saved}<Alert kind="success">{m.bo_promo_saved()}</Alert>{/if}

	<Card>
		{#if data.products.length === 0}
			<p class="text-sm text-[var(--muted)]">{m.bo_promo_empty()}</p>
		{:else}
			<div class="overflow-x-auto">
				<table class="w-full text-left text-sm" data-testid="bo-promo-products">
					<caption class="sr-only">{m.bo_promo()}</caption>
					<thead class="text-[var(--muted)]">
						<tr>
							<th scope="col" class="py-1 pr-4">{m.bo_promo_code()}</th>
							<th scope="col" class="pr-4">{m.bo_promo_name()}</th>
							<th scope="col" class="pr-4">{m.bo_promo_kind()}</th>
							<th scope="col" class="pr-4 text-right">{m.bo_promo_duration()}</th>
							<th scope="col" class="pr-4 text-right">{m.bo_promo_net()}</th>
							<th scope="col" class="pr-4 text-right">{m.bo_promo_vat()}</th>
							<th scope="col" class="pr-4 text-right">{m.bo_promo_gross()}</th>
							<th scope="col">{m.bo_promo_status()}</th>
						</tr>
					</thead>
					<tbody>
						{#each data.products as p (p.id)}
							<tr class="border-t border-[var(--border)] align-top" data-testid="bo-promo-{p.code}">
								<th scope="row" class="py-2 pr-4 font-normal"><code>{p.code}</code></th>
								<td class="py-2 pr-4">
									{t(p.name, locale)}
									<details class="mt-2">
										<summary class="cursor-pointer text-[var(--accent)]"
											>{m.bo_promo_edit({ code: p.code })}</summary
										>
										<form
											method="POST"
											action="?/update"
											use:enhance={() =>
												({ update }) =>
													update({ reset: false })}
											class="mt-2 grid max-w-md gap-2"
										>
											<input type="hidden" name="id" value={p.id} />
											<Field
												label={m.bo_promo_name_cs()}
												name="name_cs"
												value={p.name.cs}
												required
											/>
											<Field
												label={m.bo_promo_name_en()}
												name="name_en"
												value={p.name.en}
												required
											/>
											<Field
												label={m.bo_promo_duration()}
												name="duration_days"
												type="number"
												min="1"
												value={String(p.duration_days)}
												required
											/>
											<Field
												label={m.bo_promo_net()}
												name="net"
												inputmode="decimal"
												value={crowns(p.net_amount)}
												required
											/>
											<label class="flex items-center gap-2">
												<input type="checkbox" name="active" checked={p.active} />
												{m.bo_promo_active()}
											</label>
											<div>
												<Button type="submit">{m.bo_promo_save({ code: p.code })}</Button>
											</div>
										</form>
									</details>
								</td>
								<td class="py-2 pr-4">{kindLabel[p.kind]?.() ?? p.kind}</td>
								<td class="py-2 pr-4 text-right tabular-nums">{p.duration_days}</td>
								<td class="py-2 pr-4 text-right whitespace-nowrap tabular-nums"
									>{fmtAmount(p.net_amount, p.currency, locale)}</td
								>
								<td class="py-2 pr-4 text-right tabular-nums">{fmtVatRate(p.vat_rate_bp)}</td>
								<td class="py-2 pr-4 text-right whitespace-nowrap tabular-nums"
									>{fmtAmount(p.gross_amount, p.currency, locale)}</td
								>
								<td class="py-2" data-testid="bo-promo-active">
									{p.active ? m.bo_promo_active() : m.bo_promo_inactive()}
								</td>
							</tr>
						{/each}
					</tbody>
				</table>
			</div>
		{/if}
	</Card>

	<Card title={m.bo_promo_new()}>
		<form method="POST" action="?/create" use:enhance class="grid max-w-xl gap-3 sm:grid-cols-2">
			<Field label={m.bo_promo_code()} name="code" required pattern="[a-z0-9_]+" />
			<div class="grid gap-1">
				<label for={selectId} class="text-sm font-medium">{m.bo_promo_kind()}</label>
				<select
					id={selectId}
					name="kind"
					required
					class="rounded-lg border border-[var(--border)] bg-[var(--surface)] px-3 py-2 text-[var(--text)] focus:border-[var(--accent)] focus:ring-2 focus:ring-[var(--accent)]/30 focus:outline-none"
				>
					<option value="top">{m.bo_promo_kind_top()}</option>
					<option value="highlight">{m.bo_promo_kind_highlight()}</option>
					<option value="bundle">{m.bo_promo_kind_bundle()}</option>
				</select>
			</div>
			<Field label={m.bo_promo_duration()} name="duration_days" type="number" min="1" required />
			<Field label={m.bo_promo_net()} name="net" inputmode="decimal" required />
			<Field label={m.bo_promo_vat()} name="vat" inputmode="decimal" value="21" required />
			<label class="flex items-center gap-2 self-end text-sm">
				<input type="checkbox" name="active" checked />
				{m.bo_promo_active()}
			</label>
			<Field label={m.bo_promo_name_cs()} name="name_cs" required />
			<Field label={m.bo_promo_name_en()} name="name_en" required />
			<div class="sm:col-span-2">
				<Button type="submit">{m.bo_promo_create()}</Button>
			</div>
		</form>
	</Card>
</div>
