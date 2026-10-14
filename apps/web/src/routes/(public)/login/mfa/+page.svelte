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

<div class="mx-auto grid max-w-md gap-6">
	<h1 class="text-2xl font-semibold">{m.mfa_title()}</h1>
	<Card>
		<form method="POST" use:enhance class="grid gap-4">
			<p class="text-sm text-[var(--muted)]">{m.mfa_hint()}</p>
			{#if form?.error}<Alert kind="error">{form.error}</Alert>{/if}
			<Field
				label={m.field_code()}
				name="code"
				inputmode="numeric"
				autocomplete="one-time-code"
				required
			/>
			<Button type="submit">{m.mfa_submit()}</Button>
		</form>
	</Card>
</div>
