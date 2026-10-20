<script lang="ts">
	import { enhance } from '$app/forms';
	import { m } from '#lib/paraglide/messages.js';
	import Alert from '#lib/components/Alert.svelte';
	import Card from '#lib/components/Card.svelte';
	import LeaseImportForm from '#lib/components/LeaseImportForm.svelte';
	import type { PageProps } from './$types';

	let { data, form }: PageProps = $props();
	const fieldError = $derived(
		form?.error && form.field ? { field: form.field, message: form.error } : null
	);
</script>

<svelte:head><title>{m.lease_import_title()} · {m.app_name()}</title></svelte:head>
<Card title={m.lease_import_title()}>
	<p class="mb-4 text-sm text-[var(--muted)]">{m.lease_import_intro()}</p>
	{#if form?.error}<div class="mb-3">
			<Alert kind="error">{fieldError ? m.lease_import_check_fields() : form.error}</Alert>
		</div>{/if}
	<form
		method="POST"
		data-testid="lease-import-form"
		use:enhance={() =>
			({ update }) =>
				update({ reset: false })}
	>
		<LeaseImportForm
			values={{ payee_name: data.payeeName }}
			error={fieldError}
			submit={m.lease_import_submit()}
		/>
	</form>
</Card>
