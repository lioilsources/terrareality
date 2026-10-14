<script lang="ts">
	import { enhance } from '$app/forms';
	import { m } from '#lib/paraglide/messages.js';
	import { getLocale, localizeHref } from '#lib/paraglide/runtime.js';
	import { fmtDate } from '#lib/labels.js';
	import { paramsFromQuery } from '#lib/searchParams.js';
	import Button from '#lib/components/Button.svelte';
	import Card from '#lib/components/Card.svelte';
	import type { PageProps } from './$types';

	let { data }: PageProps = $props();
</script>

<Card title={m.nav_saved_searches()}>
	{#if data.searches.length === 0}<p class="text-sm text-[var(--muted)]">{m.saved_empty()}</p>{/if}
	<ul class="grid gap-2" data-testid="saved-searches">
		{#each data.searches as s (s.id)}
			<li
				class="flex flex-wrap items-center justify-between gap-2 rounded-lg border border-[var(--border)] px-3 py-2 text-sm"
			>
				<span
					><strong>{s.name}</strong> · {fmtDate(s.created_at, getLocale())}{s.notify
						? ' · 🔔'
						: ''}</span
				>
				<span class="flex items-center gap-3">
					<a href={localizeHref(`/hledat?${paramsFromQuery(s.query)}`)}>{m.saved_open()}</a>
					<form method="POST" action="?/delete" use:enhance>
						<input type="hidden" name="id" value={s.id} />
						<Button type="submit" variant="secondary">{m.remove()}</Button>
					</form>
				</span>
			</li>
		{/each}
	</ul>
</Card>
