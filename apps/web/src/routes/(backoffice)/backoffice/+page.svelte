<script lang="ts">
	import { m } from '#lib/paraglide/messages.js';
	import { getLocale, localizeHref } from '#lib/paraglide/runtime.js';
	import { fmtDate, levelLabel } from '#lib/labels.js';
	import Alert from '#lib/components/Alert.svelte';
	import Button from '#lib/components/Button.svelte';
	import Card from '#lib/components/Card.svelte';
	import Field from '#lib/components/Field.svelte';
	import type { PageProps } from './$types';

	let { data }: PageProps = $props();
</script>

<svelte:head><title>{m.bo_users()} · {m.nav_backoffice()}</title></svelte:head>

<div class="grid gap-6">
	<h1 class="text-2xl font-semibold">{m.bo_users()}</h1>
	{#if data.error}<Alert kind="error">{data.error}</Alert>{/if}
	<form method="GET" class="flex max-w-lg items-end gap-3">
		<div class="flex-1">
			<Field label={m.field_search()} name="q" value={data.q} type="search" />
		</div>
		<Button type="submit" variant="secondary">{m.field_search()}</Button>
	</form>
	<Card>
		<ul class="grid gap-2" data-testid="bo-users">
			{#each data.page.items as u (u.id)}
				<li
					class="flex flex-wrap items-center justify-between gap-2 rounded-lg border border-[var(--border)] px-3 py-2 text-sm"
				>
					<span>
						<strong>{u.display_name || '—'}</strong> · {u.email} · {levelLabel[
							u.verification_level
						]()}
						{#if u.is_staff}· <em>{m.bo_staff()}</em>{/if}
						{#if u.pseudonymized}· <em>{m.bo_erased()}</em>{/if}
						<span class="text-[var(--muted)]">· {fmtDate(u.created_at, getLocale())}</span>
					</span>
					<a href={localizeHref(`/backoffice/users/${u.id}`)}>{m.org_open()}</a>
				</li>
			{/each}
		</ul>
		{#if data.page.next_before}
			<a
				class="mt-4 inline-block text-sm"
				href="?q={encodeURIComponent(data.q)}&before={data.page.next_before}">{m.bo_more()}</a
			>
		{/if}
	</Card>
</div>
