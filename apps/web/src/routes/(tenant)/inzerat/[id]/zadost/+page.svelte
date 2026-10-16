<script lang="ts">
	import { enhance } from '$app/forms';
	import { m } from '#lib/paraglide/messages.js';
	import { getLocale, localizeHref } from '#lib/paraglide/runtime.js';
	import { t } from '#lib/catalog.js';
	import { field } from '#lib/applications.js';
	import Alert from '#lib/components/Alert.svelte';
	import Button from '#lib/components/Button.svelte';
	import Card from '#lib/components/Card.svelte';
	import DemoBadge from '#lib/components/DemoBadge.svelte';
	import type { PageProps } from './$types';

	let { data, form }: PageProps = $props();
	const locale = getLocale();
	const l = $derived(data.listing);
	let group = $state('');
</script>

<svelte:head><title>{m.app_apply_title()} · {m.app_name()}</title></svelte:head>

<Card title={m.app_apply_title()}>
	<p class="mb-4">
		<a href={localizeHref(`/inzerat/${l.id}`)}>{t(l.title, locale)}</a>
	</p>
	{#if l.is_demo}
		<!-- Demo listings cannot be applied for (api problem code demo_listing). -->
		<div class="grid gap-2" data-testid="demo-banner">
			<div><DemoBadge /></div>
			<p class="text-sm">{m.listing_demo_explain()}</p>
		</div>
	{:else}
		{#if form?.error}<div class="mb-3"><Alert kind="error">{form.error}</Alert></div>{/if}
		<form method="POST" use:enhance class="grid max-w-xl gap-4">
			{#if data.groups.length}
				<fieldset class="grid gap-2 text-sm">
					<legend class="mb-1 font-semibold">{m.app_apply_as()}</legend>
					<label class="flex items-center gap-2"
						><input type="radio" name="group_id" value="" bind:group /> {m.app_apply_alone()}</label
					>
					{#each data.groups as g (g.id)}
						<label class="flex items-center gap-2"
							><input type="radio" name="group_id" value={g.id} bind:group />
							{m.app_apply_group({ name: g.name })}</label
						>
					{/each}
					{#if group}<p class="text-[var(--muted)]">{m.app_group_hint()}</p>{/if}
				</fieldset>
			{/if}
			{#each l.prescreen as q (q.id)}
				{@const label =
					(q.text[locale as 'cs'] || q.text.cs || q.text.en) + (q.required ? ' *' : '')}
				{#if q.kind === 'yes_no'}
					<div class="grid gap-1 text-sm">
						<span class="font-medium">{label}</span>
						<div class="flex gap-4">
							<label class="flex items-center gap-1"
								><input type="radio" name="q_{q.id}" value="yes" required={q.required} />
								{m.msg_yes()}</label
							>
							<label class="flex items-center gap-1"
								><input type="radio" name="q_{q.id}" value="no" /> {m.msg_no()}</label
							>
						</div>
					</div>
				{:else}
					<label class="grid gap-1 text-sm font-medium"
						>{label}<input
							name="q_{q.id}"
							type={q.kind === 'number' ? 'number' : 'text'}
							required={q.required}
							class={field}
						/></label
					>
				{/if}
			{/each}
			<div class="grid gap-4 sm:grid-cols-3">
				<label class="grid gap-1 text-sm font-medium"
					>{m.app_preferred_from()}<input type="date" name="preferred_from" class={field} /></label
				>
				<label class="grid gap-1 text-sm font-medium"
					>{m.app_duration()}<input
						type="number"
						name="duration_months"
						min="1"
						max="120"
						class={field}
					/></label
				>
				<label class="grid gap-1 text-sm font-medium"
					>{m.app_household()}<input
						type="number"
						name="household_size"
						min="1"
						max="20"
						value="1"
						class={field}
					/></label
				>
			</div>
			<label class="grid gap-1 text-sm font-medium"
				>{m.app_message()}<textarea name="message" rows="5" maxlength="4000" class={field}
				></textarea></label
			>
			<p class="text-xs text-[var(--muted)]">{m.msg_safety()}</p>
			<div><Button type="submit">{m.app_submit()}</Button></div>
		</form>
	{/if}
</Card>
