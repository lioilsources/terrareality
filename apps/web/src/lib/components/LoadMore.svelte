<script lang="ts">
	import { m } from '#lib/paraglide/messages.js';

	/** Links from pageLinks(): plain links, so paging works without JavaScript. */
	let {
		next,
		first = null,
		label,
		testid = 'load-more'
	}: { next: string | null; first?: string | null; label?: string; testid?: string } = $props();
</script>

{#if next || first}
	<nav
		class="mt-4 flex flex-wrap items-center gap-4 text-sm"
		aria-label={label ?? m.paging_label()}
		data-testid={testid}
	>
		{#if next}
			<a
				href={next}
				rel="next"
				data-sveltekit-noscroll
				class="rounded-lg border border-[var(--border)] bg-[var(--surface)] px-4 py-2 font-medium no-underline hover:bg-[var(--border)]/40"
				data-testid="{testid}-next">{m.paging_more()}</a
			>
		{/if}
		{#if first}
			<a href={first} data-testid="{testid}-first">{m.paging_first()}</a>
		{/if}
	</nav>
{/if}
