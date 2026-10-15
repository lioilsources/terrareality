<script lang="ts">
	import { enhance } from '$app/forms';
	import { m } from '#lib/paraglide/messages.js';
	import { getLocale, localizeHref } from '#lib/paraglide/runtime.js';
	import { t } from '#lib/catalog.js';
	import { fmtDateTime } from '#lib/labels.js';
	import Alert from '#lib/components/Alert.svelte';
	import Button from '#lib/components/Button.svelte';
	import Card from '#lib/components/Card.svelte';
	import Field from '#lib/components/Field.svelte';
	import type { PageProps } from './$types';

	let { data, form }: PageProps = $props();
	const locale = getLocale();
	const tab = 'rounded-lg border border-[var(--border)] px-3 py-1 text-sm no-underline';
</script>

<svelte:head><title>{m.bo_attrs()} · {m.nav_backoffice()}</title></svelte:head>

<div class="grid gap-6">
	<h1 class="text-2xl font-semibold">{m.bo_attrs()}</h1>
	<Alert kind="info">{m.bo_attrs_hint()}</Alert>
	{#if data.error}<Alert kind="error">{data.error}</Alert>{/if}
	{#if form?.error}<Alert kind="error">{form.error}</Alert>{/if}
	<nav aria-label={m.bo_attrs_filter()} class="flex gap-2">
		<a
			href={localizeHref('/backoffice/atributy')}
			class="{tab} {data.view === 'open' ? 'border-[var(--accent)] font-semibold' : ''}"
			aria-current={data.view === 'open' ? 'page' : undefined}>{m.bo_attrs_open()}</a
		>
		<a
			href={localizeHref('/backoffice/atributy?stav=rozhodnute')}
			class="{tab} {data.view === 'decided' ? 'border-[var(--accent)] font-semibold' : ''}"
			aria-current={data.view === 'decided' ? 'page' : undefined}>{m.bo_attrs_decided()}</a
		>
	</nav>
	<Card>
		{#if data.items.length === 0}
			<p class="text-sm text-[var(--muted)]" data-testid="bo-attrs-empty">{m.bo_attrs_empty()}</p>
		{:else}
			<ul class="grid gap-3" data-testid="bo-attrs">
				{#each data.items as s (s.id)}
					<li
						class="grid gap-2 rounded-lg border border-[var(--border)] p-3 text-sm"
						data-testid="bo-attr-{s.id}"
					>
						<h2 class="text-base font-semibold">
							{t(s.label, locale) || s.key} <code class="text-xs font-normal">{s.key}</code>
						</h2>
						<dl class="grid grid-cols-[auto_1fr] gap-x-3 gap-y-1">
							<dt class="text-[var(--muted)]">{m.bo_attrs_type()}</dt>
							<dd><code>{s.type}</code></dd>
							<dt class="text-[var(--muted)]">{m.bo_attrs_group()}</dt>
							<dd><code>{s.group_key}</code></dd>
							{#if s.options.length}
								<dt class="text-[var(--muted)]">{m.bo_attrs_options()}</dt>
								<dd>{s.options.map((o) => t(o.label, locale) || o.value).join(', ')}</dd>
							{/if}
							{#if s.example_listing_id}
								<dt class="text-[var(--muted)]">{m.bo_attrs_example()}</dt>
								<dd>
									<a href={localizeHref(`/inzerat/${s.example_listing_id}`)}
										><code>{s.example_listing_id}</code></a
									>
								</dd>
							{/if}
							{#if s.model}
								<dt class="text-[var(--muted)]">{m.bo_attrs_model()}</dt>
								<dd>{s.model}</dd>
							{/if}
						</dl>
						<p class="text-xs text-[var(--muted)]">
							{m.bo_occurrences({ count: String(s.occurrences) })} · {fmtDateTime(
								s.created_at,
								locale
							)}
						</p>
						{#if s.status === 'open'}
							<form method="POST" use:enhance class="grid max-w-xl gap-2">
								<input type="hidden" name="id" value={s.id} />
								<Field label={m.bo_attrs_note()} name="note" />
								<div class="flex flex-wrap gap-2">
									<Button type="submit" name="decision" value="approve"
										>{m.bo_attrs_approve()}</Button
									>
									<Button type="submit" variant="secondary" name="decision" value="reject"
										>{m.bo_attrs_reject()}</Button
									>
								</div>
							</form>
						{:else}
							<p data-testid="bo-attr-status">
								<strong
									>{s.status === 'approved' ? m.bo_attrs_approved() : m.bo_attrs_rejected()}</strong
								>
								{#if s.decided_at}· {fmtDateTime(s.decided_at, locale)}{/if}
								{#if s.note}· „{s.note}“{/if}
							</p>
						{/if}
					</li>
				{/each}
			</ul>
		{/if}
	</Card>
</div>
