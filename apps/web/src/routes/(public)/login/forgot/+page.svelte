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
	<h1 class="text-2xl font-semibold">{m.forgot_title()}</h1>
	<Card>
		<form method="POST" use:enhance class="grid gap-4">
			{#if form?.sent}<Alert kind="success">{m.forgot_sent()}</Alert>{/if}
			{#if form?.error}<Alert kind="error">{form.error}</Alert>{/if}
			<Field label={m.field_email()} name="email" type="email" autocomplete="email" required />
			<Button type="submit">{m.forgot_submit()}</Button>
		</form>
	</Card>
</div>
