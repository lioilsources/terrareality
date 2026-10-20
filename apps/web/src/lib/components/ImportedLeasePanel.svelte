<script lang="ts">
	import type { components } from '@terra/contracts';
	import { enhance } from '$app/forms';
	import { m } from '#lib/paraglide/messages.js';
	import { fmtDate } from '#lib/labels.js';
	import { field } from '#lib/applications.js';
	import { invitable, roleLabel } from '#lib/leasing.js';
	import Alert from '#lib/components/Alert.svelte';
	import Button from '#lib/components/Button.svelte';
	import Card from '#lib/components/Card.svelte';

	/**
	 * Landlord side of a lease signed on paper: the contract scan and the
	 * invitations of its tenants to the portal (they get no e-mails before).
	 */
	let {
		detail,
		locale,
		scanError = null,
		scanned = false,
		inviteError = null,
		invited = null
	}: {
		detail: components['schemas']['LeaseDetail'];
		locale: string;
		scanError?: string | null;
		scanned?: boolean;
		/** [party id, message] of a failed invitation. */
		inviteError?: [string, string] | null;
		invited?: string | null;
	} = $props();
	const tenants = $derived(detail.parties.filter((p) => p.role !== 'landlord'));
	const canInvite = $derived(invitable(detail.lease.state));
</script>

<Card title={m.lease_scan_title()}>
	<div class="grid gap-3 text-sm" data-testid="lease-scan">
		{#if detail.contract_scan_url}
			<p>
				<a href={detail.contract_scan_url} target="_blank" rel="noopener" data-testid="scan-link"
					>{m.lease_scan_download()}</a
				>
			</p>
		{:else}
			<p class="text-[var(--muted)]">{m.lease_scan_none()}</p>
		{/if}
		{#if scanned}<Alert kind="success">{m.lease_scan_done()}</Alert>{/if}
		{#if scanError}<Alert kind="error">{scanError}</Alert>{/if}
		<form
			method="POST"
			action="?/scan"
			enctype="multipart/form-data"
			use:enhance
			class="flex flex-wrap gap-2"
		>
			<input
				type="file"
				name="file"
				required
				accept="application/pdf,image/jpeg,image/png"
				aria-label={m.lease_scan_file()}
				class="text-sm"
			/>
			<Button type="submit" variant="secondary"
				>{detail.contract_scan_url ? m.lease_scan_replace() : m.lease_scan_upload()}</Button
			>
		</form>
		<p class="text-xs text-[var(--muted)]">{m.lease_scan_hint()}</p>
	</div>
</Card>

<Card title={m.lease_invite_title()}>
	<p class="mb-3 text-sm text-[var(--muted)]">{m.lease_invite_intro()}</p>
	<ul class="grid gap-3 text-sm" data-testid="lease-invites">
		{#each tenants as p (p.id)}
			<li class="grid gap-2" data-testid="lease-invite">
				<div>
					<strong>{p.name}</strong> · {roleLabel[p.role]()}
				</div>
				{#if p.has_account}
					<p class="text-emerald-700 dark:text-emerald-400" data-testid="invite-state">
						✓ {m.lease_invite_linked()}
					</p>
				{:else}
					{#if p.invited_at}<p class="text-[var(--muted)]" data-testid="invite-state">
							{m.lease_invite_sent({ date: fmtDate(p.invited_at, locale) })}
						</p>{/if}
					{#if invited === p.id}<Alert kind="success">{m.lease_invite_done()}</Alert>{/if}
					{#if inviteError?.[0] === p.id}<Alert kind="error">{inviteError[1]}</Alert>{/if}
					{#if canInvite}
						<form
							method="POST"
							action="?/invite"
							use:enhance={() =>
								({ update }) =>
									update({ reset: false })}
							class="flex flex-wrap items-end gap-2"
						>
							<input type="hidden" name="party_id" value={p.id} />
							<label class="grid flex-1 gap-1"
								>{m.lease_party_email()}<input
									type="email"
									name="email"
									required
									value={p.email ?? ''}
									class={field}
								/></label
							>
							<Button type="submit" variant={p.invited_at ? 'secondary' : 'primary'}
								>{p.invited_at ? m.lease_invite_resend() : m.lease_invite()}</Button
							>
						</form>
					{/if}
				{/if}
			</li>
		{/each}
	</ul>
</Card>
