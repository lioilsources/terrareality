<script lang="ts">
	import { enhance } from '$app/forms';
	import { m } from '#lib/paraglide/messages.js';
	import { getLocale } from '#lib/paraglide/runtime.js';
	import { fmtDateTime } from '#lib/labels.js';
	import Alert from '#lib/components/Alert.svelte';
	import Button from '#lib/components/Button.svelte';
	import Card from '#lib/components/Card.svelte';
	import type { PageProps } from './$types';

	let { data, form }: PageProps = $props();
	const locale = getLocale();
</script>

<svelte:head><title>{m.bo_flags()} · {m.nav_backoffice()}</title></svelte:head>

<div class="grid gap-6">
	<h1 class="text-2xl font-semibold">{m.bo_flags()}</h1>
	<p class="text-sm text-[var(--muted)]">{m.bo_flags_hint()}</p>
	{#if data.error}<Alert kind="error">{data.error}</Alert>{/if}
	{#if form?.error}<Alert kind="error">{form.error}</Alert>{/if}
	<Card>
		{#if data.flags.length === 0}
			<p class="text-sm text-[var(--muted)]">{m.bo_flags_empty()}</p>
		{:else}
			<div class="overflow-x-auto">
				<table class="w-full text-left text-sm" data-testid="bo-flags">
					<caption class="sr-only">{m.bo_flags()}</caption>
					<thead class="text-[var(--muted)]">
						<tr>
							<th scope="col" class="py-1 pr-4">{m.bo_flag_key()}</th>
							<th scope="col" class="pr-4">{m.bo_flag_description()}</th>
							<th scope="col" class="pr-4">{m.bo_flag_source()}</th>
							<th scope="col" class="pr-4">{m.bo_flag_state()}</th>
							<th scope="col">{m.bo_flag_updated()}</th>
						</tr>
					</thead>
					<tbody>
						{#each data.flags as f (f.key)}
							<tr class="border-t border-[var(--border)] align-top" data-testid="bo-flag-{f.key}">
								<th scope="row" class="py-2 pr-4 font-normal"><code>{f.key}</code></th>
								<td class="py-2 pr-4">{f.description || '—'}</td>
								<td class="py-2 pr-4">
									{f.source === 'db' ? m.bo_flag_source_db() : m.bo_flag_source_default()}
								</td>
								<td class="py-2 pr-4">
									<form method="POST" action="?/toggle" use:enhance class="flex items-center gap-2">
										<input type="hidden" name="key" value={f.key} />
										<input type="hidden" name="enabled" value={f.enabled ? 'false' : 'true'} />
										<span data-testid="bo-flag-state"
											>{f.enabled ? m.bo_flag_on() : m.bo_flag_off()}</span
										>
										<Button
											type="submit"
											variant="secondary"
											aria-label={f.enabled
												? m.bo_flag_disable({ key: f.key })
												: m.bo_flag_enable({ key: f.key })}
										>
											{f.enabled ? m.bo_flag_turn_off() : m.bo_flag_turn_on()}
										</Button>
									</form>
								</td>
								<td class="py-2 whitespace-nowrap">
									{f.updated_at ? fmtDateTime(f.updated_at, locale) : '—'}
								</td>
							</tr>
						{/each}
					</tbody>
				</table>
			</div>
		{/if}
	</Card>
</div>
