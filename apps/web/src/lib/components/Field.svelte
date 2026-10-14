<script lang="ts">
	import type { HTMLInputAttributes } from 'svelte/elements';

	let {
		label,
		name,
		hint,
		value = $bindable(''),
		...rest
	}: {
		label: string;
		name: string;
		hint?: string;
		value?: string | null;
	} & HTMLInputAttributes = $props();
	const id = $props.id();
</script>

<div class="grid gap-1">
	<label for={id} class="text-sm font-medium">{label}</label>
	<input
		{id}
		{name}
		bind:value
		aria-describedby={hint ? `${id}-hint` : undefined}
		class="rounded-lg border border-[var(--border)] bg-[var(--surface)] px-3 py-2 text-[var(--text)] focus:border-[var(--accent)] focus:ring-2 focus:ring-[var(--accent)]/30 focus:outline-none"
		{...rest}
	/>
	{#if hint}<p id="{id}-hint" class="text-xs text-[var(--muted)]">{hint}</p>{/if}
</div>
