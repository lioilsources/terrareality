<script lang="ts">
	import { enhance } from '$app/forms';
	import { m } from '#lib/paraglide/messages.js';
	import Alert from '#lib/components/Alert.svelte';
	import Button from '#lib/components/Button.svelte';
	import Card from '#lib/components/Card.svelte';
	import Field from '#lib/components/Field.svelte';
	import type { PageProps } from './$types';

	let { form }: PageProps = $props();
</script>

<div class="grid max-w-md gap-6">
	<h1 class="text-2xl font-semibold">{m.org_title_new()}</h1>
	<Card>
		<form method="POST" use:enhance class="grid gap-4">
			{#if form?.error}<Alert kind="error">{form.error}</Alert>{/if}
			<Field
				label={m.field_org_name()}
				name="name"
				required
				maxlength={200}
				value={form?.name ?? ''}
			/>
			<Field
				label={m.field_registration_no()}
				name="registration_no"
				inputmode="numeric"
				pattern={'[0-9]{6,10}'}
			/>
			<Field label={m.field_vat_no()} name="vat_no" maxlength={20} />
			<Button type="submit">{m.org_create()}</Button>
		</form>
	</Card>
</div>
