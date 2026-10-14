<script lang="ts">
	import type { Snippet } from 'svelte';

	let { kind = 'info', children }: { kind?: 'info' | 'error' | 'success'; children: Snippet } =
		$props();
	const styles = {
		info: 'border-sky-300 bg-sky-50 text-sky-900 dark:border-sky-800 dark:bg-sky-950 dark:text-sky-100',
		error:
			'border-red-300 bg-red-50 text-red-900 dark:border-red-800 dark:bg-red-950 dark:text-red-100',
		success:
			'border-emerald-300 bg-emerald-50 text-emerald-900 dark:border-emerald-800 dark:bg-emerald-950 dark:text-emerald-100'
	};
</script>

<div
	class="rounded-lg border px-4 py-3 text-sm {styles[kind]}"
	role={kind === 'error' ? 'alert' : 'status'}
>
	{@render children()}
</div>
