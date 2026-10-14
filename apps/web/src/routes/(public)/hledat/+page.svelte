<script lang="ts">
	import { enhance } from '$app/forms';
	import { goto } from '$app/navigation';
	import { page } from '$app/state';
	import { m } from '#lib/paraglide/messages.js';
	import { getLocale, localizeHref } from '#lib/paraglide/runtime.js';
	import { formatMoney, kindLabel, layouts, t } from '#lib/catalog.js';
	import { PAGE_SIZE } from '#lib/searchParams.js';
	import Alert from '#lib/components/Alert.svelte';
	import Button from '#lib/components/Button.svelte';
	import SearchMap from '#lib/components/map/SearchMap.svelte';
	import type { PageProps } from './$types';

	let { data, form }: PageProps = $props();
	const locale = getLocale();
	const q = $derived(data.query);
	const res = $derived(data.result);
	const kinds = ['apartment', 'room', 'house', 'parking', 'storage', 'commercial'];
	const pageNo = $derived(Math.floor((q.offset ?? 0) / PAGE_SIZE) + 1);
	const facetAttrs = $derived(
		data.schema.attributes.filter(
			(a) =>
				a.filter &&
				(a.type === 'bool' || a.type === 'enum' || a.type === 'set') &&
				a.key !== 'layout' &&
				res?.facets[a.key]?.length
		)
	);
	const input =
		'w-full rounded-lg border border-[var(--border)] bg-[var(--surface)] px-2 py-1.5 text-sm';
	const price = (minor: number) => `${formatMoney(minor, locale)} Kč`;

	function withParams(change: (p: URLSearchParams) => void) {
		// A throwaway copy for building a link, not reactive state.
		// eslint-disable-next-line svelte/prefer-svelte-reactivity
		const p = new URLSearchParams(page.url.search);
		p.delete('reply');
		p.delete('degraded');
		p.delete('page');
		change(p);
		return localizeHref(`/hledat?${p}`);
	}
	const selected = (key: string, value: string) =>
		page.url.searchParams.getAll(`a.${key}`).includes(value);
	const optLabel = (key: string, value: string) => {
		const a = data.schema.attributes.find((x) => x.key === key);
		return t(a?.options.find((o) => o.value === value)?.label, locale) || value;
	};
</script>

<svelte:head><title>{m.search_title()} · {m.app_name()}</title></svelte:head>

<div class="grid gap-4">
	<form method="POST" action="?/chat" use:enhance class="flex gap-2" role="search">
		<input
			name="message"
			class="flex-1 rounded-xl border border-[var(--border)] bg-[var(--surface)] px-4 py-3 text-base shadow-sm focus:border-[var(--accent)] focus:outline-none"
			placeholder={m.search_chat_placeholder()}
			aria-label={m.search_chat_placeholder()}
			autocomplete="off"
		/>
		<Button type="submit">{m.search_chat_submit()}</Button>
	</form>
	{#if data.reply}<Alert kind="info"><span data-testid="chat-reply">{data.reply}</span></Alert>{/if}
	{#if data.error || form?.error}<Alert kind="error">{data.error ?? form?.error}</Alert>{/if}

	<div class="grid gap-4 lg:grid-cols-[16rem_1fr]">
		<form
			method="GET"
			class="grid content-start gap-4 text-sm"
			aria-label={m.search_filters()}
			data-testid="filters"
		>
			{#if q.admin_path}<input type="hidden" name="area" value={q.admin_path} />{/if}
			{#if q.text}<input type="hidden" name="text" value={q.text} />{/if}
			<fieldset class="grid gap-1">
				<legend class="font-semibold">{m.search_kind()}</legend>
				{#each kinds as k (k)}
					<label class="flex gap-2"
						><input type="checkbox" name="kind" value={k} checked={q.kinds?.includes(k as never)} />
						{kindLabel[k]()}</label
					>
				{/each}
			</fieldset>
			<fieldset class="grid grid-cols-2 gap-2">
				<legend class="col-span-2 font-semibold">{m.search_rent()}</legend>
				<input
					class={input}
					type="number"
					name="rent_min"
					placeholder={m.search_from()}
					value={q.rent_min ? q.rent_min / 100 : ''}
					aria-label="{m.search_rent()} {m.search_from()}"
				/>
				<input
					class={input}
					type="number"
					name="rent_max"
					placeholder={m.search_to()}
					value={q.rent_max ? q.rent_max / 100 : ''}
					aria-label="{m.search_rent()} {m.search_to()}"
				/>
			</fieldset>
			<fieldset class="grid grid-cols-2 gap-2">
				<legend class="col-span-2 font-semibold">{m.search_area()}</legend>
				<input
					class={input}
					type="number"
					name="area_min"
					placeholder={m.search_from()}
					value={q.area_min ?? ''}
					aria-label="{m.search_area()} {m.search_from()}"
				/>
				<input
					class={input}
					type="number"
					name="area_max"
					placeholder={m.search_to()}
					value={q.area_max ?? ''}
					aria-label="{m.search_area()} {m.search_to()}"
				/>
			</fieldset>
			<fieldset class="flex flex-wrap gap-x-3 gap-y-1">
				<legend class="w-full font-semibold"
					>{t(data.schema.attributes.find((a) => a.key === 'layout')?.label, locale)}</legend
				>
				{#each layouts as l (l)}
					{@const n = res?.facets.layout?.find((f) => f.value === l)?.count}
					<label class="flex gap-1"
						><input type="checkbox" name="layout" value={l} checked={q.layouts?.includes(l)} />
						{l}{n ? ` (${n})` : ''}</label
					>
				{/each}
			</fieldset>
			{#each facetAttrs as a (a.key)}
				<fieldset class="grid gap-1">
					<legend class="font-semibold">{t(a.label, locale)}</legend>
					{#if a.type === 'bool'}
						{@const n = res?.facets[a.key]?.find((f) => f.value === 'true')?.count ?? 0}
						<label class="flex gap-2"
							><input
								type="checkbox"
								name="a.{a.key}"
								value="true"
								checked={selected(a.key, 'true')}
							/>
							{m.yes()} ({n})</label
						>
					{:else}
						{#each res?.facets[a.key] ?? [] as f (f.value)}
							<label class="flex gap-2"
								><input
									type="checkbox"
									name="a.{a.key}"
									value={f.value}
									checked={selected(a.key, f.value)}
								/>
								{optLabel(a.key, f.value)} ({f.count})</label
							>
						{/each}
					{/if}
				</fieldset>
			{/each}
			<label class="grid gap-1"
				><span class="font-semibold">{m.search_sort()}</span>
				<select name="sort" class={input}>
					{#each [['relevance', m.sort_relevance], ['newest', m.sort_newest], ['price_asc', m.sort_price_asc], ['price_desc', m.sort_price_desc], ['area_desc', m.sort_area_desc]] as [v, label] (v)}
						<option value={v} selected={(q.sort ?? 'relevance') === v}
							>{(label as () => string)()}</option
						>
					{/each}
				</select>
			</label>
			<Button type="submit">{m.search_apply()}</Button>
			<a href={localizeHref('/hledat')}>{m.search_reset()}</a>
		</form>

		<div class="grid content-start gap-4">
			{#if res}
				<div class="flex flex-wrap items-center gap-3 text-sm">
					<strong data-testid="result-count"
						>{m.search_results({ count: String(res.total) })}</strong
					>
					<a href={withParams((p) => p.delete('area'))}>{m.search_all_areas()}</a>
					{#each res.areas.slice(0, 8) as a (a.path)}
						<a
							class="rounded-full border border-[var(--border)] px-2 py-0.5 no-underline"
							href={withParams((p) => (p.set('area', a.path), p.delete('bbox')))}
							>{a.name} · {a.count}</a
						>
					{/each}
				</div>
				<div class="h-[26rem]">
					<SearchMap
						result={res}
						areas={data.areas}
						bbox={q.bbox ?? null}
						boundsLabel={m.search_map_area()}
						formatPrice={(minor) => `${Math.round(minor / 100000)}k`}
						onArea={(path) => goto(withParams((p) => (p.set('area', path), p.delete('bbox'))))}
						onBounds={(b) =>
							goto(withParams((p) => p.set('bbox', b.map((n) => n.toFixed(5)).join(','))))}
						onListing={(id) => goto(localizeHref(`/inzerat/${id}`))}
					/>
				</div>
				{#if res.items.length === 0}
					<p class="text-sm text-[var(--muted)]">{m.search_no_results()}</p>
				{:else}
					<ul class="grid gap-3 sm:grid-cols-2 xl:grid-cols-3" data-testid="results">
						{#each res.items as c (c.id)}
							<li>
								<a
									href={localizeHref(`/inzerat/${c.id}`)}
									class="block overflow-hidden rounded-[var(--radius-card)] border border-[var(--border)] bg-[var(--surface)] no-underline hover:border-[var(--accent)]"
								>
									<div class="aspect-[4/3] bg-[var(--border)]/40">
										{#if c.cover_url}<img
												src={c.cover_url}
												alt=""
												class="h-full w-full object-cover"
												loading="lazy"
											/>{/if}
									</div>
									<div class="grid gap-0.5 p-3 text-sm text-[var(--text)]">
										<strong>{t(c.title, locale) || kindLabel[c.unit_kind]()}</strong>
										<span class="text-[var(--muted)]"
											>{c.city_part ?? c.city}{c.floor_area ? ` · ${c.floor_area} m²` : ''}</span
										>
										<span class="font-semibold">{price(c.rent_amount)}</span>
									</div>
								</a>
							</li>
						{/each}
					</ul>
					<nav class="flex gap-4 text-sm">
						{#if pageNo > 1}<a href={withParams((p) => p.set('page', String(pageNo - 1)))}
								>← {m.search_prev()}</a
							>{/if}
						{#if pageNo * PAGE_SIZE < res.total}<a
								href={withParams((p) => p.set('page', String(pageNo + 1)))}>{m.search_more()} →</a
							>{/if}
					</nav>
				{/if}
				{#if form?.saved}
					<Alert kind="success">{m.search_saved()}</Alert>
				{:else}
					<form
						method="POST"
						action="?/save"
						use:enhance
						class="flex flex-wrap items-end gap-2 text-sm"
					>
						{#if data.loggedIn}<input
								name="name"
								class={input + ' max-w-60'}
								placeholder={m.search_save_name()}
								aria-label={m.search_save_name()}
							/>{/if}
						<Button type="submit" variant="secondary">🔔 {m.search_save()}</Button>
					</form>
				{/if}
			{/if}
		</div>
	</div>
</div>
