<script lang="ts">
	import { enhance } from '$app/forms';
	import type { I18nText } from '@terra/contracts';
	import { m } from '#lib/paraglide/messages.js';
	import { getLocale } from '#lib/paraglide/runtime.js';
	import { formatMoney, kindLabel, t, valueLabel } from '#lib/catalog.js';
	import Alert from '#lib/components/Alert.svelte';
	import Button from '#lib/components/Button.svelte';
	import Card from '#lib/components/Card.svelte';
	import type { PageProps } from './$types';

	let { data, form }: PageProps = $props();
	const locale = getLocale();
	type Snap = {
		title: I18nText;
		description: I18nText;
		rent_amount?: number;
		deposit_amount?: number;
		attributes?: Record<string, unknown>;
		unit: { kind: string; label: string };
		address: { label: string };
	};
	const s = $derived(data.detail.snapshot as unknown as Snap);
	const item = $derived(data.detail.item);
	const defOf = (key: string) => data.schema.attributes.find((a) => a.key === key);
</script>

<div class="grid gap-6 lg:grid-cols-[2fr_1fr]">
	<Card>
		<div class="mb-4 grid grid-cols-2 gap-2 sm:grid-cols-3">
			{#each data.detail.photos as p, i (i)}<img
					src={p.medium}
					alt=""
					class="aspect-[4/3] w-full rounded object-cover"
				/>{/each}
		</div>
		<h1 class="text-xl font-semibold">{t(s.title, locale)}</h1>
		<p class="text-sm text-[var(--muted)]">
			{kindLabel[s.unit.kind]?.()} · {s.unit.label} · {s.address.label}
		</p>
		<p class="mt-2">
			{m.field_rent()}: <strong>{formatMoney(s.rent_amount, locale)}</strong>
			{#if s.deposit_amount}· {m.field_deposit()}: {formatMoney(s.deposit_amount, locale)}{/if}
		</p>
		<p class="mt-4 text-sm whitespace-pre-line">{s.description.cs}</p>
		{#if s.description.en}<p class="mt-4 text-sm whitespace-pre-line text-[var(--muted)]">
				{s.description.en}
			</p>{/if}
		<ul class="mt-4 grid gap-1 text-sm sm:grid-cols-2">
			{#each Object.entries(s.attributes ?? {}) as [key, v] (key)}
				<li>
					<span class="text-[var(--muted)]">{t(defOf(key)?.label, locale) || key}:</span>
					{valueLabel(defOf(key), v, locale)}
				</li>
			{/each}
		</ul>
	</Card>
	<Card title="{item.org_name} · v{item.version}">
		<p class="mb-3 text-sm text-[var(--muted)]">
			{m.bo_submitted_by({ email: item.submitted_by_email })}
		</p>
		{#if form?.error}<div class="mb-3"><Alert kind="error">{form.error}</Alert></div>{/if}
		<form method="POST" use:enhance class="grid gap-3">
			<label class="grid gap-1 text-sm font-medium"
				>{m.bo_note()}
				<textarea
					name="note"
					rows="4"
					class="rounded-lg border border-[var(--border)] bg-[var(--surface)] px-3 py-2"></textarea>
			</label>
			<Button type="submit" name="approve" value="true">{m.bo_approve()}</Button>
			<Button type="submit" variant="danger" name="approve" value="false">{m.bo_reject()}</Button>
		</form>
	</Card>
</div>
