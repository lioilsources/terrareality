<script lang="ts">
	import { enhance } from '$app/forms';
	import { m } from '#lib/paraglide/messages.js';
	import Alert from '#lib/components/Alert.svelte';
	import Card from '#lib/components/Card.svelte';
	import LeaseForm from '#lib/components/LeaseForm.svelte';
	import type { PageProps } from './$types';

	let { data, form }: PageProps = $props();
	const today = new Date().toISOString().slice(0, 10);
</script>

<svelte:head><title>{m.lease_new()} · {m.app_name()}</title></svelte:head>
<Card title={m.lease_new()}>
	<p class="mb-4 text-sm text-[var(--muted)]">{m.lease_draft_note()}</p>
	{#if form?.error}<div class="mb-3"><Alert kind="error">{form.error}</Alert></div>{/if}
	<form
		method="POST"
		use:enhance={() =>
			({ update }) =>
				update({ reset: false })}
	>
		<LeaseForm
			applicationId={data.applicationId}
			values={{ starts_on: today, payee_name: data.payeeName }}
			submit={m.lease_create()}
		/>
	</form>
</Card>
