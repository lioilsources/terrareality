<script lang="ts">
	import { m } from '#lib/paraglide/messages.js';
	import { getLocale } from '#lib/paraglide/runtime.js';
	import { fmtDateTime } from '#lib/labels.js';
	import Card from '#lib/components/Card.svelte';
	import type { PageProps } from './$types';

	let { data }: PageProps = $props();
</script>

<div class="grid gap-6">
	<h1 class="text-2xl font-semibold">{m.bo_audit()}</h1>
	<Card>
		<div class="overflow-x-auto">
			<table class="w-full text-left text-sm">
				<thead class="text-[var(--muted)]">
					<tr>
						<th class="py-1 pr-4">{m.audit_when()}</th><th class="pr-4">{m.audit_who()}</th>
						<th class="pr-4">{m.audit_action()}</th><th>{m.audit_entity()}</th>
					</tr>
				</thead>
				<tbody>
					{#each data.page.items as a (a.id)}
						<tr class="border-t border-[var(--border)] align-top">
							<td class="py-1 pr-4 whitespace-nowrap">{fmtDateTime(a.occurred_at, getLocale())}</td>
							<td class="pr-4">{a.actor_email}{a.impersonator_id ? ' *' : ''}</td>
							<td class="pr-4"><code>{a.action}</code></td>
							<td
								><code class="text-xs">{a.entity}</code>
								<span class="text-xs text-[var(--muted)]">{JSON.stringify(a.diff)}</span></td
							>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>
		{#if data.page.next_before}<a
				class="mt-4 inline-block text-sm"
				href="?before={data.page.next_before}">{m.bo_more()}</a
			>{/if}
	</Card>
</div>
