<script lang="ts">
	import { enhance } from '$app/forms';
	import { m } from '#lib/paraglide/messages.js';
	import Alert from '#lib/components/Alert.svelte';
	import Button from '#lib/components/Button.svelte';
	import Card from '#lib/components/Card.svelte';
	import type { PageProps } from './$types';

	let { data, form }: PageProps = $props();
</script>

<div class="mx-auto grid max-w-md gap-6">
	<h1 class="text-2xl font-semibold">{m.login_title()}</h1>
	<Card>
		<form method="POST" use:enhance class="grid gap-4">
			{#if form?.error}<Alert kind="error">{form.error}</Alert>{/if}
			<input type="hidden" name="token" value={data.token} />
			<Button type="submit">{m.login_submit()}</Button>
		</form>
	</Card>
</div>
