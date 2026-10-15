<script lang="ts">
	import { enhance } from '$app/forms';
	import { m } from '#lib/paraglide/messages.js';
	import { formatMoney } from '#lib/catalog.js';
	import { fmtDate } from '#lib/labels.js';
	import { kindLabel } from '#lib/leasing.js';
	import Button from '#lib/components/Button.svelte';
	import type { RevolutState } from '#lib/billing.js';

	type Share = {
		id: string;
		kind: string;
		period: string;
		due_on: string;
		amount: number;
		paid_amount: number;
		party_name: string;
		mine: boolean;
		status: string;
		qr: string;
	};
	type RevolutResult = { revolut?: 'off' | 'connect' | 'error'; shareId?: string } | null;
	let {
		shares,
		landlord,
		locale,
		revolut = 'off',
		revolutResult = null,
		connectHref = ''
	}: {
		shares: Share[];
		landlord: boolean;
		locale: string;
		/** Revolut payment link availability (tenants: 'on' until the api says otherwise). */
		revolut?: RevolutState;
		/** Result of the last ?/revolut action. */
		revolutResult?: RevolutResult;
		/** Where a landlord connects Revolut (billing page). */
		connectHref?: string;
	} = $props();
	const today = new Date().toISOString().slice(0, 10);
	const noteId = $props.id();
	// 403/404 = flag off → hide; 409 = landlord has no Revolut account.
	const state = $derived<RevolutState>(
		revolutResult?.revolut === 'off'
			? 'off'
			: revolutResult?.revolut === 'connect'
				? landlord
					? 'connect'
					: 'off'
				: revolut
	);
	const tenantUnavailable = $derived(!landlord && revolutResult?.revolut === 'connect');
</script>

{#snippet revolutButton(id: string)}
	<!-- Plain POST: the action redirects to the payment page on another origin. -->
	<form method="POST" action="?/revolut">
		<input type="hidden" name="share_id" value={id} />
		<Button type="submit" variant="secondary" aria-describedby={noteId} data-testid="revolut-pay"
			>{m.billing_revolut_pay()}</Button
		>
	</form>
	{#if revolutResult?.revolut === 'error' && revolutResult.shareId === id}
		<p class="text-xs text-red-700 dark:text-red-400" role="alert">{m.billing_revolut_error()}</p>
	{/if}
{/snippet}

<div class="overflow-x-auto">
	<table class="w-full text-sm" data-testid="payments">
		<thead>
			<tr class="text-left text-[var(--muted)]">
				<th class="py-1 pr-3">{m.lease_payment_due()}</th>
				<th class="py-1 pr-3">{m.lease_payment_who()}</th>
				<th class="py-1 pr-3 text-right">{m.lease_payment_amount()}</th>
				<th class="py-1 pr-3 text-right">{m.lease_payment_paid()}</th>
				<th></th>
			</tr>
		</thead>
		<tbody>
			{#each shares as s (s.id)}
				{@const open = s.paid_amount < s.amount}
				<tr
					class="border-t border-[var(--border)] {open && s.due_on <= today ? 'text-red-700' : ''}"
					data-testid="share"
				>
					<td class="py-1.5 pr-3"
						>{fmtDate(s.due_on, locale)} · {kindLabel[s.kind]()}
						{s.period}</td
					>
					<td class="py-1.5 pr-3">{s.party_name}</td>
					<td class="py-1.5 pr-3 text-right">{formatMoney(s.amount, locale)} Kč</td>
					<td class="py-1.5 pr-3 text-right" data-testid="share-paid"
						>{formatMoney(s.paid_amount, locale)} Kč</td
					>
					<td class="py-1.5">
						{#if open && landlord}
							<div class="flex flex-wrap gap-2">
								<form method="POST" action="?/paid" use:enhance>
									<input type="hidden" name="share_id" value={s.id} />
									<Button type="submit" variant="secondary">{m.lease_mark_paid()}</Button>
								</form>
								{#if state === 'on'}{@render revolutButton(s.id)}{/if}
							</div>
						{:else if open && (s.qr || state === 'on')}
							<div class="flex flex-wrap items-start gap-2">
								{#if s.qr}
									<details>
										<summary class="cursor-pointer">{m.lease_pay_qr()}</summary>
										<img
											src={s.qr}
											alt={m.lease_pay_qr()}
											width="200"
											height="200"
											data-testid="qr"
										/>
									</details>
								{/if}
								{#if state === 'on' && s.mine}{@render revolutButton(s.id)}{/if}
							</div>
						{:else if !open}✓{/if}
					</td>
				</tr>
			{/each}
		</tbody>
	</table>
</div>
{#if state === 'on'}
	<p id={noteId} class="mt-2 text-xs text-[var(--muted)]">{m.billing_revolut_note()}</p>
{:else if state === 'connect' && landlord}
	<p class="mt-2 text-sm" role="status" data-testid="revolut-connect-hint">
		{m.billing_revolut_connect_hint()}
		{#if connectHref}<a href={connectHref}>{m.billing_revolut_connect_link()}</a>{/if}
	</p>
{/if}
{#if tenantUnavailable}
	<p class="mt-2 text-sm" role="status" data-testid="revolut-unavailable">
		{m.billing_revolut_unavailable()}
	</p>
{/if}
