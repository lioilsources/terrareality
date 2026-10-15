<script lang="ts">
	import { m } from '#lib/paraglide/messages.js';
	import { localizeHref } from '#lib/paraglide/runtime.js';
	import Alert from '#lib/components/Alert.svelte';
	import Card from '#lib/components/Card.svelte';
	import type { PageProps } from './$types';

	let { data }: PageProps = $props();
	const badge = 'rounded px-2 py-0.5 text-xs font-medium';
</script>

<svelte:head><title>{m.bo_templates()} · {m.nav_backoffice()}</title></svelte:head>

<div class="grid gap-6">
	<h1 class="text-2xl font-semibold">{m.bo_templates()}</h1>
	{#if data.templates.version}
		<p class="text-sm text-[var(--muted)]" data-testid="bo-templates-version">
			{m.bo_tpl_version({ version: data.templates.version })}
		</p>
	{/if}
	{#if data.error}<Alert kind="error">{data.error}</Alert>{/if}
	{#if data.previewUnavailable}<Alert kind="error">{m.bo_tpl_unavailable()}</Alert>{/if}
	<Card>
		{#if data.templates.items.length === 0}
			<p class="text-sm text-[var(--muted)]">{m.bo_tpl_empty()}</p>
		{:else}
			<div class="overflow-x-auto">
				<table class="w-full text-left text-sm" data-testid="bo-templates">
					<caption class="sr-only">{m.bo_templates()}</caption>
					<thead class="text-[var(--muted)]">
						<tr>
							<th scope="col" class="py-1 pr-4">{m.bo_tpl_title()}</th>
							<th scope="col" class="pr-4">{m.bo_tpl_name()}</th>
							<th scope="col" class="pr-4">{m.bo_tpl_review()}</th>
							<th scope="col">{m.bo_tpl_preview()}</th>
						</tr>
					</thead>
					<tbody>
						{#each data.templates.items as tpl (tpl.name)}
							<tr class="border-t border-[var(--border)]">
								<th scope="row" class="py-2 pr-4 font-normal">{tpl.title}</th>
								<td class="py-2 pr-4"><code>{tpl.name}</code></td>
								<td class="py-2 pr-4">
									{#if tpl.reviewed}
										<span
											class="{badge} bg-emerald-100 text-emerald-900 dark:bg-emerald-900/40 dark:text-emerald-100"
											>{m.bo_tpl_reviewed()}</span
										>
									{:else}
										<span
											class="{badge} bg-amber-100 text-amber-900 dark:bg-amber-900/40 dark:text-amber-100"
											>{m.bo_tpl_unreviewed()}</span
										>
									{/if}
								</td>
								<td class="py-2">
									<a
										href={localizeHref(`/backoffice/sablony/${encodeURIComponent(tpl.name)}/pdf`)}
										target="_blank"
										rel="noopener"
										data-sveltekit-reload
										aria-label={m.bo_tpl_preview_of({ title: tpl.title })}>{m.bo_tpl_preview()}</a
									>
								</td>
							</tr>
						{/each}
					</tbody>
				</table>
			</div>
		{/if}
	</Card>
</div>
