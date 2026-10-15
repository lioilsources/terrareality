<script lang="ts">
	import { m } from '#lib/paraglide/messages.js';
	import { factorDetail, factorLabel, type RiskFactor } from '#lib/portfolio.js';

	let {
		factors,
		locale,
		tenant = false
	}: { factors: RiskFactor[]; locale: string; tenant?: boolean } = $props();
</script>

<ul class="grid gap-2" data-testid="risk-factors">
	{#each factors as f (f.key)}
		<li class="grid gap-1" data-factor={f.key}>
			<div class="flex items-baseline justify-between gap-3 text-sm">
				<span class={f.value > 0 ? 'font-medium' : 'text-[var(--muted)]'}
					>{factorLabel[f.key]()}</span
				>
				{#if !tenant && f.points !== undefined}
					<span class="tabular-nums {f.points > 0 ? '' : 'text-[var(--muted)]'}"
						>{m.risk_points({
							points: f.points.toLocaleString(locale === 'en' ? 'en-GB' : 'cs-CZ')
						})}</span
					>
				{/if}
			</div>
			<div class="h-1.5 overflow-hidden rounded-full bg-[var(--border)]">
				<div
					class="h-full rounded-full {f.value >= 0.66
						? 'bg-red-500'
						: f.value >= 0.33
							? 'bg-amber-500'
							: 'bg-emerald-500'}"
					style="width: {Math.max(2, Math.round(f.value * 100))}%"
				></div>
			</div>
			<span class="text-xs text-[var(--muted)]">{factorDetail(f, locale)}</span>
		</li>
	{/each}
</ul>
