<script lang="ts">
	import { enhance } from '$app/forms';
	import { m } from '#lib/paraglide/messages.js';
	import { getLocale } from '#lib/paraglide/runtime.js';
	import { formatMoney } from '#lib/catalog.js';
	import { fmtDate } from '#lib/labels.js';
	import { field, levelLabel, lifestyle, lifestyleLabel } from '#lib/applications.js';
	import Alert from '#lib/components/Alert.svelte';
	import Button from '#lib/components/Button.svelte';
	import Card from '#lib/components/Card.svelte';
	import type { PageProps } from './$types';

	let { data, form }: PageProps = $props();
	const locale = getLocale();
	const p = $derived(data.profile);
</script>

<svelte:head><title>{m.rm_title()} · {m.app_name()}</title></svelte:head>
<h1 class="mb-6 text-2xl font-semibold">{m.rm_title()}</h1>
<div class="grid gap-6 lg:grid-cols-[1fr_1fr]">
	<Card title={m.rm_profile()}>
		{#if form?.saved}<div class="mb-3"><Alert kind="success">{m.rm_saved()}</Alert></div>{/if}
		{#if form?.error}<div class="mb-3"><Alert kind="error">{form.error}</Alert></div>{/if}
		<form
			method="POST"
			use:enhance={() =>
				({ update }) =>
					update({ reset: false })}
			class="grid gap-3"
		>
			<label class="flex items-center gap-2 text-sm"
				><input type="checkbox" name="active" checked={p?.active ?? true} /> {m.rm_active()}</label
			>
			<label class="grid gap-1 text-sm font-medium"
				>{m.rm_area()}
				<select name="admin_path" class={field}>
					<option value="">{m.rm_area_any()}</option>
					{#each data.areas as a (a.path)}
						<option value={a.path} selected={p?.admin_path === a.path}>{a.name}</option>
					{/each}
				</select>
			</label>
			<div class="grid gap-3 sm:grid-cols-2">
				<label class="grid gap-1 text-sm font-medium"
					>{m.rm_budget()}<input
						type="number"
						name="budget"
						min="1"
						required
						value={p ? p.budget_max / 100 : ''}
						class={field}
					/></label
				>
				<label class="grid gap-1 text-sm font-medium"
					>{m.rm_move_in()}<input
						type="date"
						name="move_in"
						value={p?.move_in ?? ''}
						class={field}
					/></label
				>
			</div>
			<fieldset class="grid gap-1 text-sm">
				<legend class="mb-1 font-medium">{m.rm_lifestyle()}</legend>
				<div class="flex flex-wrap gap-x-4 gap-y-1">
					{#each lifestyle as [value, label] (value)}
						<label class="flex items-center gap-1"
							><input
								type="checkbox"
								name="lifestyle"
								{value}
								checked={p?.lifestyle.includes(value)}
							/>
							{label()}</label
						>
					{/each}
				</div>
			</fieldset>
			<label class="flex items-center gap-2 text-sm"
				><input type="checkbox" name="has_room" checked={p?.has_room ?? false} />
				{m.rm_has_room()}</label
			>
			<label class="grid gap-1 text-sm font-medium"
				>{m.rm_about()}<textarea name="about" rows="4" maxlength="2000" class={field}
					>{p?.about ?? ''}</textarea
				></label
			>
			<p class="text-xs text-[var(--muted)]">{m.rm_about_hint()}</p>
			<div><Button type="submit">{m.rm_save()}</Button></div>
		</form>
	</Card>
	<Card title={m.rm_matches()}>
		{#if data.matches.length === 0}<p class="text-sm text-[var(--muted)]">
				{m.rm_matches_empty()}
			</p>{/if}
		<ul class="grid gap-3" data-testid="roommate-matches">
			{#each data.matches as r (r.user_id)}
				<li class="rounded-lg border border-[var(--border)] p-3 text-sm">
					<p class="flex flex-wrap items-baseline gap-2">
						<strong>{r.display_name}</strong>
						<span class="text-[var(--muted)]">{levelLabel[r.verification_level]()}</span>
						<span class="ml-auto rounded-full bg-[var(--accent)] px-2 text-white"
							>{m.rm_score({ score: String(r.score) })}</span
						>
					</p>
					<p class="text-[var(--muted)]">
						{r.profile.area_label || m.rm_area_any()} · ≤ {formatMoney(
							r.profile.budget_max,
							'CZK',
							locale
						)}
						{#if r.profile.move_in}· {fmtDate(r.profile.move_in, locale)}{/if}
						{#if r.profile.has_room}· {m.rm_offers_room()}{/if}
					</p>
					{#if r.profile.lifestyle.length}
						<p class="mt-1">
							{r.profile.lifestyle.map((l) => lifestyleLabel[l]?.() ?? l).join(' · ')}
						</p>
					{/if}
					{#if r.profile.about}<p class="mt-1 whitespace-pre-line">{r.profile.about}</p>{/if}
				</li>
			{/each}
		</ul>
	</Card>
</div>
