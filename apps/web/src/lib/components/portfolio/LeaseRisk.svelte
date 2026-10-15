<script lang="ts">
	import type { components } from '@terra/contracts';
	import { m } from '#lib/paraglide/messages.js';
	import { fmtDateTime } from '#lib/labels.js';
	import Card from '#lib/components/Card.svelte';
	import RiskBadge from './RiskBadge.svelte';
	import RiskFactors from './RiskFactors.svelte';

	let { risk, locale }: { risk: components['schemas']['LeaseRisk'] | null; locale: string } =
		$props();
</script>

{#if risk}
	<Card title={risk.landlord ? m.risk_title() : m.risk_tenant_title()} testid="lease-risk">
		{#if risk.landlord}
			<p class="mb-3 flex items-center gap-2" data-testid="lease-risk-score">
				<RiskBadge score={risk.score} band={risk.band} />
			</p>
			<p class="mb-4 text-xs text-[var(--muted)]">{m.risk_hint()}</p>
		{:else}
			<p class="mb-4 text-xs text-[var(--muted)]">{m.risk_tenant_hint()}</p>
		{/if}
		<RiskFactors factors={risk.factors} {locale} tenant={!risk.landlord} />
		<p class="mt-3 text-xs text-[var(--muted)]">
			{m.risk_computed({ date: fmtDateTime(risk.computed_at, locale), model: risk.model_version })}
		</p>
	</Card>
{/if}
