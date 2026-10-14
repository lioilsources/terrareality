<script lang="ts">
	import { enhance } from '$app/forms';
	import { m } from '#lib/paraglide/messages.js';
	import { getLocale, localizeHref } from '#lib/paraglide/runtime.js';
	import { fmtDate } from '#lib/labels.js';
	import { isirLabel, levelLabel } from '#lib/applications.js';
	import Alert from '#lib/components/Alert.svelte';
	import Button from '#lib/components/Button.svelte';
	import Card from '#lib/components/Card.svelte';
	import type { PageProps } from './$types';

	let { data, form }: PageProps = $props();
	const locale = getLocale();
	const p = $derived(data.passport);
</script>

<svelte:head><title>{m.pass_title()} · {m.app_name()}</title></svelte:head>
<Card title={m.pass_title()} testid="passport">
	<p class="mb-4 text-sm text-[var(--muted)]">{m.pass_lead()}</p>
	{#if form?.error}<div class="mb-4"><Alert kind="error">{form.error}</Alert></div>{/if}
	<dl class="grid gap-6">
		<div>
			<dt class="font-semibold">{m.pass_verification()}</dt>
			<dd class="mt-1 flex flex-wrap items-center gap-3">
				<span data-testid="pass-level">{levelLabel[p.verification_level]()}</span>
				{#if p.verification_level !== 'identity'}
					<a href={localizeHref('/admin/settings/profile')}>{m.pass_verify_cta()}</a>
				{/if}
			</dd>
		</div>
		<div>
			<dt class="font-semibold">{m.pass_income()}</dt>
			<dd class="mt-1 grid gap-2">
				<p class="text-sm text-[var(--muted)]">{m.pass_income_hint()}</p>
				<p data-testid="pass-income">
					{#if p.income_proof_name}{p.income_proof_name} ·
						{fmtDate(p.income_uploaded_at!, locale)}{:else}{m.pass_income_none()}{/if}
				</p>
				<div class="flex flex-wrap gap-3">
					<form
						method="POST"
						action="?/upload"
						enctype="multipart/form-data"
						use:enhance
						class="flex gap-2"
					>
						<input
							type="file"
							name="file"
							required
							accept="application/pdf,image/jpeg,image/png"
							aria-label={m.pass_income()}
							class="text-sm"
						/>
						<Button type="submit" variant="secondary">{m.pass_income_upload()}</Button>
					</form>
					{#if p.income_proof_name}
						<form method="POST" action="?/remove" use:enhance>
							<Button type="submit" variant="danger">{m.pass_income_remove()}</Button>
						</form>
					{/if}
				</div>
			</dd>
		</div>
		<div>
			<dt class="font-semibold">{m.pass_isir()}</dt>
			<dd class="mt-1 grid gap-2">
				<p class="text-sm text-[var(--muted)]">{m.pass_isir_hint()}</p>
				<p data-testid="pass-isir">
					{isirLabel[p.insolvency]()}
					{#if p.insolvency_checked_at}· {fmtDate(p.insolvency_checked_at, locale)}{/if}
				</p>
				<form method="POST" action="?/isir" use:enhance>
					<Button type="submit" variant="secondary" disabled={p.verification_level !== 'identity'}
						>{m.pass_isir_check()}</Button
					>
				</form>
			</dd>
		</div>
	</dl>
</Card>
