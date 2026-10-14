<script lang="ts">
	import type { Snippet } from 'svelte';

	let { title, children, testid }: { title?: string; children: Snippet; testid?: string } =
		$props();
</script>

<section
	class="rounded-[var(--radius-card)] border border-[var(--border)] bg-[var(--surface)] p-6"
	data-testid={testid}
>
	{#if title}<h2 class="mb-4 text-lg font-semibold">{title}</h2>{/if}
	{@render children()}
</section>
