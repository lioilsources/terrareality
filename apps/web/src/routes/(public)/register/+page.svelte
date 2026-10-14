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

<svelte:head><title>{m.register_title()} · {m.app_name()}</title></svelte:head>

<div class="mx-auto grid max-w-md gap-6">
	<h1 class="text-2xl font-semibold">{m.register_title()}</h1>
	<Card>
		<form
			method="POST"
			action="?next={encodeURIComponent(data.next)}"
			use:enhance
			class="grid gap-4"
		>
			{#if form?.error}<Alert kind="error">{form.error}</Alert>{/if}
			<Field
				label={m.field_name()}
				name="display_name"
				autocomplete="name"
				required
				maxlength={120}
				value={form?.displayName ?? ''}
			/>
			<Field
				label={m.field_email()}
				name="email"
				type="email"
				autocomplete="email"
				required
				value={form?.email ?? ''}
			/>
			<Field
				label={m.field_password()}
				name="password"
				type="password"
				autocomplete="new-password"
				required
				minlength={10}
				hint={m.password_hint()}
			/>
			<label class="flex items-start gap-2 text-sm"
				><input type="checkbox" name="terms" required class="mt-1" /> {m.register_terms()}</label
			>
			<label class="flex items-start gap-2 text-sm"
				><input type="checkbox" name="privacy" required class="mt-1" />
				{m.register_privacy()}</label
			>
			<label class="flex items-start gap-2 text-sm"
				><input type="checkbox" name="marketing" class="mt-1" /> {m.register_marketing()}</label
			>
			<Button type="submit">{m.register_submit()}</Button>
			<p class="text-sm">
				{m.register_have_account()} <a href={localizeHref('/login')}>{m.nav_login()}</a>
			</p>
		</form>
	</Card>
</div>
