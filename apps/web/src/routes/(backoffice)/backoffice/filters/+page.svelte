<script lang="ts">
	import { enhance } from '$app/forms';
	import { m } from '#lib/paraglide/messages.js';
	import { getLocale } from '#lib/paraglide/runtime.js';
	import { t } from '#lib/catalog.js';
	import Alert from '#lib/components/Alert.svelte';
	import Button from '#lib/components/Button.svelte';
	import Card from '#lib/components/Card.svelte';
	import type { PageProps } from './$types';

	let { data, form }: PageProps = $props();
	const locale = getLocale();
	const input = 'rounded border border-[var(--border)] bg-[var(--surface)] px-2 py-1 text-sm';
</script>

<div class="grid gap-6">
	<h1 class="text-2xl font-semibold">{m.bo_filters()}</h1>
	{#if form?.error}<Alert kind="error">{form.error}</Alert>{/if}
	<Card>
		{#if data.proposals.length === 0}<p class="text-sm text-[var(--muted)]">
				{m.bo_proposals_empty()}
			</p>{/if}
		<ul class="grid gap-3" data-testid="proposals">
			{#each data.proposals as p (p.id)}
				{@const attr = data.schema.attributes.find((a) => a.key === p.attribute_key)}
				<li class="rounded-lg border border-[var(--border)] p-3 text-sm">
					<p>
						<strong>{t(attr?.label, locale) || p.attribute_key}</strong>: <code>{p.value}</code> · {m.bo_occurrences(
							{
								count: String(p.occurrences)
							}
						)}
					</p>
					<form method="POST" use:enhance class="mt-2 flex flex-wrap items-center gap-2">
						<input type="hidden" name="id" value={p.id} />
						<input name="label_cs" value={p.label.cs} class={input} aria-label="cs" />
						<input name="label_en" value={p.label.en} class={input} aria-label="en" />
						<Button type="submit" name="approve" value="true">{m.bo_add_option()}</Button>
						<Button type="submit" variant="secondary" name="approve" value="false"
							>{m.bo_reject_option()}</Button
						>
					</form>
				</li>
			{/each}
		</ul>
	</Card>
</div>
