<script lang="ts">
	import { enhance } from '$app/forms';
	import { m } from '#lib/paraglide/messages.js';
	import { levelLabel, roleLabel } from '#lib/labels.js';
	import Alert from '#lib/components/Alert.svelte';
	import Button from '#lib/components/Button.svelte';
	import Card from '#lib/components/Card.svelte';
	import Field from '#lib/components/Field.svelte';
	import type { PageProps } from './$types';

	let { data, form }: PageProps = $props();
	const u = $derived(data.detail.user);
</script>

<div class="grid gap-6">
	<h1 class="text-2xl font-semibold">{u.display_name || u.email}</h1>
	<Card>
		<dl class="grid gap-1 text-sm">
			<div>
				<dt class="inline text-[var(--muted)]">{m.field_email()}:</dt>
				<dd class="inline">{u.email}</dd>
			</div>
			<div>
				<dt class="inline text-[var(--muted)]">{m.dashboard_level()}:</dt>
				<dd class="inline">{levelLabel[u.verification_level]()}</dd>
			</div>
			<div>
				<dt class="inline text-[var(--muted)]">{m.check_mfa()}:</dt>
				<dd class="inline">{u.mfa_enabled ? '✓' : '✗'}</dd>
			</div>
		</dl>
		<h2 class="mt-4 font-semibold">{m.dashboard_orgs()}</h2>
		<ul class="mt-2 text-sm">
			{#each data.detail.organizations as o (o.organization.id)}
				<li>{o.organization.name} · {roleLabel[o.role]()}</li>
			{/each}
		</ul>
	</Card>
	{#if !u.is_staff && !u.pseudonymized}
		<Card title={m.bo_impersonate()}>
			<form method="POST" action="?/impersonate" use:enhance class="grid max-w-md gap-3">
				{#if form?.error}<Alert kind="error">{form.error}</Alert>{/if}
				<Field label={m.field_reason()} name="reason" required minlength={5} maxlength={500} />
				<Button type="submit" variant="danger">{m.bo_impersonate()}</Button>
			</form>
		</Card>
	{/if}
</div>
