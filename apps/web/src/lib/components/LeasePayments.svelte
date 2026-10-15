<script lang="ts">
	import { enhance } from '$app/forms';
	import { m } from '#lib/paraglide/messages.js';
	import { formatMoney } from '#lib/catalog.js';
	import { fmtDate } from '#lib/labels.js';
	import { kindLabel } from '#lib/leasing.js';
	import Button from '#lib/components/Button.svelte';

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
	let { shares, landlord, locale }: { shares: Share[]; landlord: boolean; locale: string } =
		$props();
	const today = new Date().toISOString().slice(0, 10);
</script>

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
							<form method="POST" action="?/paid" use:enhance>
								<input type="hidden" name="share_id" value={s.id} />
								<Button type="submit" variant="secondary">{m.lease_mark_paid()}</Button>
							</form>
						{:else if open && s.qr}
							<details>
								<summary class="cursor-pointer">{m.lease_pay_qr()}</summary>
								<img src={s.qr} alt={m.lease_pay_qr()} width="200" height="200" data-testid="qr" />
							</details>
						{:else if !open}✓{/if}
					</td>
				</tr>
			{/each}
		</tbody>
	</table>
</div>
