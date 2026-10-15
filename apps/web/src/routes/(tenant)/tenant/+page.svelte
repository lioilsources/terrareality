<script lang="ts">
	import { m } from '#lib/paraglide/messages.js';
	import { getLocale, localizeHref } from '#lib/paraglide/runtime.js';
	import { t } from '#lib/catalog.js';
	import { fmtDateTime } from '#lib/labels.js';
	import { statusLabel } from '#lib/applications.js';
	import { stateLabel } from '#lib/leasing.js';
	import { enhance } from '$app/forms';
	import Alert from '#lib/components/Alert.svelte';
	import Card from '#lib/components/Card.svelte';
	import type { PageProps } from './$types';

	let { data, form }: PageProps = $props();
	const locale = getLocale();
	const links = [
		['/zadosti', m.nav_applications],
		['/skupiny', m.nav_groups],
		['/spolubydleni', m.nav_roommates],
		['/pas', m.nav_passport],
		['/zpravy', m.nav_messages]
	] as const;
</script>

<h1 class="text-2xl font-semibold">{m.nav_tenant()}</h1>
<p class="mt-2 mb-6 text-[var(--muted)]">{m.tenant_hub_lead()}</p>
{#if data.me && !data.me.email_verified}
	<!-- Leases are linked to an account only after its e-mail is verified (B-1). -->
	<div class="mb-6">
		<Alert kind="info">
			<div class="flex flex-wrap items-center justify-between gap-2" data-testid="verify-leases">
				<span
					>{form?.resent
						? m.verify_resent()
						: m.tenant_verify_for_leases({ email: data.me.email })}</span
				>
				<form method="POST" action="?/resend" use:enhance>
					<button class="underline">{m.verify_resend()}</button>
				</form>
			</div>
		</Alert>
	</div>
{/if}
<nav class="mb-6 flex flex-wrap gap-3">
	{#each links as [href, label] (href)}
		<a
			href={localizeHref(href)}
			class="rounded-lg border border-[var(--border)] bg-[var(--surface)] px-4 py-2 no-underline hover:border-[var(--accent)]"
			>{label()}</a
		>
	{/each}
</nav>
<div class="grid gap-6 md:grid-cols-2">
	{#if data.leases.length}
		<Card title={m.lease_title()}>
			<ul class="grid gap-2 text-sm" data-testid="my-leases">
				{#each data.leases as l (l.id)}
					<li>
						<a href={localizeHref(`/smlouvy/${l.id}`)}>{l.property_address}</a>
						· {l.org_name} · {stateLabel[l.state]()}
					</li>
				{/each}
			</ul>
		</Card>
	{/if}
	<Card title={m.app_mine()}>
		{#if data.applications.length === 0}
			<p class="text-sm text-[var(--muted)]">{m.app_empty()}</p>
		{/if}
		<ul class="grid gap-2 text-sm">
			{#each data.applications.slice(0, 5) as a (a.id)}
				<li>
					<a href={localizeHref(`/zadosti/${a.id}`)}>{t(a.listing_title, locale)}</a>
					· {statusLabel[a.status]()}
				</li>
			{/each}
		</ul>
	</Card>
	<Card title={m.app_booking()}>
		<ul class="grid gap-2 text-sm" data-testid="my-viewings">
			{#each data.viewings as v (v.id)}
				<li>
					<a href={localizeHref(`/zadosti/${v.application_id}`)}>{t(v.listing_title, locale)}</a>
					· {fmtDateTime(v.starts_at, locale)}
				</li>
			{/each}
		</ul>
	</Card>
</div>
