<script lang="ts">
	import type { AddressSuggestion } from '@terra/contracts';
	import { m } from '#lib/paraglide/messages.js';

	/**
	 * RÚIAN address search (admin /admin/api/addresses): the picked address's id
	 * goes in a hidden `ruianName` input. With `textName` the typed text is
	 * submitted too, so a free-text address works when nothing is picked.
	 */
	let {
		label = m.wizard_address(),
		hint = m.wizard_address_hint(),
		query = $bindable(''),
		picked = $bindable(null),
		ruianName = 'ruian_id',
		textName,
		required = false,
		error = ''
	}: {
		label?: string;
		hint?: string;
		query?: string;
		picked?: AddressSuggestion | null;
		ruianName?: string;
		textName?: string;
		required?: boolean;
		error?: string;
	} = $props();
	const id = $props.id();
	let results: AddressSuggestion[] = $state([]);
	let searched = $state(false);
	let timer: ReturnType<typeof setTimeout> | undefined;

	function search() {
		picked = null;
		clearTimeout(timer);
		timer = setTimeout(async () => {
			if (query.trim().length < 3) {
				results = [];
				searched = false;
				return;
			}
			const res = await fetch(`/admin/api/addresses?q=${encodeURIComponent(query)}`);
			results = res.ok ? await res.json() : [];
			searched = true;
		}, 200);
	}

	function pick(a: AddressSuggestion) {
		picked = a;
		query = a.label;
		results = [];
	}
</script>

<div class="relative grid gap-1">
	<label for={id} class="text-sm font-medium">{label}</label>
	<input
		{id}
		name={textName}
		autocomplete="off"
		role="combobox"
		aria-expanded={results.length > 0}
		aria-controls="{id}-results"
		aria-invalid={error ? 'true' : undefined}
		aria-describedby={error ? `${id}-err` : `${id}-hint`}
		{required}
		class="rounded-lg border border-[var(--border)] bg-[var(--surface)] px-3 py-2"
		bind:value={query}
		oninput={search}
	/>
	<p id="{id}-hint" class="text-xs text-[var(--muted)]">{hint}</p>
	{#if error}
		<p id="{id}-err" class="text-sm text-red-700 dark:text-red-400" role="alert">{error}</p>
	{/if}
	{#if results.length}
		<ul
			id="{id}-results"
			role="listbox"
			class="absolute top-[4.5rem] z-10 w-full overflow-hidden rounded-lg border border-[var(--border)] bg-[var(--surface)] shadow"
		>
			{#each results as a (a.ruian_id)}
				<li role="option" aria-selected="false">
					<button
						type="button"
						class="w-full px-3 py-2 text-left text-sm hover:bg-[var(--border)]/40"
						onclick={() => pick(a)}>{a.label}</button
					>
				</li>
			{/each}
		</ul>
	{:else if searched && !picked}
		<p class="text-sm text-[var(--muted)]">{m.wizard_address_none()}</p>
	{/if}
	<input type="hidden" name={ruianName} value={picked?.ruian_id ?? ''} />
</div>
