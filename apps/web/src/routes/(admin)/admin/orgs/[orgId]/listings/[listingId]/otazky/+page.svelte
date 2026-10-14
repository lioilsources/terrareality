<script lang="ts">
	import { enhance } from '$app/forms';
	import { untrack } from 'svelte';
	import type { PrescreenQuestion } from '@terra/contracts';
	import { m } from '#lib/paraglide/messages.js';
	import { getLocale, localizeHref } from '#lib/paraglide/runtime.js';
	import { t } from '#lib/catalog.js';
	import Alert from '#lib/components/Alert.svelte';
	import Button from '#lib/components/Button.svelte';
	import Card from '#lib/components/Card.svelte';
	import type { PageProps } from './$types';

	let { data, form }: PageProps = $props();
	// Editable copy; deep state so push/splice re-render.
	let questions = $state<PrescreenQuestion[]>(
		untrack(() => structuredClone(data.listing.prescreen))
	);
	const kinds = [
		['text', m.msg_prescreen_kind_text],
		['yes_no', m.msg_prescreen_kind_yes_no],
		['number', m.msg_prescreen_kind_number]
	] as const;
	const field = 'rounded-lg border border-[var(--border)] bg-[var(--surface)] px-3 py-2';
</script>

<p class="mb-4 text-sm">
	<a href={localizeHref(`/admin/orgs/${data.listing.org_id}/listings/${data.listing.id}`)}
		>← {t(data.listing.title, getLocale()) || m.back()}</a
	>
</p>
<Card title={m.msg_prescreen_edit()}>
	<p class="mb-4 text-sm text-[var(--muted)]">{m.msg_prescreen_hint()}</p>
	{#if form?.saved}<div class="mb-3">
			<Alert kind="success">{m.msg_prescreen_saved()}</Alert>
		</div>{/if}
	{#if form?.error}<div class="mb-3"><Alert kind="error">{form.error}</Alert></div>{/if}
	<form
		method="POST"
		use:enhance={() =>
			({ update }) =>
				update({ reset: false })}
		class="grid gap-4"
	>
		<input type="hidden" name="questions" value={JSON.stringify(questions)} />
		{#each questions as q, i (i)}
			<fieldset
				class="grid gap-2 rounded-lg border border-[var(--border)] p-3 sm:grid-cols-[1fr_auto_auto_auto] sm:items-end"
			>
				<label class="grid gap-1 text-sm font-medium"
					>{m.msg_prescreen_question()}
					{i + 1}
					<input bind:value={q.text.cs} maxlength="300" required class={field} />
				</label>
				<label class="grid gap-1 text-sm font-medium"
					>{m.msg_prescreen_kind()}
					<select bind:value={q.kind} class={field}>
						{#each kinds as [value, label] (value)}<option {value}>{label()}</option>{/each}
					</select>
				</label>
				<label class="flex items-center gap-2 pb-2 text-sm">
					<input type="checkbox" bind:checked={q.required} />
					{m.msg_prescreen_required()}
				</label>
				<Button type="button" variant="secondary" onclick={() => questions.splice(i, 1)}
					>{m.msg_prescreen_remove()}</Button
				>
			</fieldset>
		{/each}
		<div class="flex gap-2">
			{#if questions.length < 10}
				<Button
					type="button"
					variant="secondary"
					onclick={() => questions.push({ text: { cs: '' }, kind: 'text', required: false })}
					>{m.msg_prescreen_add()}</Button
				>
			{/if}
			<Button type="submit">{m.msg_prescreen_save()}</Button>
		</div>
	</form>
</Card>
