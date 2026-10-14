<script lang="ts">
	import { m } from '#lib/paraglide/messages.js';
	import { localizeHref } from '#lib/paraglide/runtime.js';
	import Alert from '#lib/components/Alert.svelte';
	import type { PageProps } from './$types';

	let { data }: PageProps = $props();
</script>

<div class="mx-auto grid max-w-md gap-4">
	<h1 class="text-2xl font-semibold">{m.verify_title()}</h1>
	{#if data.ok}
		<Alert kind="success"><span data-testid="email-verified">{m.verify_ok()}</span></Alert>
		<a href={localizeHref(data.loggedIn ? '/admin' : '/login')}
			>{data.loggedIn ? m.dashboard_title() : m.nav_login()}</a
		>
	{:else}
		<Alert kind="error">{m.verify_failed()}</Alert>
	{/if}
</div>
