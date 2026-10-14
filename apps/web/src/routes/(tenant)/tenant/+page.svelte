<script lang="ts">
	import { m } from '#lib/paraglide/messages.js';
	import { getLocale, localizeHref } from '#lib/paraglide/runtime.js';
	import { t } from '#lib/catalog.js';
	import { fmtDateTime } from '#lib/labels.js';
	import { statusLabel } from '#lib/applications.js';
	import Card from '#lib/components/Card.svelte';
	import type { PageProps } from './$types';

	let { data }: PageProps = $props();
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
