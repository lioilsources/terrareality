<script lang="ts">
	/** TerraReality wordmark: a map pin over a roofline. */
	let { size = 28, label = 'TerraReality' }: { size?: number; label?: string } = $props();
</script>

<span class="terra-logo" style:--size="{size}px">
	<svg viewBox="0 0 32 32" width={size} height={size} aria-hidden="true">
		<path d="M16 3c-5.5 0-10 4.3-10 9.7C6 20 16 29 16 29s10-9 10-16.3C26 7.3 21.5 3 16 3z" fill="var(--accent)" />
		<path d="M10.5 14.5 16 10l5.5 4.5V20h-3.5v-3.5h-4V20h-3.5z" fill="var(--surface)" />
	</svg>
	<span class="terra-logo__text">{label}</span>
</span>

<style>
	.terra-logo {
		display: inline-flex;
		align-items: center;
		gap: 0.5rem;
		font-weight: 650;
		font-size: calc(var(--size) * 0.64);
		letter-spacing: -0.01em;
		color: var(--text);
	}
</style>
