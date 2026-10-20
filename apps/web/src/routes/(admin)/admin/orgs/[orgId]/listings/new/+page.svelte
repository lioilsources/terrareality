<script lang="ts">
	import type { AddressSuggestion } from '@terra/contracts';
	import { enhance } from '$app/forms';
	import { m } from '#lib/paraglide/messages.js';
	import { kindLabel, layouts } from '#lib/catalog.js';
	import AddressPicker from '#lib/components/AddressPicker.svelte';
	import Alert from '#lib/components/Alert.svelte';
	import Button from '#lib/components/Button.svelte';
	import Card from '#lib/components/Card.svelte';
	import Field from '#lib/components/Field.svelte';
	import type { PageProps } from './$types';

	let { form }: PageProps = $props();
	let picked: AddressSuggestion | null = $state(null);
	let kind = $state('apartment');
	const kinds = ['apartment', 'house', 'room', 'parking', 'storage', 'commercial'];
	const select = 'rounded-lg border border-[var(--border)] bg-[var(--surface)] px-3 py-2';
</script>

<svelte:head><title>{m.wizard_title()}</title></svelte:head>

<form method="POST" use:enhance class="grid max-w-2xl gap-6">
	<h1 class="text-2xl font-semibold">{m.wizard_title()}</h1>
	{#if form?.error}<Alert kind="error"
			>{form.error === 'pick_address' ? m.wizard_pick_address() : form.error}</Alert
		>{/if}

	<Card title="1. {m.wizard_address()}">
		<AddressPicker bind:picked />
	</Card>

	<Card title="2. {m.wizard_unit()}">
		<div class="grid gap-4">
			<div class="flex flex-wrap gap-2" role="radiogroup" aria-label={m.wizard_unit()}>
				{#each kinds as k (k)}
					<label
						class="cursor-pointer rounded-lg border px-3 py-2 text-sm {kind === k
							? 'border-[var(--accent)] bg-[var(--accent)]/10'
							: 'border-[var(--border)]'}"
					>
						<input type="radio" name="unit_kind" value={k} bind:group={kind} class="sr-only" />
						{kindLabel[k]()}
					</label>
				{/each}
			</div>
			{#if kind === 'room'}
				<Field label={m.wizard_room_label()} name="unit_label" required maxlength={120} />
				<label class="grid gap-1 text-sm font-medium"
					>{m.wizard_parent_layout()}
					<select name="parent_layout" class={select}>
						{#each layouts as l (l)}<option value={l} selected={l === '3+1'}>{l}</option>{/each}
					</select>
				</label>
				<Field
					label={m.wizard_parent_area()}
					name="parent_floor_area"
					type="number"
					min="1"
					step="0.1"
				/>
				<Field label={m.wizard_area()} name="floor_area" type="number" min="1" step="0.1" />
			{:else}
				{#if kind === 'apartment' || kind === 'house'}
					<label class="grid gap-1 text-sm font-medium"
						>{m.wizard_layout()}
						<select name="layout" class={select}>
							{#each layouts as l (l)}<option value={l} selected={l === '2+kk'}>{l}</option>{/each}
						</select>
					</label>
				{/if}
				<Field label={m.wizard_unit_label()} name="unit_label" maxlength={120} />
				<Field label={m.wizard_area()} name="floor_area" type="number" min="1" step="0.1" />
			{/if}
			<Field label={m.wizard_floor()} name="floor" type="number" min="-5" max="100" />
		</div>
	</Card>
	<div><Button type="submit" disabled={!picked}>{m.wizard_create()}</Button></div>
</form>
