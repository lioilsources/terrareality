<script lang="ts">
	import { untrack } from 'svelte';
	import { m } from '#lib/paraglide/messages.js';
	import {
		cutoverRange,
		defaultCutover,
		roleLabel,
		templates,
		type ImportField,
		type ImportParty
	} from '#lib/leasing.js';
	import { field } from '#lib/applications.js';
	import AddressPicker from '#lib/components/AddressPicker.svelte';
	import Button from '#lib/components/Button.svelte';

	type Values = {
		template?: string;
		starts_on?: string;
		payee_name?: string;
		parties?: ImportParty[];
	};

	let {
		values = {},
		error = null,
		submit
	}: {
		values?: Values;
		/** An api error that belongs to one field (shown under it). */
		error?: { field: ImportField; message: string } | null;
		submit: string;
	} = $props();

	// The form owns its state from the initial values on.
	const initial = untrack(() => values);
	let template = $state(initial.template ?? 'byt_doba_neurcita');
	let startsOn = $state(initial.starts_on ?? '');
	let cutover = $state(defaultCutover());
	let cutoverTouched = false;
	let parties = $state<ImportParty[]>(
		structuredClone(
			initial.parties ?? [{ name: '', email: '', role: 'tenant', share: '', opening: '' }]
		)
	);
	const roles = ['tenant', 'co_tenant', 'subtenant', 'guarantor'];
	const range = cutoverRange();
	const errorOf = (f: ImportField) => (error?.field === f ? error.message : '');
	const invalid = (f: ImportField) => (error?.field === f ? 'true' : undefined);

	// A lease starting later is tracked from its start (the api's default too).
	$effect(() => {
		const s = startsOn;
		if (!cutoverTouched) cutover = defaultCutover(new Date(), s);
	});
</script>

{#snippet err(f: ImportField)}
	{#if errorOf(f)}<span
			class="text-sm font-normal text-red-700 dark:text-red-400"
			role="alert"
			data-testid="error-{f}">{errorOf(f)}</span
		>{/if}
{/snippet}

<div class="grid gap-4">
	<input type="hidden" name="parties" value={JSON.stringify(parties)} />
	<AddressPicker
		label={m.lease_address()}
		hint={m.lease_import_address_hint()}
		textName="property_address"
		required
		error={errorOf('property_address')}
	/>
	<div class="grid gap-4 sm:grid-cols-2">
		<label class="grid gap-1 text-sm font-medium"
			>{m.lease_unit()}<input name="unit_label" maxlength="120" class={field} /></label
		>
		<label class="grid gap-1 text-sm font-medium"
			>{m.lease_template()}
			<select
				name="template"
				bind:value={template}
				class={field}
				aria-invalid={invalid('template')}
			>
				{#each templates as [v, label] (v)}<option value={v}>{label()}</option>{/each}
			</select>
			{@render err('template')}
		</label>
		<label class="grid gap-1 text-sm font-medium"
			>{m.lease_starts()}<input
				type="date"
				name="starts_on"
				required
				bind:value={startsOn}
				aria-invalid={invalid('starts_on')}
				class={field}
			/>{@render err('starts_on')}</label
		>
		{#if template !== 'byt_doba_neurcita'}
			<label class="grid gap-1 text-sm font-medium"
				>{m.lease_ends()}<input
					type="date"
					name="ends_on"
					required={template === 'byt_doba_urcita'}
					aria-invalid={invalid('ends_on')}
					class={field}
				/>{@render err('ends_on')}</label
			>
		{/if}
		<label class="grid gap-1 text-sm font-medium"
			>{m.lease_rent()}<input
				type="number"
				name="rent"
				min="1"
				step="any"
				required
				aria-invalid={invalid('rent')}
				class={field}
			/>{@render err('rent')}</label
		>
		<label class="grid gap-1 text-sm font-medium"
			>{m.lease_services()}<input
				type="number"
				name="services"
				min="0"
				step="any"
				value="0"
				class={field}
			/></label
		>
		<div class="grid gap-1 text-sm font-medium">
			<label class="grid gap-1"
				>{m.lease_deposit()}<input
					type="number"
					name="deposit"
					min="0"
					step="any"
					value="0"
					aria-invalid={invalid('deposit')}
					class={field}
				/></label
			>
			<label class="flex items-center gap-2 font-normal"
				><input type="checkbox" name="deposit_held" checked />
				{m.lease_import_deposit_held()}</label
			>
			{@render err('deposit')}
		</div>
		<label class="grid gap-1 text-sm font-medium"
			>{m.lease_due_day()}<input
				type="number"
				name="due_day"
				min="1"
				max="28"
				value="15"
				aria-invalid={invalid('due_day')}
				class={field}
			/>{@render err('due_day')}</label
		>
		<label class="grid gap-1 text-sm font-medium"
			>{m.lease_notice_months()}<input
				type="number"
				name="notice_months"
				min="1"
				max="12"
				placeholder="3"
				class={field}
			/><span class="text-xs font-normal text-[var(--muted)]">{m.lease_import_notice_hint()}</span
			></label
		>
		<label class="grid gap-1 text-sm font-medium"
			>{m.lease_iban()}<input
				name="payee_iban"
				required
				aria-invalid={invalid('payee_iban')}
				class={field}
			/>{@render err('payee_iban')}</label
		>
		<label class="grid gap-1 text-sm font-medium"
			>{m.lease_payee()}<input
				name="payee_name"
				required
				value={values.payee_name ?? ''}
				aria-invalid={invalid('payee_name')}
				class={field}
			/>{@render err('payee_name')}</label
		>
		<label class="grid gap-1 text-sm font-medium"
			>{m.lease_import_vs()}<input
				name="variable_symbol"
				inputmode="numeric"
				maxlength="12"
				aria-invalid={invalid('variable_symbol')}
				class={field}
			/><span class="text-xs font-normal text-[var(--muted)]">{m.lease_import_vs_hint()}</span
			>{@render err('variable_symbol')}</label
		>
		<label class="grid gap-1 text-sm font-medium"
			>{m.lease_import_cutover()}<input
				type="date"
				name="cutover_on"
				required
				min={range.min}
				max={range.max}
				bind:value={cutover}
				oninput={() => (cutoverTouched = true)}
				aria-invalid={invalid('cutover_on')}
				class={field}
			/><span class="text-xs font-normal text-[var(--muted)]">{m.lease_import_cutover_hint()}</span
			>{@render err('cutover_on')}</label
		>
	</div>
	<fieldset class="grid gap-2 text-sm" data-testid="lease-parties">
		<legend class="mb-1 font-medium">{m.lease_parties()}</legend>
		<p class="text-xs text-[var(--muted)]">{m.lease_import_parties_hint()}</p>
		{#each parties as p, i (i)}
			<div
				class="grid gap-2 sm:grid-cols-[2fr_2fr_1.5fr_1fr_1.5fr_auto] sm:items-end"
				data-testid="lease-party"
			>
				<label class="grid gap-1"
					>{m.lease_party_name()}<input bind:value={p.name} required class={field} /></label
				>
				<label class="grid gap-1"
					>{m.lease_import_party_email()}<input
						type="email"
						bind:value={p.email}
						class={field}
					/></label
				>
				<label class="grid gap-1"
					>{m.lease_party_role()}<select bind:value={p.role} class={field}>
						{#each roles as r (r)}<option value={r}>{roleLabel[r]()}</option>{/each}
					</select></label
				>
				<label class="grid gap-1"
					>{m.lease_party_share()}<input
						type="number"
						min="0"
						max="100"
						step="any"
						disabled={p.role === 'guarantor'}
						bind:value={p.share}
						class={field}
					/></label
				>
				<label class="grid gap-1"
					>{m.lease_import_opening()}<input
						type="number"
						min="0"
						step="any"
						disabled={p.role === 'guarantor'}
						bind:value={p.opening}
						class={field}
					/></label
				>
				<Button
					type="button"
					variant="secondary"
					aria-label={m.lease_import_remove_party()}
					disabled={parties.length === 1}
					onclick={() => parties.splice(i, 1)}>✕</Button
				>
			</div>
		{/each}
		<p class="text-xs text-[var(--muted)]">{m.lease_import_opening_hint()}</p>
		{@render err('parties')}
		<div>
			<Button
				type="button"
				variant="secondary"
				onclick={() =>
					parties.push({ name: '', email: '', role: 'co_tenant', share: '', opening: '' })}
				>{m.lease_add_party()}</Button
			>
		</div>
	</fieldset>
	<p class="text-xs text-[var(--muted)]">{m.lease_money_note()}</p>
	<div><Button type="submit">{submit}</Button></div>
</div>
