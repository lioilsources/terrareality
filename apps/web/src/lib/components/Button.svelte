<script lang="ts">
	import type { Snippet } from 'svelte';
	import type { HTMLButtonAttributes } from 'svelte/elements';

	let {
		variant = 'primary',
		children,
		...rest
	}: {
		variant?: 'primary' | 'secondary' | 'danger';
		children: Snippet;
	} & HTMLButtonAttributes = $props();
	const styles = {
		primary: 'bg-[var(--accent)] text-white hover:opacity-90',
		secondary: 'border border-[var(--border)] bg-[var(--surface)] hover:bg-[var(--border)]/40',
		danger:
			'border border-red-600 text-red-700 hover:bg-red-50 dark:text-red-400 dark:hover:bg-red-950'
	};
</script>

<button
	class="inline-flex items-center justify-center rounded-lg px-4 py-2 text-sm font-medium transition disabled:opacity-50 {styles[
		variant
	]}"
	{...rest}
>
	{@render children()}
</button>
