<script lang="ts">
	import { m } from '#lib/paraglide/messages.js';
	import { getLocale, localizeHref } from '#lib/paraglide/runtime.js';
	import { t } from '#lib/catalog.js';
	import { fmtDateTime } from '#lib/labels.js';
	import Card from '#lib/components/Card.svelte';
	import type { PageProps } from './$types';

	let { data }: PageProps = $props();
	const locale = getLocale();
</script>

<div class="grid gap-6">
	<h1 class="text-2xl font-semibold">{m.bo_reviews()}</h1>
	<Card>
		{#if data.items.length === 0}<p class="text-sm text-[var(--muted)]">
				{m.bo_review_empty()}
			</p>{/if}
		<ul class="grid gap-2" data-testid="review-queue">
			{#each data.items as r (r.version_id)}
				<li class="flex items-center gap-3 rounded-lg border border-[var(--border)] p-2 text-sm">
					{#if r.cover_url}<img
							src={r.cover_url}
							alt=""
							class="h-14 w-20 rounded object-cover"
						/>{/if}
					<span class="grid flex-1">
						<a href={localizeHref(`/backoffice/reviews/${r.version_id}`)}
							><strong>{t(r.title, locale)}</strong></a
						>
						<span class="text-[var(--muted)]"
							>{r.org_name} · v{r.version} · {r.first_publication ? m.bo_first() : m.bo_update()} · {fmtDateTime(
								r.submitted_at,
								locale
							)}</span
						>
					</span>
				</li>
			{/each}
		</ul>
	</Card>
</div>
