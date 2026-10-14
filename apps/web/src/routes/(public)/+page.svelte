<script lang="ts">
	import { m } from '#lib/paraglide/messages.js';
	import { orderChecks } from '#lib/status.js';
	import { StatusDot } from '@terra/ui';
	import type { PageProps } from './$types';

	let { data }: PageProps = $props();

	const labels: Record<string, () => string> = {
		database: m.check_database,
		worker: m.check_worker,
		centrifugo: m.check_centrifugo,
		vision: m.check_vision
	};
	const states: Record<'ok' | 'fail' | 'disabled', () => string> = {
		ok: m.state_ok,
		fail: m.state_fail,
		disabled: m.state_disabled
	};
	let checks = $derived(data.health ? orderChecks(data.health) : []);
</script>

<section class="mb-10">
	<h1 class="text-3xl font-semibold tracking-tight">{m.app_name()}</h1>
	<p class="mt-2 text-[var(--muted)]">{m.tagline()}</p>
</section>

<section
	class="rounded-[var(--radius-card)] border border-[var(--border)] bg-[var(--surface)] p-6"
	aria-labelledby="status-title"
>
	<div class="flex flex-wrap items-baseline justify-between gap-2">
		<h2 id="status-title" class="text-lg font-semibold">{m.status_title()}</h2>
		{#if data.version}
			<span class="text-sm text-[var(--muted)]"
				>{data.version.version} · {m.status_schema({
					version: String(data.version.schema_version)
				})}</span
			>
		{/if}
	</div>

	{#if !data.health}
		<p class="mt-4" data-testid="api-status">
			<StatusDot state="fail" label={m.status_api_unreachable()} />
		</p>
	{:else}
		<p class="mt-4" data-testid="api-status">
			<StatusDot
				state={data.health.status}
				label={data.health.status === 'ok' ? m.status_ok() : m.status_degraded()}
			/>
		</p>
		<ul class="mt-4 grid gap-2 sm:grid-cols-2">
			{#each checks as c (c.name)}
				<li
					class="flex items-center justify-between rounded-lg border border-[var(--border)] px-3 py-2"
				>
					<StatusDot state={c.state} label={labels[c.name]?.() ?? c.name} />
					<span class="text-sm text-[var(--muted)]" title={c.error}>
						{states[c.state]()}{c.latencyMs !== undefined ? ` · ${c.latencyMs} ms` : ''}
					</span>
				</li>
			{/each}
		</ul>
	{/if}
</section>
