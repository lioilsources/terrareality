<script lang="ts">
	/** Coloured dot plus label for ok / fail / disabled / degraded states. */
	type State = 'ok' | 'fail' | 'disabled' | 'degraded' | 'unknown';
	let { state = 'unknown', label }: { state?: State; label: string } = $props();
</script>

<span class="status" data-state={state}>
	<span class="dot" aria-hidden="true"></span>
	<span>{label}</span>
</span>

<style>
	.status {
		display: inline-flex;
		align-items: center;
		gap: 0.4rem;
		color: var(--text);
	}
	.dot {
		width: 0.6rem;
		height: 0.6rem;
		border-radius: 999px;
		background: var(--muted);
	}
	[data-state='ok'] .dot {
		background: var(--ok);
	}
	[data-state='fail'] .dot {
		background: var(--fail);
	}
	[data-state='degraded'] .dot {
		background: var(--warn);
	}
</style>
