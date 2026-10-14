<script lang="ts">
	import { enhance } from '$app/forms';
	import { m } from '#lib/paraglide/messages.js';
	import { getLocale } from '#lib/paraglide/runtime.js';
	import { fmtDate, fmtDateTime, gdprStatus } from '#lib/labels.js';
	import Alert from '#lib/components/Alert.svelte';
	import Button from '#lib/components/Button.svelte';
	import Card from '#lib/components/Card.svelte';
	import type { PageProps } from './$types';

	let { data, form }: PageProps = $props();
	const erasure = $derived(
		data.requests.find((r) => r.kind === 'erasure' && r.status === 'pending')
	);
</script>

<div class="grid gap-6">
	{#if form?.error}<Alert kind="error">{form.error}</Alert>{/if}
	<div class="grid gap-6 md:grid-cols-2">
		<Card title={m.privacy_export()}>
			<p class="mb-4 text-sm text-[var(--muted)]">{m.privacy_export_hint()}</p>
			<form method="POST" action="?/export" use:enhance>
				<Button type="submit">{m.privacy_export_request()}</Button>
			</form>
		</Card>
		<Card title={m.privacy_erasure()}>
			<p class="mb-4 text-sm text-[var(--muted)]">{m.privacy_erasure_hint()}</p>
			{#if erasure}
				<p class="mb-3 text-sm font-medium">
					{m.privacy_erasure_scheduled({ date: fmtDate(erasure.scheduled_at, getLocale()) })}
				</p>
				<form method="POST" action="?/cancelErase" use:enhance>
					<Button type="submit" variant="secondary">{m.privacy_erasure_cancel()}</Button>
				</form>
			{:else}
				<form method="POST" action="?/erase" use:enhance>
					<Button type="submit" variant="danger">{m.privacy_erasure_request()}</Button>
				</form>
			{/if}
		</Card>
	</div>
	<Card title={m.privacy_consents()}>
		<form method="POST" action="?/marketing" use:enhance class="flex items-center gap-3 text-sm">
			<input type="hidden" name="granted" value={String(!data.marketing)} />
			<span>{m.privacy_marketing()}: <strong>{data.marketing ? '✓' : '✗'}</strong></span>
			<Button type="submit" variant="secondary">{data.marketing ? m.revoke() : m.save()}</Button>
		</form>
	</Card>
	{#if data.requests.length}
		<Card title={m.privacy_requests()}>
			<ul class="grid gap-2" data-testid="gdpr-requests">
				{#each data.requests as r (r.id)}
					<li
						class="flex flex-wrap items-center justify-between gap-2 rounded-lg border border-[var(--border)] px-3 py-2 text-sm"
					>
						<span>
							{r.kind === 'export' ? m.gdpr_export() : m.gdpr_erasure()} · {fmtDateTime(
								r.created_at,
								getLocale()
							)} ·
							<strong>{gdprStatus[r.status]()}</strong>{r.detail ? ` · ${r.detail}` : ''}
						</span>
						{#if r.kind === 'export' && r.status === 'done'}
							<form method="POST" action="?/download">
								<input type="hidden" name="id" value={r.id} />
								<Button type="submit" variant="secondary">{m.privacy_export_download()}</Button>
							</form>
						{/if}
					</li>
				{/each}
			</ul>
		</Card>
	{/if}
</div>
