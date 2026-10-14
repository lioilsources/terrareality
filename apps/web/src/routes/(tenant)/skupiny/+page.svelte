<script lang="ts">
	import { enhance } from '$app/forms';
	import { m } from '#lib/paraglide/messages.js';
	import { localizeHref } from '#lib/paraglide/runtime.js';
	import { field } from '#lib/applications.js';
	import Alert from '#lib/components/Alert.svelte';
	import Button from '#lib/components/Button.svelte';
	import Card from '#lib/components/Card.svelte';
	import type { PageProps } from './$types';

	let { data, form }: PageProps = $props();
</script>

<svelte:head><title>{m.group_title()} · {m.app_name()}</title></svelte:head>
<div class="grid gap-6 md:grid-cols-2">
	<Card title={m.group_title()}>
		{#if data.groups.length === 0}<p class="text-sm text-[var(--muted)]">{m.group_empty()}</p>{/if}
		<ul class="grid gap-2" data-testid="groups">
			{#each data.groups as g (g.id)}
				<li>
					<a href={localizeHref(`/skupiny/${g.id}`)}>{g.name}</a>
					<span class="text-sm text-[var(--muted)]"
						>· {g.members}
						{#if !g.joined}· {m.group_invited()}{/if}</span
					>
				</li>
			{/each}
		</ul>
	</Card>
	<Card title={m.group_create()}>
		{#if form?.error}<div class="mb-3"><Alert kind="error">{form.error}</Alert></div>{/if}
		<form method="POST" action="?/create" use:enhance class="grid gap-3">
			<label class="grid gap-1 text-sm font-medium"
				>{m.group_name()}<input name="name" required maxlength="80" class={field} /></label
			>
			<label class="grid gap-1 text-sm font-medium"
				>{m.group_invite_emails()}<input name="invite" class={field} /></label
			>
			<div><Button type="submit">{m.group_create()}</Button></div>
		</form>
	</Card>
</div>
