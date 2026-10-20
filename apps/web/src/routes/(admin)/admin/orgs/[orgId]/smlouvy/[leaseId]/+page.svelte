<script lang="ts">
	import { enhance } from '$app/forms';
	import { m } from '#lib/paraglide/messages.js';
	import { getLocale, localizeHref } from '#lib/paraglide/runtime.js';
	import { fmtDate } from '#lib/labels.js';
	import Alert from '#lib/components/Alert.svelte';
	import Button from '#lib/components/Button.svelte';
	import Card from '#lib/components/Card.svelte';
	import ImportedLeasePanel from '#lib/components/ImportedLeasePanel.svelte';
	import LandlordNoticeForm from '#lib/components/LandlordNoticeForm.svelte';
	import LeaseForm from '#lib/components/LeaseForm.svelte';
	import LeasePayments from '#lib/components/LeasePayments.svelte';
	import LeaseSignForm from '#lib/components/LeaseSignForm.svelte';
	import LeaseSummary from '#lib/components/LeaseSummary.svelte';
	import LeaseRisk from '#lib/components/portfolio/LeaseRisk.svelte';
	import type { PageProps } from './$types';

	let { data, form, params }: PageProps = $props();
	const locale = getLocale();
	const d = $derived(data.detail);
	const l = $derived(d.lease);
	const me = $derived(d.parties.find((p) => p.me));
	const imported = $derived(l.origin === 'imported');
	// An imported lease was signed on paper: no drafting, proposal or signing here.
	const editable = $derived(!imported && (l.state === 'draft' || l.state === 'negotiating'));
	// Errors of the scan and invite forms are shown next to them.
	const local = $derived(
		!!form && ('noticeError' in form || 'scanError' in form || 'inviteError' in form)
	);
	const values = $derived({
		template: l.template,
		starts_on: l.starts_on,
		ends_on: l.ends_on ?? '',
		rent: l.rent_amount / 100,
		services: d.services_amount / 100,
		deposit: d.deposit_amount / 100,
		due_day: d.due_day,
		notice_months: d.notice_months,
		payee_iban: d.payee_iban,
		payee_name: d.payee_name,
		property_address: l.property_address,
		unit_label: l.unit_label ?? '',
		clauses: d.clauses,
		parties: d.parties
			.filter((p) => p.role !== 'landlord')
			.map((p) => ({ name: p.name, email: p.email ?? '', role: p.role, share: p.share_bps / 100 }))
	});
</script>

<svelte:head><title>{l.property_address} · {m.app_name()}</title></svelte:head>
<p class="mb-2 text-sm">
	<a href={localizeHref(`/admin/orgs/${params.orgId}/smlouvy`)}>← {m.lease_title()}</a>
</p>
{#if form?.error && !local}<div class="mb-4">
		<Alert kind="error">{form.error}</Alert>
	</div>{/if}
<div class="grid gap-6 lg:grid-cols-[2fr_1fr]">
	<div class="grid content-start gap-6">
		<LeaseSummary detail={d} chain={data.chain} {locale} />
		{#if data.shares.length}
			<Card title={m.lease_payments()}>
				<LeasePayments
					shares={data.shares}
					landlord={true}
					{locale}
					revolut={data.revolut}
					revolutResult={form && 'revolut' in form ? form : null}
					connectHref={localizeHref(`/admin/orgs/${params.orgId}/fakturace#revolut`)}
				/>
				<p class="mt-3 text-sm">
					<a href={`/admin/orgs/${params.orgId}/smlouvy/${l.id}/ledger.csv`}
						>{m.lease_ledger_csv()}</a
					>
				</p>
			</Card>
		{/if}
		{#if editable}
			<Card title={m.lease_save()}>
				<form
					method="POST"
					action="?/update"
					use:enhance={() =>
						({ update }) =>
							update({ reset: false })}
				>
					<LeaseForm {values} submit={m.lease_save()} />
				</form>
			</Card>
		{/if}
	</div>
	<div class="grid content-start gap-4">
		<LeaseRisk risk={data.risk} {locale} />
		{#if d.change_request && l.state === 'negotiating'}
			<Alert kind="info">{m.lease_change_request()}: „{d.change_request}“</Alert>
		{/if}
		{#if editable}
			<form method="POST" action="?/propose" use:enhance>
				<Button type="submit">{m.lease_propose()}</Button>
			</form>
		{/if}
		{#if imported}
			<ImportedLeasePanel
				detail={d}
				{locale}
				scanError={form && 'scanError' in form ? form.error : null}
				scanned={!!form && 'scanned' in form}
				inviteError={form && 'inviteError' in form && form.inviteError
					? [form.inviteError, form.error]
					: null}
				invited={form && 'invited' in form ? form.invited : null}
			/>
		{/if}
		{#if !imported && l.state === 'proposed' && me && !me.signed_at}
			<LeaseSignForm providers={d.sign_providers} />
		{/if}
		{#if form && 'endsOn' in form && form.endsOn}
			<Alert kind="success"
				><span data-testid="notice-done"
					>{m.lease_notice_done({ date: fmtDate(form.endsOn, locale) })}</span
				></Alert
			>
		{/if}
		{#if l.state === 'active' || l.state === 'signed'}
			<Card title={m.lease_notice_landlord()}>
				<LandlordNoticeForm
					endsOn={l.ends_on}
					error={form && 'noticeError' in form ? form.error : null}
				/>
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
