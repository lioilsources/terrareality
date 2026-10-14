<script lang="ts">
	import { enhance } from '$app/forms';
	import { page } from '$app/state';
	import { m } from '#lib/paraglide/messages.js';
	import { localizeHref } from '#lib/paraglide/runtime.js';
	import { roleLabel } from '#lib/labels.js';
	import Alert from '#lib/components/Alert.svelte';
	import Button from '#lib/components/Button.svelte';
	import Card from '#lib/components/Card.svelte';
	import type { PageProps } from './$types';

	let { data, form }: PageProps = $props();
	const inv = $derived(data.invitation);
	const next = $derived(encodeURIComponent(page.url.pathname));
	const statusText: Record<string, () => string> = {
		accepted: m.invite_status_accepted,
		revoked: m.invite_status_revoked,
		expired: m.invite_status_expired
	};
</script>

<div class="mx-auto grid max-w-md gap-6">
	<h1 class="text-2xl font-semibold">{m.invite_title()}</h1>
	<Card>
		{#if !inv}
			<Alert kind="error">{m.invite_not_found()}</Alert>
		{:else if inv.status !== 'open'}
			<Alert kind="info">{statusText[inv.status]()}</Alert>
		{:else}
			<p class="mb-4" data-testid="invite-text">
				{m.invite_text({
					inviter: inv.inviter_name,
					org: inv.org_name,
					role: roleLabel[inv.role]()
				})}
			</p>
			{#if form?.error}<div class="mb-4"><Alert kind="error">{form.error}</Alert></div>{/if}
			{#if data.me}
				<form method="POST" use:enhance><Button type="submit">{m.invite_accept()}</Button></form>
			{:else}
				<p class="mb-4 text-sm">{m.invite_login({ email: inv.email })}</p>
				<div class="flex gap-3">
					<a href="{localizeHref('/register')}?next={next}">{m.nav_register()}</a>
					<a href="{localizeHref('/login')}?next={next}">{m.nav_login()}</a>
				</div>
			{/if}
		{/if}
	</Card>
</div>
