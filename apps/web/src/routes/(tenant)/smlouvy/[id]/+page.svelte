<script lang="ts">
	import { enhance } from '$app/forms';
	import { m } from '#lib/paraglide/messages.js';
	import { getLocale } from '#lib/paraglide/runtime.js';
	import { field } from '#lib/applications.js';
	import Alert from '#lib/components/Alert.svelte';
	import Button from '#lib/components/Button.svelte';
	import Card from '#lib/components/Card.svelte';
	import LeasePayments from '#lib/components/LeasePayments.svelte';
	import LeaseSummary from '#lib/components/LeaseSummary.svelte';
	import LeaseRisk from '#lib/components/portfolio/LeaseRisk.svelte';
	import type { PageProps } from './$types';

	let { data, form }: PageProps = $props();
	const locale = getLocale();
	const d = $derived(data.detail);
	const l = $derived(d.lease);
	const me = $derived(d.parties.find((p) => p.me));
	const mine = $derived(data.shares.filter((s) => s.mine));
</script>

<svelte:head><title>{l.property_address} · {m.app_name()}</title></svelte:head>
{#if form?.error}<div class="mb-4"><Alert kind="error">{form.error}</Alert></div>{/if}
<div class="grid gap-6 lg:grid-cols-[2fr_1fr]">
	<div class="grid content-start gap-6">
		<LeaseSummary detail={d} chain={data.chain} {locale} />
		{#if mine.length}
			<Card title={m.lease_my_payments()} testid="my-payments">
				<LeasePayments shares={mine} landlord={false} {locale} />
			</Card>
		{/if}
	</div>
	<div class="grid content-start gap-4">
		<LeaseRisk risk={data.risk} {locale} />
		{#if l.state === 'proposed' && me && !me.signed_at}
			<Card>
				<form method="POST" action="?/sign" use:enhance>
					<Button type="submit">{m.lease_sign()}</Button>
				</form>
				<details class="mt-4">
					<summary class="cursor-pointer text-sm">{m.lease_request_changes()}</summary>
					<form method="POST" action="?/changes" use:enhance class="mt-2 grid gap-2">
						<label class="grid gap-1 text-sm"
							>{m.lease_request_comment()}<textarea
								name="comment"
								required
								rows="3"
								maxlength="2000"
								class={field}></textarea></label
						>
						<Button type="submit" variant="secondary">{m.lease_send()}</Button>
					</form>
				</details>
			</Card>
		{/if}
		{#if l.state === 'active' || l.state === 'signed'}
			<Card title={m.lease_notice()}>
				{#if form?.endsOn}<Alert kind="success">{m.lease_notice_done({ date: form.endsOn })}</Alert
					>{/if}
				<form method="POST" action="?/notice" use:enhance class="grid gap-2">
					<label class="grid gap-1 text-sm"
						>{m.lease_notice_on()}<input
							type="date"
							name="delivered_on"
							required
							class={field}
						/></label
					>
					<Button type="submit" variant="danger">{m.lease_notice()}</Button>
				</form>
			</Card>
		{/if}
		{#if l.state === 'terminated'}
			<form method="POST" action="?/settle" use:enhance>
				<Button type="submit">{m.lease_settle()}</Button>
			</form>
			{#if form?.settled}<Alert kind="success">{m.lease_settled()}</Alert>{/if}
		{/if}
	</div>
</div>
