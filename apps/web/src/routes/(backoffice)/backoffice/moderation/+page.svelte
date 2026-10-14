<script lang="ts">
	import { m } from '#lib/paraglide/messages.js';
	import { getLocale, localizeHref } from '#lib/paraglide/runtime.js';
	import { t } from '#lib/catalog.js';
	import { fmtDateTime } from '#lib/labels.js';
	import Card from '#lib/components/Card.svelte';
	import { verdictLabel, reasonLabel } from './labels.js';
	import type { PageProps } from './$types';

	let { data }: PageProps = $props();
	const locale = getLocale();
</script>

<Card title={m.bo_moderation()}>
	{#if data.cases.length === 0}
		<p class="text-sm text-[var(--muted)]">{m.bo_moderation_empty()}</p>
	{:else}
		<ul class="grid gap-2" data-testid="moderation-queue">
			{#each data.cases as c (c.id)}
				<li>
					<a
						href={localizeHref(`/backoffice/moderation/${c.id}`)}
						class="grid gap-1 rounded-lg border border-[var(--border)] p-3 text-[var(--text)] no-underline hover:border-[var(--accent)]"
					>
						<span class="flex flex-wrap items-center gap-2 text-sm">
							<span class="rounded bg-[var(--border)]/60 px-2 py-0.5"
								>{c.source === 'auto' ? m.bo_case_auto() : m.bo_case_report()}</span
							>
							<strong>{reasonLabel(c.reason)}</strong>
							<span class="text-[var(--muted)]">{t(c.listing_title, locale)}</span>
							<span class="ml-auto text-xs text-[var(--muted)]"
								>{fmtDateTime(c.created_at, locale)}</span
							>
						</span>
						{#if c.message_body}<span class="truncate text-sm">„{c.message_body}“</span>{/if}
						<span class="text-xs text-[var(--muted)]" data-testid="case-ai">
							{#if c.ai_status === 'ready' && c.ai_suggestion}
								{m.bo_ai_suggestion()}: {verdictLabel(c.ai_suggestion.verdict)} ({m.bo_confidence({
									pct: String(Math.round(c.ai_suggestion.confidence * 100))
								})})
							{:else if c.ai_status === 'pending'}{m.bo_ai_pending()}
							{:else if c.ai_status === 'failed'}{m.bo_ai_failed()}
							{:else}{m.bo_ai_disabled()}{/if}
						</span>
					</a>
				</li>
			{/each}
		</ul>
	{/if}
</Card>
