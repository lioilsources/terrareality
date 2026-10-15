<script lang="ts">
	import { enhance } from '$app/forms';
	import { m } from '#lib/paraglide/messages.js';
	import { getLocale } from '#lib/paraglide/runtime.js';
	import { fmtDateTime } from '#lib/labels.js';
	import Alert from '#lib/components/Alert.svelte';
	import Button from '#lib/components/Button.svelte';
	import Card from '#lib/components/Card.svelte';
	import Field from '#lib/components/Field.svelte';
	import type { PageProps } from './$types';

	let { data, form }: PageProps = $props();
	const me = $derived(data.me);
</script>

<div class="grid gap-6">
	<Card title={m.security_mfa()} testid="mfa-card">
		{#if form?.mfaError}<div class="mb-3"><Alert kind="error">{form.mfaError}</Alert></div>{/if}
		{#if form?.recoveryCodes}
			<Alert kind="success">{m.security_mfa_on({ count: String(form.recoveryCodes.length) })}</Alert
			>
			<h3 class="mt-4 font-semibold">{m.security_recovery_title()}</h3>
			<p class="text-sm text-[var(--muted)]">{m.security_recovery_hint()}</p>
			<ul class="mt-2 grid grid-cols-2 gap-1 font-mono text-sm" data-testid="recovery-codes">
				{#each form.recoveryCodes as c (c)}<li>{c}</li>{/each}
			</ul>
		{:else if me.mfa_enabled}
			<p class="mb-4 text-sm" data-testid="mfa-on">
				{m.security_mfa_on({ count: String(me.recovery_codes_left ?? 0) })}
			</p>
			<form method="POST" action="?/disable" use:enhance class="grid max-w-sm gap-3">
				<Field label={m.field_code()} name="code" autocomplete="one-time-code" required />
				<Button type="submit" variant="danger">{m.security_mfa_disable()}</Button>
			</form>
		{:else if form?.setup}
			<p class="mb-4 text-sm">{m.security_mfa_scan()}</p>
			<div class="flex flex-wrap items-start gap-6">
				{#if form.setup.qr}
					<!-- eslint-disable-next-line svelte/no-at-html-tags -- SVG generated server-side by qrcode from our own URI -->
					<div class="rounded bg-white p-2">{@html form.setup.qr}</div>
				{/if}
				<form method="POST" action="?/enable" use:enhance class="grid max-w-sm gap-3">
					<code class="text-sm break-all" data-testid="totp-secret">{form.setup.secret}</code>
					<input type="hidden" name="secret" value={form.setup.secret} />
					<input type="hidden" name="otpauth_uri" value={form.setup.uri} />
					<Field
						label={m.field_code()}
						name="code"
						inputmode="numeric"
						autocomplete="one-time-code"
						required
					/>
					<Button type="submit">{m.security_mfa_enable()}</Button>
				</form>
			</div>
		{:else}
			<p class="mb-4 text-sm text-[var(--muted)]">{m.security_mfa_off()}</p>
			<form method="POST" action="?/setup" use:enhance>
				<Button type="submit">{m.security_mfa_start()}</Button>
			</form>
		{/if}
	</Card>

	<Card title={m.security_password()}>
		<form method="POST" action="?/password" use:enhance class="grid max-w-sm gap-3">
			{#if form?.passwordChanged}<Alert kind="success">{m.security_password_changed()}</Alert>{/if}
			{#if form?.passwordError}<Alert kind="error">{form.passwordError}</Alert>{/if}
			{#if me.has_password}
				<Field
					label={m.field_password_current()}
					name="current_password"
					type="password"
					autocomplete="current-password"
					required
				/>
			{/if}
			<Field
				label={m.field_password_new()}
				name="new_password"
				type="password"
				autocomplete="new-password"
				required
				minlength={12}
				hint={m.password_hint()}
			/>
			<Button type="submit" variant="secondary">{m.save()}</Button>
		</form>
	</Card>

	<Card title={m.security_sessions()}>
		{#if form?.sessionsError}<div class="mb-3">
				<Alert kind="error">{form.sessionsError}</Alert>
			</div>{/if}
		<ul class="grid gap-2">
			{#each data.sessions as s (s.id)}
				<li
					class="flex flex-wrap items-center justify-between gap-2 rounded-lg border border-[var(--border)] px-3 py-2 text-sm"
				>
					<span>
						{s.client} · {s.user_agent?.slice(0, 60) ?? ''} · {fmtDateTime(
							s.last_seen_at,
							getLocale()
						)}
						{#if s.current}<strong> · {m.security_session_current()}</strong>{/if}
						{#if s.impersonated}<em> · {m.security_session_impersonated()}</em>{/if}
					</span>
					{#if !s.current}
						<form method="POST" action="?/revoke" use:enhance>
							<input type="hidden" name="id" value={s.id} />
							<Button type="submit" variant="secondary">{m.revoke()}</Button>
						</form>
					{/if}
				</li>
			{/each}
		</ul>
	</Card>
</div>
