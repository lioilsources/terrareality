<script lang="ts">
	import { enhance } from '$app/forms';
	import { m } from '#lib/paraglide/messages.js';
	import { localizeHref } from '#lib/paraglide/runtime.js';
	import Alert from '#lib/components/Alert.svelte';
	import Button from '#lib/components/Button.svelte';
	import Card from '#lib/components/Card.svelte';
	import Field from '#lib/components/Field.svelte';
	import type { PageProps } from './$types';

	let { data, form }: PageProps = $props();
</script>

<div class="mx-auto grid max-w-md gap-6">
	<h1 class="text-2xl font-semibold">{m.reset_title()}</h1>
	<Card>
		{#if form?.done}
			<Alert kind="success">{m.reset_done()}</Alert>
			<a class="mt-4 inline-block" href={localizeHref('/login')}>{m.nav_login()}</a>
		{:else}
			<form method="POST" use:enhance class="grid gap-4">
				{#if form?.error}<Alert kind="error">{form.error}</Alert>{/if}
				<input type="hidden" name="token" value={data.token} />
				<Field
					label={m.field_password_new()}
					name="password"
					type="password"
					autocomplete="new-password"
					required
					minlength={12}
					hint={m.password_hint()}
				/>
				<Button type="submit">{m.reset_submit()}</Button>
			</form>
		{/if}
	</Card>
</div>
