<script lang="ts">
	import { enhance } from '$app/forms';
	import { m } from '#lib/paraglide/messages.js';
	import { getLocale } from '#lib/paraglide/runtime.js';
	import { fmtDate } from '#lib/labels.js';
	import Alert from '#lib/components/Alert.svelte';
	import Button from '#lib/components/Button.svelte';
	import Card from '#lib/components/Card.svelte';
	import Field from '#lib/components/Field.svelte';
	import type { PageProps } from './$types';

	let { data, form }: PageProps = $props();
	const me = $derived(data.me);
</script>

<div class="grid gap-6 md:grid-cols-2">
	<Card title={m.settings_profile()}>
		<form method="POST" action="?/profile" use:enhance class="grid gap-4">
			{#if form?.profileSaved}<Alert kind="success">{m.profile_saved()}</Alert>{/if}
			{#if form?.profileError}<Alert kind="error">{form.profileError}</Alert>{/if}
			<Field
				label={m.field_name()}
				name="display_name"
				value={me.display_name}
				required
				maxlength={120}
			/>
			<label class="grid gap-1 text-sm font-medium">
				{m.field_locale()}
				<select
					name="locale"
					class="rounded-lg border border-[var(--border)] bg-[var(--surface)] px-3 py-2"
				>
					<option value="cs" selected={me.locale === 'cs'}>{m.lang_name_cs()}</option>
					<option value="en" selected={me.locale === 'en'}>{m.lang_name_en()}</option>
				</select>
			</label>
			<Button type="submit">{m.save()}</Button>
		</form>
	</Card>

	<Card title={m.identity_title()} testid="identity-card">
		{#if data.verified}<div class="mb-3">
				<Alert kind="success">{m.level_identity()}</Alert>
			</div>{/if}
		{#if data.identityError || form?.identityError}
			<div class="mb-3"><Alert kind="error">{form?.identityError ?? m.err_generic()}</Alert></div>
		{/if}
		{#if me.identity}
			<p class="text-sm" data-testid="identity-done">
				{m.identity_done({
					name: `${me.identity.given_name ?? ''} ${me.identity.family_name ?? ''}`.trim(),
					date: fmtDate(me.identity.verified_at, getLocale())
				})}
			</p>
		{:else}
			<p class="mb-4 text-sm text-[var(--muted)]">{m.identity_hint()}</p>
			<form method="POST" action="?/identity">
				<Button type="submit">{m.identity_start()}</Button>
			</form>
		{/if}
	</Card>

	<Card title={m.phone_title()}>
		{#if me.phone_verified && !form?.phoneSent}
			<p class="text-sm" data-testid="phone-verified">
				{m.phone_verified({ phone: me.phone ?? '' })}
			</p>
		{/if}
		{#if form?.phoneError}<div class="mb-3"><Alert kind="error">{form.phoneError}</Alert></div>{/if}
		{#if form?.phoneSent}
			<form method="POST" action="?/phoneVerify" use:enhance class="grid gap-4">
				<Alert kind="info">{m.phone_sent()}</Alert>
				<Field
					label={m.field_code()}
					name="code"
					inputmode="numeric"
					autocomplete="one-time-code"
					required
				/>
				<Button type="submit">{m.phone_verify()}</Button>
			</form>
		{:else}
			<form method="POST" action="?/phone" use:enhance class="mt-3 grid gap-4">
				<Field
					label={m.field_phone()}
					name="phone"
					type="tel"
					autocomplete="tel"
					placeholder="+420 601 234 567"
					required
					value={form?.phone ?? ''}
				/>
				<Button type="submit" variant="secondary">{m.phone_send()}</Button>
			</form>
		{/if}
	</Card>
</div>
