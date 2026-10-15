<script lang="ts">
	import { enhance } from '$app/forms';
	import { invalidateAll } from '$app/navigation';
	import { page } from '$app/state';
	import { m } from '#lib/paraglide/messages.js';
	import { getLocale, localizeHref } from '#lib/paraglide/runtime.js';
	import { fmtDate, fmtDateTime } from '#lib/labels.js';
	import { fmtAmount, orderStatusClass, orderStatusLabel } from '#lib/billing.js';
	import Alert from '#lib/components/Alert.svelte';
	import Button from '#lib/components/Button.svelte';
	import Card from '#lib/components/Card.svelte';
	import Field from '#lib/components/Field.svelte';
	import type { PageProps } from './$types';

	let { data, form, params }: PageProps = $props();
	const locale = getLocale();
	const paid = $derived(data.paidOrder);
	const processing = $derived(data.returned && (!paid || paid.status === 'pending'));
	const invoiceOf = $derived(Object.fromEntries(data.invoices.map((i) => [i.order_id, i])));
	const pdfHref = (id: string) =>
		localizeHref(`/admin/orgs/${params.orgId}/fakturace/faktury/${id}.pdf`);
	const select =
		'rounded-lg border border-[var(--border)] bg-[var(--surface)] px-3 py-2 text-[var(--text)]';

	// The order turns paid when the provider's webhook arrives: poll for a while.
	let polls = $state(0);
	$effect(() => {
		if (!processing || polls >= 30) return;
		const id = setTimeout(() => {
			polls += 1;
			invalidateAll();
		}, 2000);
		return () => clearTimeout(id);
	});
</script>

<svelte:head><title>{m.billing_title()} · {data.orgName}</title></svelte:head>

<div class="grid gap-6">
	<div>
		<a class="text-sm" href={localizeHref(`/admin/orgs/${params.orgId}`)}>← {data.orgName}</a>
		<h1 class="text-2xl font-semibold">{m.billing_title()}</h1>
		<p class="text-sm text-[var(--muted)]">{m.billing_intro()}</p>
	</div>

	<!-- Persistent live region: the status change after the webhook is announced. -->
	<div aria-live="polite" aria-atomic="true">
		{#if data.returned}
			{#if processing}
				<div
					class="rounded-lg border border-amber-300 bg-amber-50 px-4 py-3 text-sm text-amber-950 dark:border-amber-800 dark:bg-amber-950 dark:text-amber-100"
					data-testid="billing-pending"
				>
					{m.billing_processing()}
					<a href={page.url.pathname + page.url.search} data-sveltekit-reload
						>{m.billing_reload()}</a
					>
				</div>
			{:else if paid?.status === 'paid'}
				<div
					class="rounded-lg border border-emerald-300 bg-emerald-50 px-4 py-3 text-sm text-emerald-950 dark:border-emerald-800 dark:bg-emerald-950 dark:text-emerald-100"
					data-testid="billing-paid"
				>
					{m.billing_paid_banner({ listing: paid.listing_title })}
				</div>
			{:else if paid}
				<div
					class="rounded-lg border border-red-300 bg-red-50 px-4 py-3 text-sm text-red-950 dark:border-red-800 dark:bg-red-950 dark:text-red-100"
					data-testid="billing-failed"
				>
					{m.billing_failed_banner()}
				</div>
			{/if}
		{/if}
	</div>
	{#if data.error}<Alert kind="error">{data.error}</Alert>{/if}

	<Card title={m.billing_orders()} testid="orders">
		{#if data.orders.length === 0}
			<p class="text-sm text-[var(--muted)]">{m.billing_orders_none()}</p>
		{:else}
			<div class="overflow-x-auto">
				<table class="w-full text-left text-sm">
					<thead class="text-[var(--muted)]">
						<tr>
							<th class="py-1 pr-3">{m.billing_col_created()}</th>
							<th class="pr-3">{m.billing_col_listing()}</th>
							<th class="pr-3">{m.billing_col_product()}</th>
							<th class="pr-3">{m.billing_col_start()}</th>
							<th class="pr-3 text-right">{m.billing_gross()}</th>
							<th class="pr-3">{m.billing_col_status()}</th>
							<th>{m.billing_col_invoice()}</th>
						</tr>
					</thead>
					<tbody>
						{#each data.orders as o (o.id)}
							{@const inv = invoiceOf[o.id]}
							<tr
								class="border-t border-[var(--border)]"
								data-testid="order-row"
								data-status={o.status}
							>
								<td class="py-1.5 pr-3 whitespace-nowrap">{fmtDateTime(o.created_at, locale)}</td>
								<td class="pr-3">
									<a href={localizeHref(`/admin/orgs/${params.orgId}/listings/${o.listing_id}`)}
										>{o.listing_title}</a
									>
								</td>
								<td class="pr-3"><code>{o.product_code}</code></td>
								<td class="pr-3 whitespace-nowrap">{fmtDate(o.starts_at, locale)}</td>
								<td class="pr-3 text-right whitespace-nowrap"
									>{fmtAmount(o.gross_amount, o.currency, locale)}</td
								>
								<td class="pr-3">
									<span
										class="rounded-full px-2 py-0.5 text-xs font-medium whitespace-nowrap {orderStatusClass[
											o.status
										]}"
										data-testid="order-status">{orderStatusLabel[o.status]()}</span
									>
								</td>
								<td>
									{#if inv}<a href={pdfHref(inv.id)} download>{inv.number}</a>{:else}—{/if}
								</td>
							</tr>
						{/each}
					</tbody>
				</table>
			</div>
		{/if}
	</Card>

	<Card title={m.billing_invoices()} testid="invoices">
		{#if data.invoices.length === 0}
			<p class="text-sm text-[var(--muted)]">{m.billing_invoices_none()}</p>
		{:else}
			<div class="overflow-x-auto">
				<table class="w-full text-left text-sm">
					<thead class="text-[var(--muted)]">
						<tr>
							<th class="py-1 pr-3">{m.billing_col_number()}</th>
							<th class="pr-3">{m.billing_col_issued()}</th>
							<th class="pr-3">{m.billing_col_taxable()}</th>
							<th class="pr-3 text-right">{m.billing_net()}</th>
							<th class="pr-3 text-right">{m.billing_vat()}</th>
							<th class="pr-3 text-right">{m.billing_gross()}</th>
							<th><span class="sr-only">{m.billing_col_download()}</span></th>
						</tr>
					</thead>
					<tbody>
						{#each data.invoices as i (i.id)}
							<tr class="border-t border-[var(--border)]" data-testid="invoice-row">
								<td class="py-1.5 pr-3 font-medium" data-testid="invoice-number">{i.number}</td>
								<td class="pr-3 whitespace-nowrap">{fmtDate(i.issued_on, locale)}</td>
								<td class="pr-3 whitespace-nowrap">{fmtDate(i.taxable_supply_on, locale)}</td>
								<td class="pr-3 text-right whitespace-nowrap"
									>{fmtAmount(i.net_amount, i.currency, locale)}</td
								>
								<td class="pr-3 text-right whitespace-nowrap"
									>{fmtAmount(i.vat_amount, i.currency, locale)}</td
								>
								<td class="pr-3 text-right whitespace-nowrap"
									>{fmtAmount(i.gross_amount, i.currency, locale)}</td
								>
								<td>
									<a
										href={pdfHref(i.id)}
										download
										data-testid="invoice-pdf"
										aria-label={m.billing_invoice_pdf_label({ number: i.number })}
										>{m.billing_invoice_pdf()}</a
									>
								</td>
							</tr>
						{/each}
					</tbody>
				</table>
			</div>
		{/if}
	</Card>

	{#if data.revolut}
		<section id="revolut" class="scroll-mt-4">
			<Card title={m.billing_revolut_title()} testid="revolut">
				<p class="mb-3 text-sm text-[var(--muted)]">{m.billing_revolut_intro()}</p>
				{#if form?.error}<div class="mb-3"><Alert kind="error">{form.error}</Alert></div>{/if}
				{#if form?.revolutSaved}<div class="mb-3">
						<Alert kind="success">{m.billing_revolut_saved()}</Alert>
					</div>{/if}
				{#if form?.revolutRemoved}<div class="mb-3">
						<Alert kind="success">{m.billing_revolut_removed()}</Alert>
					</div>{/if}
				<p class="mb-3 text-sm" data-testid="revolut-status">
					{#if data.revolut.connected}
						<strong>{m.billing_revolut_connected()}</strong>
						· {data.revolut.mode === 'live'
							? m.billing_revolut_mode_live()
							: m.billing_revolut_mode_sandbox()}
						{#if data.revolut.connected_at}· {fmtDateTime(data.revolut.connected_at, locale)}{/if}
					{:else}
						{m.billing_revolut_not_connected()}
					{/if}
				</p>
				{#if data.manage}
					<form
						method="POST"
						action="?/revolutConnect"
						use:enhance
						class="grid max-w-md gap-3"
						data-testid="revolut-form"
					>
						<Field
							label={m.billing_revolut_api_key()}
							name="api_key"
							type="password"
							autocomplete="off"
							required
							hint={m.billing_revolut_api_key_hint()}
							aria-invalid={form?.revolutError ? 'true' : undefined}
						/>
						<label class="grid gap-1 text-sm font-medium">
							{m.billing_revolut_mode()}
							<select name="mode" class={select}>
								<option value="sandbox" selected={(form?.mode ?? data.revolut.mode) !== 'live'}
									>{m.billing_revolut_mode_sandbox()}</option
								>
								<option value="live" selected={(form?.mode ?? data.revolut.mode) === 'live'}
									>{m.billing_revolut_mode_live()}</option
								>
							</select>
						</label>
						<div>
							<Button type="submit"
								>{data.revolut.connected
									? m.billing_revolut_update()
									: m.billing_revolut_connect()}</Button
							>
						</div>
					</form>
					{#if data.revolut.connected}
						<form method="POST" action="?/revolutDisconnect" use:enhance class="mt-3">
							<Button type="submit" variant="danger">{m.billing_revolut_disconnect()}</Button>
						</form>
					{/if}
				{/if}
			</Card>
		</section>
	{/if}
</div>
