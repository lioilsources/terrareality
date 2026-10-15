<script lang="ts">
	import { m } from '#lib/paraglide/messages.js';
	import { bandClass, bandLabel, type RiskBand } from '#lib/portfolio.js';

	let { score, band }: { score?: number | null; band?: RiskBand | null } = $props();
</script>

{#if band && score !== undefined && score !== null}
	<span
		class="inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-xs font-medium whitespace-nowrap {bandClass[
			band
		]}"
		data-testid="risk-badge"
		data-band={band}>{score} · {bandLabel[band]()}</span
	>
{:else}
	<span class="text-xs text-[var(--muted)]">{m.pf_no_score()}</span>
{/if}
