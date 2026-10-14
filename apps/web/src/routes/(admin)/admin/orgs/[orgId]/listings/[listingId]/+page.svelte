<script lang="ts">
	import { enhance } from '$app/forms';
	import { invalidateAll } from '$app/navigation';
	import { m } from '#lib/paraglide/messages.js';
	import { getLocale, localizeHref } from '#lib/paraglide/runtime.js';
	import {
		applicable,
		crowns,
		formatMoney,
		kindLabel,
		statusLabel,
		t,
		valueLabel,
		versionLabel
	} from '#lib/catalog.js';
	import { fieldMessages } from '#lib/fieldErrors.js';
	import { fmtDateTime } from '#lib/labels.js';
	import Alert from '#lib/components/Alert.svelte';
	import Button from '#lib/components/Button.svelte';
	import Card from '#lib/components/Card.svelte';
	import Field from '#lib/components/Field.svelte';
	import type { PageProps } from './$types';

	let { data, form }: PageProps = $props();
	const locale = getLocale();
	const l = $derived(data.listing);
	const defs = $derived(applicable(data.schema, l.unit.kind));
	const defOf = (key: string) => data.schema.attributes.find((a) => a.key === key);
	const labelOf = (key: string) => t(defOf(key)?.label, locale) || key;
	const groups = $derived(
		data.schema.groups
			.map((g) => ({ ...g, attrs: defs.filter((a) => a.group === g.key) }))
			.filter((g) => g.attrs.length > 0)
	);
	const busy = $derived(
		l.suggestions.some((s) => s.status === 'generating') ||
			l.media.some((x) => x.status === 'uploading' || x.status === 'processing')
	);
	const pendingOf = (kind: string) =>
		l.suggestions.find(
			(s) =>
				s.kind === kind &&
				(s.status === 'pending' || s.status === 'generating' || s.status === 'failed')
		);
	const attrSuggestion = $derived(pendingOf('attributes'));
	const textSuggestion = $derived(pendingOf('text'));
	const errors = $derived(fieldMessages(form?.fieldErrors, labelOf));
	const href = (step: string) =>
		localizeHref(`/admin/orgs/${l.org_id}/listings/${l.id}?step=${step}`);
	const stepLabel: Record<string, () => string> = {
		attributes: m.step_attributes,
		photos: m.step_photos,
		text: m.step_text,
		preview: m.step_preview
	};
	const input = 'rounded-lg border border-[var(--border)] bg-[var(--surface)] px-3 py-2';
	// Actions keep the current step in the URL (also for submits without JavaScript).
	const act = (name: string) => `?step=${data.step}&/${name}`;

	// Poll while AI suggestions or photos are being processed.
	$effect(() => {
		if (!busy) return;
		const id = setInterval(() => invalidateAll(), 1500);
		return () => clearInterval(id);
	});
</script>

<svelte:head><title>{t(l.title, locale) || m.listings_title()}</title></svelte:head>

<div class="grid gap-6">
	<div class="flex flex-wrap items-baseline justify-between gap-3">
		<div>
			<a class="text-sm" href={localizeHref(`/admin/orgs/${l.org_id}/listings`)}
				>← {m.listings_title()}</a
			>
			<h1 class="text-2xl font-semibold" data-testid="listing-title">
				{t(l.title, locale) || `${kindLabel[l.unit.kind]()} · ${l.unit.label}`}
			</h1>
			<p class="text-sm text-[var(--muted)]">{l.address.label}</p>
		</div>
		<a href={localizeHref(`/admin/orgs/${l.org_id}/listings/${l.id}/otazky`)} class="text-sm"
			>{m.msg_prescreen_edit()} ({l.prescreen.length})</a
		>
		<span class="rounded bg-[var(--border)]/60 px-3 py-1 text-sm" data-testid="listing-status"
			>{statusLabel[l.status]()}{l.pending_review && l.status !== 'review'
				? ` · ${m.pending_review()}`
				: ''}</span
		>
	</div>

	<nav class="flex flex-wrap gap-2 text-sm" aria-label={m.listings_title()}>
		{#each data.steps as s, i (s)}
			<a
				href={href(s)}
				class="rounded-lg px-3 py-1.5 no-underline {data.step === s
					? 'bg-[var(--accent)] text-white'
					: 'text-[var(--muted)] hover:bg-[var(--border)]/40'}"
				aria-current={data.step === s ? 'step' : undefined}>{i + 3}. {stepLabel[s]()}</a
			>
		{/each}
	</nav>

	{#if form?.error}<Alert kind="error"
			>{form.error}
			{#if errors.length}<ul class="mt-1 list-disc pl-5">
					{#each errors as e (e)}<li>{e}</li>{/each}
				</ul>{/if}</Alert
		>{/if}
	{#if form?.saved}<Alert kind="success">{m.saved()}</Alert>{/if}

	{#if data.step === 'attributes'}
		{#if attrSuggestion}
			<Card title={m.ai_attr_title()} testid="ai-attributes">
				{#if attrSuggestion.status === 'generating'}
					<p class="text-sm">{m.ai_generating()}</p>
				{:else if attrSuggestion.status === 'failed'}
					<Alert kind="error">{m.ai_failed({ error: attrSuggestion.error ?? '' })}</Alert>
				{:else}
					{@const values = (attrSuggestion.payload.values ?? {}) as Record<string, unknown>}
					{@const newOpts = (attrSuggestion.payload.new_options ?? []) as {
						key: string;
						value: string;
						label: { cs: string; en: string };
					}[]}
					<form method="POST" action={act('decide')} use:enhance class="grid gap-3">
						<input type="hidden" name="id" value={attrSuggestion.id} />
						<input type="hidden" name="accept" value="true" />
						<input type="hidden" name="partial" value="true" />
						<p class="text-sm text-[var(--muted)]">{m.ai_attr_hint()}</p>
						{#if Object.keys(values).length === 0}<p class="text-sm">{m.ai_nothing_new()}</p>{/if}
						<ul class="grid gap-1 sm:grid-cols-2">
							{#each Object.entries(values) as [key, v] (key)}
								<li>
									<label class="flex items-center gap-2 text-sm">
										<input type="checkbox" name="key" value={key} checked />
										<span>{labelOf(key)}: <strong>{valueLabel(defOf(key), v, locale)}</strong></span
										>
									</label>
								</li>
							{/each}
						</ul>
						{#if newOpts.length}
							<p class="text-xs text-[var(--muted)]">
								{m.ai_new_options({
									list: newOpts.map((o) => `${labelOf(o.key)}: ${t(o.label, locale)}`).join(', ')
								})}
							</p>
						{/if}
						<div class="flex gap-2">
							<Button type="submit">{m.ai_accept_selected()}</Button>
							<Button
								type="submit"
								variant="secondary"
								formaction={act('decide')}
								name="accept"
								value="false">{m.ai_reject()}</Button
							>
						</div>
					</form>
				{/if}
			</Card>
		{/if}

		<form method="POST" action={act('attributes')} use:enhance class="grid gap-6">
			<Card title={m.step_attributes()}>
				<div class="grid gap-4 sm:grid-cols-2">
					<Field
						label={m.field_rent()}
						name="rent"
						type="number"
						min="1"
						value={crowns(l.rent_amount)}
					/>
					<Field
						label={m.field_deposit()}
						name="deposit"
						type="number"
						min="0"
						value={crowns(l.deposit_amount)}
						hint={m.field_deposit_hint({ months: String(l.deposit_max_months) })}
					/>
					<Field
						label={m.field_utilities()}
						name="utilities"
						type="number"
						min="0"
						value={crowns(l.utilities_amount)}
					/>
					<Field
						label={m.field_available_from()}
						name="available_from"
						type="date"
						value={l.available_from ?? ''}
					/>
					<Field
						label={m.field_min_term()}
						name="min_term_months"
						type="number"
						min="0"
						max="120"
						value={l.min_term_months?.toString() ?? ''}
					/>
					<fieldset class="grid gap-1 text-sm">
						<legend class="font-medium">{m.field_precision()}</legend>
						<label class="flex gap-2"
							><input
								type="radio"
								name="location_precision"
								value="approximate"
								checked={l.location_precision === 'approximate'}
							/>
							{m.precision_approximate()}</label
						>
						<label class="flex gap-2"
							><input
								type="radio"
								name="location_precision"
								value="exact"
								checked={l.location_precision === 'exact'}
							/>
							{m.precision_exact()}</label
						>
					</fieldset>
				</div>
			</Card>
			{#each groups as g (g.key)}
				<Card title={t(g.label, locale)}>
					<div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
						{#each g.attrs as a (a.key)}
							{@const v = l.attributes[a.key]}
							{#if a.type === 'bool'}
								<label class="grid gap-1 text-sm font-medium"
									>{t(a.label, locale)}
									<select name="attr.{a.key}" class={input}>
										<option value="">{m.unset()}</option>
										<option value="true" selected={v === true}>{m.yes()}</option>
										<option value="false" selected={v === false}>{m.no()}</option>
									</select>
								</label>
							{:else if a.type === 'int' || a.type === 'range'}
								<label class="grid gap-1 text-sm font-medium"
									>{t(a.label, locale)}{a.unit ? ` (${a.unit.replace('m2', 'm²')})` : ''}
									<input
										type="number"
										name="attr.{a.key}"
										class={input}
										value={v ?? ''}
										min={a.min}
										max={a.max}
										step="any"
									/>
								</label>
							{:else if a.type === 'enum'}
								<label class="grid gap-1 text-sm font-medium"
									>{t(a.label, locale)}
									<select name="attr.{a.key}" class={input}>
										<option value="">{m.unset()}</option>
										{#each a.options as o (o.value)}<option value={o.value} selected={v === o.value}
												>{t(o.label, locale)}</option
											>{/each}
									</select>
								</label>
							{:else if a.type === 'set'}
								<fieldset class="grid gap-1 text-sm">
									<legend class="font-medium">{t(a.label, locale)}</legend>
									{#each a.options as o (o.value)}
										<label class="flex gap-2"
											><input
												type="checkbox"
												name="attr.{a.key}"
												value={o.value}
												checked={Array.isArray(v) && v.includes(o.value)}
											/>
											{t(o.label, locale)}</label
										>
									{/each}
								</fieldset>
							{/if}
						{/each}
					</div>
				</Card>
			{/each}
			<div class="flex flex-wrap gap-2">
				<Button type="submit">{m.save()}</Button>
			</div>
		</form>
		<form method="POST" action={act('suggest')} use:enhance>
			<input type="hidden" name="kind" value="attributes" />
			<Button type="submit" variant="secondary" disabled={attrSuggestion?.status === 'generating'}
				>✨ {m.ai_suggest_attributes()}</Button
			>
		</form>
	{:else if data.step === 'photos'}
		<Card title={m.step_photos()} testid="photos">
			<form
				method="POST"
				action={act('upload')}
				enctype="multipart/form-data"
				use:enhance
				class="mb-4 grid gap-2"
			>
				<label class="text-sm font-medium" for="photos">{m.photos_upload()}</label>
				<input
					id="photos"
					type="file"
					name="photos"
					accept="image/jpeg,image/png,image/webp"
					multiple
				/>
				<p class="text-xs text-[var(--muted)]">{m.photos_hint()}</p>
				<div><Button type="submit">{m.photos_upload()}</Button></div>
			</form>
			{#if l.media.length === 0}<p class="text-sm text-[var(--muted)]">{m.photos_empty()}</p>{/if}
			<ul class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
				{#each l.media as ph, i (ph.id)}
					{@const caption = l.suggestions.find(
						(s) => s.media_id === ph.id && s.kind === 'photo_tags' && s.status === 'pending'
					)}
					{@const privacy = l.suggestions.find(
						(s) => s.media_id === ph.id && s.kind === 'privacy_blur' && s.status === 'pending'
					)}
					<li
						class="overflow-hidden rounded-lg border border-[var(--border)]"
						data-testid="photo"
						data-status={ph.status}
					>
						<div
							class="flex aspect-[4/3] items-center justify-center bg-[var(--border)]/40 text-sm text-[var(--muted)]"
						>
							{#if ph.status === 'ready' && ph.urls.thumb}
								<img
									src={ph.urls.thumb}
									alt={t(ph.caption, locale) || ph.filename}
									class="h-full w-full object-cover"
								/>
							{:else if ph.status === 'rejected'}
								{m.photos_rejected({ reason: ph.rejection_reason ?? '' })}
							{:else}
								{m.photos_processing()}…
							{/if}
						</div>
						<div class="grid gap-2 p-2 text-sm">
							<span class="truncate">{t(ph.caption, locale) || ph.filename}</span>
							{#if caption}
								<form
									method="POST"
									action={act('decide')}
									use:enhance
									class="flex flex-wrap items-center gap-2 text-xs"
								>
									<input type="hidden" name="id" value={caption.id} />
									<span
										>{m.ai_photo_caption({ caption: String(caption.payload.caption ?? '') })}</span
									>
									<button name="accept" value="true" class="underline">{m.ai_accept()}</button>
									<button name="accept" value="false" class="underline">{m.ai_reject()}</button>
								</form>
							{/if}
							{#if privacy}
								<form
									method="POST"
									action={act('decide')}
									use:enhance
									class="flex flex-wrap items-center gap-2 rounded bg-amber-100 p-2 text-xs text-amber-950"
								>
									<input type="hidden" name="id" value={privacy.id} />
									<span>{m.ai_privacy()}</span>
									<button name="accept" value="true" class="font-semibold underline"
										>{m.ai_blur()}</button
									>
									<button name="accept" value="false" class="underline">{m.ai_keep()}</button>
								</form>
							{/if}
							<form method="POST" use:enhance class="flex gap-2 text-xs">
								<input type="hidden" name="id" value={ph.id} />
								<button
									formaction={act('movePhoto')}
									name="dir"
									value="left"
									disabled={i === 0}
									class="underline disabled:opacity-40">← {m.photos_left()}</button
								>
								<button
									formaction={act('movePhoto')}
									name="dir"
									value="right"
									disabled={i === l.media.length - 1}
									class="underline disabled:opacity-40">{m.photos_right()} →</button
								>
								<button formaction={act('deletePhoto')} class="ml-auto text-red-700 underline"
									>{m.remove()}</button
								>
							</form>
						</div>
					</li>
				{/each}
			</ul>
		</Card>
	{:else if data.step === 'text'}
		{#if textSuggestion}
			<Card title={m.ai_text_title()} testid="ai-text">
				{#if textSuggestion.status === 'generating'}
					<p class="text-sm">{m.ai_generating()}</p>
				{:else if textSuggestion.status === 'failed'}
					<Alert kind="error">{m.ai_failed({ error: textSuggestion.error ?? '' })}</Alert>
				{:else}
					{@const tt = textSuggestion.payload.title as { cs: string; en: string }}
					{@const dd = textSuggestion.payload.description as { cs: string; en: string }}
					<div class="grid gap-3 text-sm md:grid-cols-2">
						<div>
							<strong>{tt.cs}</strong>
							<p class="mt-1 whitespace-pre-line">{dd.cs}</p>
						</div>
						<div>
							<strong>{tt.en}</strong>
							<p class="mt-1 whitespace-pre-line">{dd.en}</p>
						</div>
					</div>
					<form method="POST" action={act('decide')} use:enhance class="mt-3 flex gap-2">
						<input type="hidden" name="id" value={textSuggestion.id} />
						<Button type="submit" name="accept" value="true">{m.ai_accept()}</Button>
						<Button type="submit" variant="secondary" name="accept" value="false"
							>{m.ai_reject()}</Button
						>
					</form>
				{/if}
			</Card>
		{/if}
		<form method="POST" action={act('text')} use:enhance class="grid gap-4">
			<Card title={m.step_text()}>
				<div class="grid gap-4 md:grid-cols-2">
					<Field label={m.field_title_cs()} name="title_cs" value={l.title.cs} maxlength={120} />
					<Field label={m.field_title_en()} name="title_en" value={l.title.en} maxlength={120} />
					<label class="grid gap-1 text-sm font-medium"
						>{m.field_description_cs()}
						<textarea name="description_cs" rows="12" class={input}>{l.description.cs}</textarea>
					</label>
					<label class="grid gap-1 text-sm font-medium"
						>{m.field_description_en()}
						<textarea name="description_en" rows="12" class={input}>{l.description.en}</textarea>
					</label>
				</div>
			</Card>
			<div><Button type="submit">{m.save()}</Button></div>
		</form>
		<form method="POST" action={act('suggest')} use:enhance>
			<input type="hidden" name="kind" value="text" />
			<Button type="submit" variant="secondary" disabled={textSuggestion?.status === 'generating'}
				>✨ {m.ai_suggest_text()}</Button
			>
		</form>
	{:else}
		<div class="grid gap-6 lg:grid-cols-[2fr_1fr]">
			<Card testid="preview">
				{#if l.media[0]?.urls.medium}<img
						src={l.media[0].urls.medium}
						alt=""
						class="mb-4 aspect-[16/9] w-full rounded-lg object-cover"
					/>{/if}
				<h2 class="text-xl font-semibold">{t(l.title, locale)}</h2>
				<p class="text-sm text-[var(--muted)]">{l.address.label}</p>
				{#if l.rent_amount}<p class="mt-2 text-lg font-semibold">
						{m.price_per_month({ amount: formatMoney(l.rent_amount, locale) })}
					</p>{/if}
				<p class="mt-4 text-sm whitespace-pre-line">{t(l.description, locale)}</p>
				<ul class="mt-4 grid gap-1 text-sm sm:grid-cols-2">
					{#each Object.entries(l.attributes) as [key, v] (key)}
						<li>
							<span class="text-[var(--muted)]">{labelOf(key)}:</span>
							{valueLabel(defOf(key), v, locale)}
						</li>
					{/each}
				</ul>
			</Card>
			<div class="grid content-start gap-6">
				<Card>
					{#if form?.submitted}<div class="mb-3">
							<Alert kind="success">{m.preview_submitted()}</Alert>
						</div>{/if}
					<p class="mb-3 text-sm text-[var(--muted)]">{m.preview_hint()}</p>
					{#if l.status !== 'archived' && l.status !== 'rented'}
						<form method="POST" action={act('submit')} use:enhance>
							<Button type="submit"
								>{l.published_version ? m.preview_resubmit() : m.preview_submit()}</Button
							>
						</form>
					{/if}
				</Card>
				<Card title={m.listing_actions()}>
					<form method="POST" use:enhance class="flex flex-wrap gap-2">
						{#if l.status === 'published'}<Button
								type="submit"
								variant="secondary"
								formaction={act('status')}
								name="status"
								value="paused">{m.action_pause()}</Button
							>{/if}
						{#if l.status === 'paused'}<Button
								type="submit"
								variant="secondary"
								formaction={act('status')}
								name="status"
								value="published">{m.action_resume()}</Button
							>{/if}
						{#if l.status === 'published' || l.status === 'paused'}<Button
								type="submit"
								variant="secondary"
								formaction={act('status')}
								name="status"
								value="rented">{m.action_rented()}</Button
							>{/if}
						<Button type="submit" variant="secondary" formaction={act('duplicate')}
							>{m.action_duplicate()}</Button
						>
						{#if l.status !== 'archived'}<Button
								type="submit"
								variant="danger"
								formaction={act('status')}
								name="status"
								value="archived">{m.action_archive()}</Button
							>{/if}
					</form>
				</Card>
				{#if l.versions.length}
					<Card title={m.versions_title()}>
						<ul class="grid gap-2 text-sm" data-testid="versions">
							{#each l.versions as v (v.id)}
								<li>
									v{v.version} · {versionLabel[v.status]()} · {fmtDateTime(v.submitted_at, locale)}
									{#if v.review_note}<p class="text-xs text-[var(--muted)]">
											„{v.review_note}“
										</p>{/if}
								</li>
							{/each}
						</ul>
					</Card>
				{/if}
			</div>
		</div>
	{/if}
</div>
