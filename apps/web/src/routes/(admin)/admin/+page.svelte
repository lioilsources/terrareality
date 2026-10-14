<script lang="ts">
	import { enhance } from '$app/forms';
	import { m } from '#lib/paraglide/messages.js';
	import { localizeHref } from '#lib/paraglide/runtime.js';
	import { levelLabel, roleLabel } from '#lib/labels.js';
	import Alert from '#lib/components/Alert.svelte';
	import Card from '#lib/components/Card.svelte';
	import type { PageProps } from './$types';

	let { data, form }: PageProps = $props();
	const me = $derived(data.me);
	const checks = $derived([
		{ ok: me.email_verified, label: m.check_email(), href: '/admin' },
		{ ok: me.mfa_enabled, label: m.check_mfa(), href: '/admin/settings/security' },
		{ ok: me.phone_verified, label: m.check_phone(), href: '/admin/settings/profile' },
		{
			ok: me.verification_level === 'identity',
			label: m.check_identity(),
			href: '/admin/settings/profile'
		}
	]);
</script>

<svelte:head><title>{m.dashboard_title()} · {m.app_name()}</title></svelte:head>

<div class="grid gap-6">
	<h1 class="text-2xl font-semibold">{m.dashboard_hello({ name: me.display_name || me.email })}</h1>
	{#if !me.email_verified}
		<Alert kind="info">
			<div class="flex flex-wrap items-center justify-between gap-2" data-testid="verify-banner">
				<span>{form?.resent ? m.verify_resent() : m.verify_banner({ email: me.email })}</span>
				<form method="POST" action="?/resend" use:enhance>
					<button class="underline">{m.verify_resend()}</button>
				</form>
			</div>
		</Alert>
	{/if}
	<div class="grid gap-6 md:grid-cols-2">
		<Card title={m.dashboard_checklist()}>
			<p class="mb-3 text-sm">
				{m.dashboard_level()}:
				<strong data-testid="verification-level">{levelLabel[me.verification_level]()}</strong>
			</p>
			<ul class="grid gap-2">
				{#each checks as c (c.label)}
					<li class="flex items-center gap-2 text-sm">
						<span aria-hidden="true" class={c.ok ? 'text-emerald-600' : 'text-[var(--muted)]'}
							>{c.ok ? '✓' : '○'}</span
						>
						{#if c.ok}{c.label}{:else}<a href={localizeHref(c.href)}>{c.label}</a>{/if}
					</li>
				{/each}
			</ul>
		</Card>
		<Card title={m.dashboard_orgs()} testid="org-list">
			<ul class="grid gap-2">
				{#each me.organizations as o (o.organization.id)}
					<li
						class="flex items-center justify-between gap-2 rounded-lg border border-[var(--border)] px-3 py-2 text-sm"
					>
						<span>
							<strong>{o.organization.name}</strong>
							<span class="text-[var(--muted)]">
								· {o.organization.kind === 'personal' ? m.org_personal() : m.org_company()} · {roleLabel[
									o.role
								]()}</span
							>
						</span>
						<a href={localizeHref(`/admin/orgs/${o.organization.id}`)}>{m.org_open()}</a>
					</li>
				{/each}
			</ul>
			<a class="mt-4 inline-block text-sm" href={localizeHref('/admin/orgs/new')}>+ {m.org_new()}</a
			>
		</Card>
	</div>
</div>
