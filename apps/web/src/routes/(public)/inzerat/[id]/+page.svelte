<script lang="ts">
	import { m } from '#lib/paraglide/messages.js';
	import { getLocale, localizeHref } from '#lib/paraglide/runtime.js';
	import { formatMoney, kindLabel, t, valueLabel } from '#lib/catalog.js';
	import { fmtDate } from '#lib/labels.js';
	import Alert from '#lib/components/Alert.svelte';
	import Button from '#lib/components/Button.svelte';
	import Card from '#lib/components/Card.svelte';
	import { enhance } from '$app/forms';
	import { page } from '$app/state';
	import type { PageProps } from './$types';

	let { data, form }: PageProps = $props();
	const locale = getLocale();
	const l = $derived(data.listing);
	const defOf = (key: string) => data.schema.attributes.find((a) => a.key === key);
	const title = $derived(t(l.title, locale) || kindLabel[l.unit.kind]());
	const jsonLd = $derived(
		JSON.stringify({
			'@context': 'https://schema.org',
			'@type': 'Offer',
			name: title,
			price: Math.round(l.rent_amount / 100),
			priceCurrency: l.currency,
			itemOffered: {
				'@type': 'Accommodation',
				floorSize: l.unit.floor_area
					? { '@type': 'QuantitativeValue', value: l.unit.floor_area, unitCode: 'MTK' }
					: undefined
			}
		}).replace(/</g, '\\u003c')
	);
</script>

<svelte:head>
	<title>{title} · {m.app_name()}</title>
	<meta name="description" content={t(l.description, locale).slice(0, 160)} />
	<!-- eslint-disable-next-line svelte/no-at-html-tags -- JSON-LD built from our data with < escaped -->
	{@html '<script type="application/ld+json">' + jsonLd + '</' + 'script>'}
</svelte:head>

<div class="grid gap-6 lg:grid-cols-[2fr_1fr]">
	<div class="grid content-start gap-4">
		{#if l.photos.length}
			<img
				src={l.photos[0].large}
				alt={title}
				class="aspect-[16/10] w-full rounded-[var(--radius-card)] object-cover"
			/>
			{#if l.photos.length > 1}
				<div class="grid grid-cols-4 gap-2">
					{#each l.photos.slice(1, 9) as p, i (i)}<img
							src={p.thumb}
							alt=""
							class="aspect-[4/3] w-full rounded object-cover"
							loading="lazy"
						/>{/each}
				</div>
			{/if}
		{/if}
		<h1 class="text-2xl font-semibold" data-testid="public-title">{title}</h1>
		<p class="text-[var(--muted)]">{l.area_names.slice(1).join(' · ')}</p>
		<p class="whitespace-pre-line">{t(l.description, locale)}</p>
		<Card>
			<ul class="grid gap-1 text-sm sm:grid-cols-2">
				{#each Object.entries(l.attributes) as [key, v] (key)}
					{#if defOf(key)}<li>
							<span class="text-[var(--muted)]">{t(defOf(key)?.label, locale)}:</span>
							{valueLabel(defOf(key), v, locale)}
						</li>{/if}
				{/each}
			</ul>
		</Card>
	</div>
	<div class="grid content-start gap-4">
		<Card>
			<p class="text-2xl font-semibold" data-testid="public-price">
				{m.price_per_month({ amount: formatMoney(l.rent_amount, locale) })}
			</p>
			<ul class="mt-2 grid gap-1 text-sm">
				{#if l.deposit_amount}<li>
						{m.listing_deposit({ amount: formatMoney(l.deposit_amount, locale) })}
					</li>{/if}
				{#if l.utilities_amount}<li>
						{m.listing_utilities({ amount: formatMoney(l.utilities_amount, locale) })}
					</li>{/if}
				{#if l.available_from}<li>
						{m.listing_available_from({ date: fmtDate(l.available_from, locale) })}
					</li>{/if}
				{#if l.min_term_months}<li>
						{m.listing_min_term({ months: String(l.min_term_months) })}
					</li>{/if}
			</ul>
			<p class="mt-3 text-sm text-[var(--muted)]">
				{l.location.address ?? m.listing_location_approx()}
			</p>
		</Card>
		<a
			href={localizeHref(`/inzerat/${l.id}/zadost`)}
			class="rounded-lg bg-[var(--accent)] px-4 py-3 text-center font-medium text-white no-underline hover:opacity-90"
			data-testid="apply">{m.app_apply()}</a
		>
		<Card title={m.msg_contact_title()} testid="contact">
			{#if data.conversation}
				<p class="mb-3 text-sm text-[var(--muted)]">{m.msg_contact_existing()}</p>
				<a href={localizeHref(`/zpravy/${data.conversation}`)}>{m.msg_open_conversation()}</a>
			{:else if !page.data.me}
				<p class="mb-3 text-sm text-[var(--muted)]">{m.msg_contact_login()}</p>
				<a href={localizeHref(`/login?next=${encodeURIComponent(page.url.pathname)}`)}
					>{m.nav_login()}</a
				>
			{:else}
				{#if form?.error}<div class="mb-3"><Alert kind="error">{form.error}</Alert></div>{/if}
				<form method="POST" action="?/contact" use:enhance class="grid gap-3">
					{#if l.prescreen.length}
						<fieldset class="grid gap-3">
							<legend class="mb-1 text-sm font-semibold">{m.msg_prescreen_title()}</legend>
							{#each l.prescreen as q (q.id)}
								{@const label =
									(q.text[locale as 'cs'] || q.text.cs || q.text.en) + (q.required ? ' *' : '')}
								{#if q.kind === 'yes_no'}
									<div class="grid gap-1 text-sm">
										<span class="font-medium">{label}</span>
										<div class="flex gap-4">
											<label class="flex items-center gap-1"
												><input type="radio" name="q_{q.id}" value="yes" required={q.required} />
												{m.msg_yes()}</label
											>
											<label class="flex items-center gap-1"
												><input type="radio" name="q_{q.id}" value="no" /> {m.msg_no()}</label
											>
										</div>
									</div>
								{:else}
									<label class="grid gap-1 text-sm font-medium"
										>{label}
										<input
											name="q_{q.id}"
											type={q.kind === 'number' ? 'number' : 'text'}
											required={q.required}
											maxlength="500"
											value={form?.answers?.[q.id!] ?? ''}
											class="rounded-lg border border-[var(--border)] bg-[var(--surface)] px-3 py-2"
										/>
									</label>
								{/if}
							{/each}
						</fieldset>
					{/if}
					<label class="grid gap-1 text-sm font-medium"
						>{m.msg_body_label()}
						<textarea
							name="body"
							rows="4"
							required
							maxlength="4000"
							class="rounded-lg border border-[var(--border)] bg-[var(--surface)] px-3 py-2"
							>{form?.body ?? ''}</textarea
						>
					</label>
					<p class="text-xs text-[var(--muted)]">{m.msg_safety()}</p>
					<Button type="submit">{m.msg_send()}</Button>
				</form>
			{/if}
		</Card>
		<p class="text-sm">
			<a
				href={localizeHref(`/inzerat/${l.id}/nahlasit`)}
				class="text-[var(--muted)] hover:text-[var(--text)]"
				data-testid="report-listing-link">{m.dsa_report_link()}</a
			>
		</p>
		{#if data.similar.length}
			<Card title={m.listing_similar()}>
				<ul class="grid gap-2 text-sm">
					{#each data.similar as s (s.id)}
						<li>
							<a href={localizeHref(`/inzerat/${s.id}`)}
								>{t(s.title, locale) || kindLabel[s.unit_kind]()}</a
							>
							· {formatMoney(s.rent_amount, locale)} Kč
						</li>
					{/each}
				</ul>
			</Card>
		{/if}
	</div>
</div>
