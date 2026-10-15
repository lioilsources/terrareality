<script lang="ts">
	import { enhance } from '$app/forms';
	import { m } from '#lib/paraglide/messages.js';
	import { localizeHref } from '#lib/paraglide/runtime.js';
	import { field } from '#lib/applications.js';
	import { factorLabel } from '#lib/portfolio.js';
	import Alert from '#lib/components/Alert.svelte';
	import Button from '#lib/components/Button.svelte';
	import Card from '#lib/components/Card.svelte';
	import type { PageProps } from './$types';

	let { data, form, params }: PageProps = $props();
	const base = $derived(`/admin/orgs/${params.orgId}`);
	const canEdit = $derived(data.role === 'owner' || data.role === 'admin');
	let scope = $state<'municipality' | 'group'>('municipality');
	const defaults = $derived(data.rules?.defaults);
	const ruleFields = [
		['reminder_before_days', m.pf_rule_reminder_before, 0, 14],
		['overdue_days', m.pf_rule_overdue, 1, 14],
		['escalation_days', m.pf_rule_escalation, 2, 30],
		['deposit_months', m.pf_rule_deposit, 0, 3],
		['notice_months', m.pf_rule_notice, 1, 12]
	] as const;
	const show = (v: number | undefined, d: number | undefined) => String(v ?? d ?? '–');
	const keep =
		() =>
		({ update }: { update: (o?: { reset?: boolean }) => Promise<void> }) =>
			update({ reset: false });
</script>

<svelte:head><title>{m.pf_settings()} · {m.app_name()}</title></svelte:head>
<p class="mb-2 text-sm"><a href={localizeHref(`${base}/portfolio`)}>← {m.pf_title()}</a></p>
<h1 class="mb-4 text-2xl font-semibold">{m.pf_settings()}</h1>
{#if !canEdit}<div class="mb-4"><Alert kind="info">{m.pf_readonly()}</Alert></div>{/if}
{#if form?.error}<div class="mb-4"><Alert kind="error">{form.error}</Alert></div>{/if}
{#if form?.saved === 'weights'}<div class="mb-4">
		<Alert kind="success">{m.pf_weights_saved()}</Alert>
	</div>
{:else if form?.saved}<div class="mb-4"><Alert kind="success">{m.pf_saved()}</Alert></div>{/if}

<div class="grid gap-6 lg:grid-cols-2">
	<Card title={m.pf_groups()} testid="pf-groups">
		<p class="mb-4 text-sm text-[var(--muted)]">{m.pf_groups_hint()}</p>
		{#if data.groups.groups.length === 0}<p class="mb-4 text-sm">{m.pf_group_empty()}</p>{/if}
		{#each [...data.groups.groups, null] as g (g?.id ?? 'new')}
			{#if g || canEdit}
				<details
					class="mb-3 rounded-lg border border-[var(--border)] p-3"
					open={!g && data.groups.groups.length === 0}
				>
					<summary class="cursor-pointer font-medium">
						{#if g}
							<span class="inline-block size-3 rounded" style="background: {g.color}"></span>
							{g.name}
							<span class="text-sm text-[var(--muted)]"
								>· {g.property_ids.length}
								{m.pf_group_properties().toLowerCase()} · {g.lease_ids.length}
								{m.pf_group_leases().toLowerCase()}</span
							>
						{:else}+ {m.pf_group_create()}{/if}
					</summary>
					<form method="POST" action="?/saveGroup" use:enhance={keep} class="mt-3 grid gap-3">
						<input type="hidden" name="id" value={g?.id ?? ''} />
						<fieldset disabled={!canEdit} class="grid gap-3">
							<div class="flex gap-3">
								<label class="grid flex-1 gap-1 text-sm"
									>{m.pf_group_name()}<input
										name="name"
										required
										maxlength="80"
										value={g?.name ?? ''}
										class={field}
									/></label
								>
								<label class="grid gap-1 text-sm"
									>{m.pf_group_color()}<input
										type="color"
										name="color"
										value={g?.color ?? '#0ea5e9'}
										class="h-10 w-14 rounded border border-[var(--border)]"
									/></label
								>
							</div>
							{#if data.groups.properties.length}
								<fieldset class="grid gap-1 text-sm">
									<legend class="mb-1 font-medium">{m.pf_group_properties()}</legend>
									{#each data.groups.properties as p (p.id)}
										<label class="flex gap-2"
											><input
												type="checkbox"
												name="property_ids"
												value={p.id}
												checked={g?.property_ids.includes(p.id)}
											/>{p.name} <span class="text-[var(--muted)]">{p.address}</span></label
										>
									{/each}
								</fieldset>
							{/if}
							{#if data.leases.length}
								<fieldset class="grid gap-1 text-sm">
									<legend class="mb-1 font-medium">{m.pf_group_leases()}</legend>
									{#each data.leases as l (l.id)}
										<label class="flex gap-2"
											><input
												type="checkbox"
												name="lease_ids"
												value={l.id}
												checked={g?.lease_ids.includes(l.id)}
											/>{l.label}</label
										>
									{/each}
								</fieldset>
							{/if}
							{#if canEdit}
								<div class="flex gap-2">
									<Button type="submit">{g ? m.pf_group_save() : m.pf_group_create()}</Button>
								</div>
							{/if}
						</fieldset>
					</form>
					{#if g && canEdit}
						<form method="POST" action="?/deleteGroup" use:enhance class="mt-2">
							<input type="hidden" name="id" value={g.id} />
							<Button type="submit" variant="danger">{m.pf_group_delete()}</Button>
						</form>
					{/if}
				</details>
			{/if}
		{/each}
	</Card>

	<div class="grid content-start gap-6">
		<Card title={m.pf_rules()} testid="pf-rules">
			<p class="mb-4 text-sm text-[var(--muted)]">{m.pf_rules_hint()}</p>
			{#if data.rules}
				{#if data.rules.rules.length === 0}<p class="mb-4 text-sm">{m.pf_rule_empty()}</p>{/if}
				<ul class="mb-4 grid gap-2">
					{#each data.rules.rules as r (r.id)}
						<li
							class="flex items-center justify-between gap-2 rounded-lg border border-[var(--border)] px-3 py-2 text-sm"
							data-testid="pf-rule"
						>
							<span>
								<strong>{r.scope_name}</strong>
								<span class="block text-[var(--muted)]"
									>{m.pf_rule_summary({
										before: show(r.rules.reminder_before_days, defaults?.reminder_before_days),
										overdue: show(r.rules.overdue_days, defaults?.overdue_days),
										escalation: show(r.rules.escalation_days, defaults?.escalation_days),
										deposit: show(r.rules.deposit_months, defaults?.deposit_months),
										notice: show(r.rules.notice_months, defaults?.notice_months)
									})}</span
								>
							</span>
							{#if canEdit}
								<form method="POST" action="?/deleteRule" use:enhance>
									<input type="hidden" name="id" value={r.id} />
									<Button type="submit" variant="secondary">{m.pf_rule_delete()}</Button>
								</form>
							{/if}
						</li>
					{/each}
				</ul>
				{#if canEdit}
					<form method="POST" action="?/saveRule" use:enhance={keep} class="grid gap-3">
						<fieldset class="flex flex-wrap gap-4 text-sm">
							<legend class="mb-1 font-medium">{m.pf_rule_scope()}</legend>
							<label class="flex gap-2"
								><input
									type="radio"
									name="scope"
									value="municipality"
									bind:group={scope}
								/>{m.pf_rule_municipality()}</label
							>
							<label class="flex gap-2"
								><input
									type="radio"
									name="scope"
									value="group"
									bind:group={scope}
									disabled={!data.groups.groups.length}
								/>{m.pf_rule_group()}</label
							>
						</fieldset>
						{#if scope === 'municipality'}
							<select
								name="municipality"
								class={field}
								aria-label={m.pf_rule_municipality()}
								required
							>
								{#each data.rules.municipalities as mu (mu.path)}
									<option value={mu.path}>{mu.name}</option>
								{/each}
							</select>
						{:else}
							<select name="group_id" class={field} aria-label={m.pf_rule_group()} required>
								{#each data.groups.groups as g (g.id)}
									<option value={g.id}>{g.name}</option>
								{/each}
							</select>
						{/if}
						<div class="grid gap-3 sm:grid-cols-2">
							{#each ruleFields as [key, label, min, max] (key)}
								<label class="grid gap-1 text-sm"
									>{label()}<input
										type="number"
										name={key}
										{min}
										{max}
										placeholder={m.pf_rule_default({ value: show(undefined, defaults?.[key]) })}
										class={field}
									/></label
								>
							{/each}
						</div>
						<div><Button type="submit">{m.pf_rule_save()}</Button></div>
					</form>
				{/if}
			{/if}
		</Card>

		{#if data.weights}
			<Card title={m.pf_weights()} testid="pf-weights">
				<p class="mb-4 text-sm text-[var(--muted)]">{m.pf_weights_hint()}</p>
				<form method="POST" action="?/saveWeights" use:enhance={keep} class="grid gap-3">
					<fieldset disabled={!canEdit} class="grid gap-2 sm:grid-cols-2">
						{#each Object.keys(factorLabel).filter((k) => k in data.weights!.defaults) as k (k)}
							<label class="flex items-center justify-between gap-2 text-sm"
								>{factorLabel[k]?.() ?? k}<input
									type="number"
									name={k}
									min="0"
									max="100"
									value={data.weights.weights[k]}
									class="{field} w-20"
								/></label
							>
						{/each}
					</fieldset>
					{#if canEdit}<div><Button type="submit">{m.pf_weights_save()}</Button></div>{/if}
				</form>
			</Card>
		{/if}
	</div>
</div>
