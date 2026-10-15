<script lang="ts">
	import { untrack } from 'svelte';
	import { m } from '#lib/paraglide/messages.js';
	import { getLocale, localizeHref } from '#lib/paraglide/runtime.js';
	import { t } from '#lib/catalog.js';
	import { fmtDate } from '#lib/labels.js';
	import { fmtAmount, fmtVatRate, promoKindLabel } from '#lib/billing.js';
	import Alert from '#lib/components/Alert.svelte';
	import Button from '#lib/components/Button.svelte';
	import Card from '#lib/components/Card.svelte';
	import type { PageProps } from './$types';

	let { data, form }: PageProps = $props();
	const locale = getLocale();
	const l = $derived(data.listing);
	const title = $derived(t(l.title, locale) || l.unit.label);
	const tomorrow = new Date(Date.now() + 864e5).toISOString().slice(0, 10);
	// Form state survives a failed submit (the form posts without JavaScript enhancement).
	let start = $state(untrack(() => (form?.start === 'later' ? 'later' : 'now')));
	const dateId = $props.id();
	const active = $derived(data.promotions.filter((p) => p.active));
	const other = $derived(data.promotions.filter((p) => !p.active));
	const now = new Date().toISOString();
</script>

<svelte:head><title>{m.billing_promo_title()} · {title}</title></svelte:head>

<div class="grid gap-6">
	<div>
		<a class="text-sm" href={localizeHref(`/admin/orgs/${l.org_id}/listings/${l.id}`)}>← {title}</a>
		<h1 class="text-2xl font-semibold">{m.billing_promo_title()}</h1>
		<p class="text-sm text-[var(--muted)]">{m.billing_promo_intro()}</p>
	</div>

	{#if data.canceled}<Alert>{m.billing_checkout_canceled()}</Alert>{/if}
	{#if form?.error}<Alert kind="error">{form.error}</Alert>{/if}
	{#if data.error}<Alert kind="error">{data.error}</Alert>{/if}

	<Card title={m.billing_promo_buy()} testid="promo-products">
		{#if l.status !== 'published'}
			<p class="mb-3 text-sm text-[var(--muted)]">{m.billing_promo_not_published()}</p>
		{/if}
		<form method="POST" action="?/checkout" class="grid gap-5">
			<fieldset class="grid gap-3">
				<legend class="mb-2 text-sm font-medium">{m.billing_promo_choose()}</legend>
				{#if form?.missing === 'product'}
					<p class="text-sm text-red-700 dark:text-red-400" role="alert">
						{m.billing_promo_choose_required()}
					</p>
				{/if}
				<div class="grid gap-3 sm:grid-cols-2">
					{#each data.products as p (p.id)}
						<label
							class="flex cursor-pointer gap-3 rounded-lg border border-[var(--border)] p-3 has-[:checked]:border-[var(--accent)] has-[:checked]:ring-2 has-[:checked]:ring-[var(--accent)]/30 has-[:focus-visible]:outline-2 has-[:focus-visible]:outline-[var(--accent)]"
							data-testid="promo-product-{p.code}"
						>
							<input
								type="radio"
								name="product_code"
								value={p.code}
								required
								checked={form?.product_code === p.code}
								class="mt-1"
							/>
							<span class="grid gap-0.5 text-sm">
								<strong>{t(p.name, locale) || p.code}</strong>
								<span class="text-[var(--muted)]"
									>{promoKindLabel[p.kind]?.() ?? p.kind} · {m.billing_days({
										days: String(p.duration_days)
									})}</span
								>
								<span
									>{m.billing_net()}: {fmtAmount(p.net_amount, p.currency, locale)} · {m.billing_vat()}
									{fmtVatRate(p.vat_rate_bp)}: {fmtAmount(p.vat_amount, p.currency, locale)}</span
								>
								<span class="font-semibold"
									>{m.billing_gross()}: {fmtAmount(p.gross_amount, p.currency, locale)}</span
								>
							</span>
						</label>
					{:else}
						<p class="text-sm text-[var(--muted)]">{m.billing_promo_no_products()}</p>
					{/each}
				</div>
			</fieldset>

			<fieldset class="grid gap-2 text-sm">
				<legend class="mb-2 font-medium">{m.billing_promo_start()}</legend>
				<label class="flex items-center gap-2">
					<input type="radio" name="start" value="now" bind:group={start} />
					{m.billing_promo_start_now()}
				</label>
				<label class="flex items-center gap-2">
					<input type="radio" name="start" value="later" bind:group={start} />
					{m.billing_promo_start_later()}
				</label>
				{#if start === 'later'}
					<div class="grid max-w-xs gap-1 pl-6">
						<label for={dateId} class="font-medium">{m.billing_promo_start_date()}</label>
						<input
							id={dateId}
							type="date"
							name="starts_on"
							min={tomorrow}
							required
							value={form?.starts_on ?? ''}
							aria-invalid={form?.missing === 'date' ? 'true' : undefined}
							aria-describedby={form?.missing === 'date' ? `${dateId}-err` : undefined}
							class="rounded-lg border border-[var(--border)] bg-[var(--surface)] px-3 py-2"
						/>
						{#if form?.missing === 'date'}
							<p id="{dateId}-err" class="text-red-700 dark:text-red-400" role="alert">
								{m.billing_promo_date_invalid()}
							</p>
						{/if}
					</div>
				{/if}
			</fieldset>

			<p class="text-xs text-[var(--muted)]">{m.billing_promo_pay_note()}</p>
			<div>
				<Button type="submit" data-testid="promo-pay" disabled={data.products.length === 0}
					>{m.billing_promo_pay()}</Button
				>
			</div>
		</form>
	</Card>

	<Card title={m.billing_promotions()} testid="promotions">
		{#if data.promotions.length === 0}
			<p class="text-sm text-[var(--muted)]">{m.billing_promotions_none()}</p>
		{:else}
			<ul class="grid gap-2 text-sm">
				{#each [...active, ...other] as p (p.id)}
					{@const state = p.active
						? m.billing_promo_active()
						: p.starts_at > now
							? m.billing_promo_scheduled()
							: m.billing_promo_ended()}
					<li
						class="flex flex-wrap items-center justify-between gap-2 rounded-lg border border-[var(--border)] px-3 py-2"
						data-testid="promotion"
						data-active={p.active ? 'true' : 'false'}
					>
						<span
							>{promoKindLabel[p.kind]()} · {fmtDate(p.starts_at, locale)} – {fmtDate(
								p.ends_at,
								locale
							)}</span
						>
						<span
							class="rounded-full px-2 py-0.5 text-xs font-medium {p.active
								? 'bg-emerald-100 text-emerald-900 dark:bg-emerald-900/40 dark:text-emerald-100'
								: 'bg-[var(--border)]/60'}">{state}</span
						>
					</li>
				{/each}
			</ul>
		{/if}
		<p class="mt-3 text-sm">
			<a href={localizeHref(`/admin/orgs/${l.org_id}/fakturace`)}>{m.billing_title()} →</a>
		</p>
	</Card>
</div>
