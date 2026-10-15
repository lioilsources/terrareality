<script lang="ts">
	import { untrack } from 'svelte';
	import { m } from '#lib/paraglide/messages.js';
	import { clauses, roleLabel, templates } from '#lib/leasing.js';
	import { field } from '#lib/applications.js';
	import Button from '#lib/components/Button.svelte';

	type Party = { name: string; email: string; role: string; share: number };
	type Values = {
		template?: string;
		starts_on?: string;
		ends_on?: string;
		rent?: number;
		services?: number;
		deposit?: number;
		due_day?: number;
		notice_months?: number;
		payee_iban?: string;
		payee_name?: string;
		property_address?: string;
		unit_label?: string;
		clauses?: string[];
		parties?: Party[];
	};

	let {
		values = {},
		applicationId = '',
		submit
	}: { values?: Values; applicationId?: string; submit: string } = $props();

	// The form owns its state from the initial values on.
	const initial = untrack(() => values);
	let template = $state(initial.template ?? 'spolecny_najem');
	let parties = $state<Party[]>(structuredClone(initial.parties ?? []));
	const roles = ['tenant', 'co_tenant', 'subtenant', 'guarantor'];
</script>

<div class="grid gap-4">
	{#if applicationId}<input type="hidden" name="application_id" value={applicationId} />{/if}
	<input type="hidden" name="parties" value={JSON.stringify(parties)} />
	<label class="grid gap-1 text-sm font-medium"
		>{m.lease_template()}
		<select name="template" bind:value={template} class={field}>
			{#each templates as [v, label] (v)}<option value={v}>{label()}</option>{/each}
		</select>
	</label>
	<div class="grid gap-4 sm:grid-cols-2">
		<label class="grid gap-1 text-sm font-medium"
			>{m.lease_starts()}<input
				type="date"
				name="starts_on"
				required
				value={values.starts_on ?? ''}
				class={field}
			/></label
		>
		{#if template !== 'byt_doba_neurcita'}
			<label class="grid gap-1 text-sm font-medium"
				>{m.lease_ends()}<input
					type="date"
					name="ends_on"
					required={template === 'byt_doba_urcita'}
					value={values.ends_on ?? ''}
					class={field}
				/></label
			>
		{/if}
		<label class="grid gap-1 text-sm font-medium"
			>{m.lease_rent()}<input
				type="number"
				name="rent"
				min="1"
				required
				value={values.rent ?? ''}
				class={field}
			/></label
		>
		<label class="grid gap-1 text-sm font-medium"
			>{m.lease_services()}<input
				type="number"
				name="services"
				min="0"
				value={values.services ?? 0}
				class={field}
			/></label
		>
		<label class="grid gap-1 text-sm font-medium"
			>{m.lease_deposit()}<input
				type="number"
				name="deposit"
				min="0"
				value={values.deposit ?? 0}
				class={field}
			/></label
		>
		<label class="grid gap-1 text-sm font-medium"
			>{m.lease_due_day()}<input
				type="number"
				name="due_day"
				min="1"
				max="28"
				value={values.due_day ?? 15}
				class={field}
			/></label
		>
		<label class="grid gap-1 text-sm font-medium"
			>{m.lease_notice_months()}<input
				type="number"
				name="notice_months"
				min="1"
				max="12"
				value={values.notice_months ?? 3}
				class={field}
			/></label
		>
		<label class="grid gap-1 text-sm font-medium"
			>{m.lease_iban()}<input
				name="payee_iban"
				required
				value={values.payee_iban ?? ''}
				class={field}
			/></label
		>
		<label class="grid gap-1 text-sm font-medium"
			>{m.lease_payee()}<input
				name="payee_name"
				required
				value={values.payee_name ?? ''}
				class={field}
			/></label
		>
		<label class="grid gap-1 text-sm font-medium"
			>{m.lease_address()}<input
				name="property_address"
				value={values.property_address ?? ''}
				class={field}
			/></label
		>
		<label class="grid gap-1 text-sm font-medium"
			>{m.lease_unit()}<input
				name="unit_label"
				value={values.unit_label ?? ''}
				class={field}
			/></label
		>
	</div>
	<fieldset class="grid gap-1 text-sm">
		<legend class="mb-1 font-medium">{m.lease_clauses()}</legend>
		{#each clauses as [v, label] (v)}
			<label class="flex items-center gap-2"
				><input type="checkbox" name="clauses" value={v} checked={values.clauses?.includes(v)} />
				{label()}</label
			>
		{/each}
	</fieldset>
	<fieldset class="grid gap-2 text-sm" data-testid="lease-parties">
		<legend class="mb-1 font-medium">{m.lease_parties()}</legend>
		{#if applicationId && parties.length === 0}<p class="text-[var(--muted)]">
				{m.lease_parties_from_app()}
			</p>{/if}
		{#each parties as p, i (i)}
			<div class="grid gap-2 sm:grid-cols-[2fr_2fr_1.5fr_1fr_auto] sm:items-end">
				<label class="grid gap-1"
					>{m.lease_party_name()}<input bind:value={p.name} required class={field} /></label
				>
				<label class="grid gap-1"
					>{m.lease_party_email()}<input
						type="email"
						bind:value={p.email}
						required
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
						bind:value={p.share}
						class={field}
					/></label
				>
				<Button type="button" variant="secondary" onclick={() => parties.splice(i, 1)}>✕</Button>
			</div>
		{/each}
		<div>
			<Button
				type="button"
				variant="secondary"
				onclick={() => parties.push({ name: '', email: '', role: 'co_tenant', share: 0 })}
				>{m.lease_add_party()}</Button
			>
		</div>
	</fieldset>
	<p class="text-xs text-[var(--muted)]">{m.lease_money_note()}</p>
	<div><Button type="submit">{submit}</Button></div>
</div>
