<script lang="ts">
	import { invalidateAll } from '$app/navigation';
	import { onMount } from 'svelte';
	import { m } from '#lib/paraglide/messages.js';
	import { getLocale, localizeHref } from '#lib/paraglide/runtime.js';
	import { t } from '#lib/catalog.js';
	import { fmtDate } from '#lib/labels.js';
	import { connect } from '#lib/realtime.js';
	import Card from '#lib/components/Card.svelte';
	import LoadMore from '#lib/components/LoadMore.svelte';
	import type { PageProps } from './$types';

	let { data }: PageProps = $props();
	const locale = getLocale();

	// New messages and read receipts arrive on the user channel.
	onMount(() => connect({ onEvent: () => invalidateAll() }));
</script>

<svelte:head><title>{m.msg_inbox_title()} · {m.app_name()}</title></svelte:head>

<h1 class="mb-6 text-2xl font-semibold">{m.msg_inbox_title()}</h1>
{#if data.conversations.length === 0}
	<Card><p class="text-[var(--muted)]">{m.msg_inbox_empty()}</p></Card>
{:else}
	<ul class="grid gap-2" data-testid="inbox">
		{#each data.conversations as c (c.id)}
			<li>
				<a
					href={localizeHref(`/zpravy/${c.id}`)}
					class="flex items-center gap-4 rounded-[var(--radius-card)] border border-[var(--border)] bg-[var(--surface)] p-4 text-[var(--text)] no-underline hover:border-[var(--accent)]"
				>
					{#if c.cover_url}
						<img src={c.cover_url} alt="" class="h-14 w-20 shrink-0 rounded object-cover" />
					{/if}
					<div class="min-w-0 flex-1">
						<p class="flex flex-wrap items-baseline gap-x-2">
							<span class="font-semibold">{c.role === 'seeker' ? c.org_name : c.seeker_name}</span>
							<span class="truncate text-sm text-[var(--muted)]">{t(c.listing_title, locale)}</span>
						</p>
						<p class="truncate text-sm {c.unread ? 'font-semibold' : 'text-[var(--muted)]'}">
							{c.last_message || '📎'}
						</p>
					</div>
					<div class="grid shrink-0 justify-items-end gap-1 text-xs text-[var(--muted)]">
						<span>{fmtDate(c.last_message_at, locale)}</span>
						<span class="rounded bg-[var(--border)]/50 px-1.5 py-0.5"
							>{c.role === 'seeker' ? m.msg_role_seeker() : m.msg_role_owner()}</span
						>
						{#if c.unread}
							<span
								class="rounded-full bg-[var(--accent)] px-2 py-0.5 font-semibold text-white"
								data-testid="unread">{m.msg_unread({ count: String(c.unread) })}</span
							>
						{/if}
					</div>
				</a>
			</li>
		{/each}
	</ul>
{/if}
<LoadMore next={data.paging.next} first={data.paging.first} testid="inbox-more" />
