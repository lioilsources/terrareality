<script lang="ts">
	import { enhance } from '$app/forms';
	import { page } from '$app/state';
	import { m } from '#lib/paraglide/messages.js';
	import { getLocale, localizeHref } from '#lib/paraglide/runtime.js';
	import { kindLabel, t } from '#lib/catalog.js';
	import Alert from '#lib/components/Alert.svelte';
	import Button from '#lib/components/Button.svelte';
	import Card from '#lib/components/Card.svelte';
	import Field from '#lib/components/Field.svelte';
	import type { PageProps } from './$types';

	let { data, form }: PageProps = $props();
	const locale = getLocale();
	const title = $derived(t(data.listing.title, locale) || kindLabel[data.listing.unit.kind]());
	const back = $derived(localizeHref(`/inzerat/${data.listing.id}`));
	const reasonLabels: Record<string, () => string> = {
		illegal_content: m.dsa_reason_illegal_content,
		fraud: m.dsa_reason_fraud,
		discrimination: m.dsa_reason_discrimination,
		wrong_info: m.dsa_reason_wrong_info,
		other: m.dsa_reason_other
	};
	const values = $derived(form && 'values' in form ? form.values : undefined);
	let sending = $state(false);
</script>

<svelte:head>
	<title>{m.dsa_title()} · {title} · {m.app_name()}</title>
	<meta name="robots" content="noindex" />
</svelte:head>

<div class="mx-auto grid max-w-2xl gap-4">
	<p><a href={back}>← {m.dsa_back()}</a></p>
	{#if form && 'sent' in form && form.sent}
		<Card title={m.dsa_sent_title()} testid="report-sent">
			<div role="status">
				<p>{m.dsa_sent({ id: form.sent })}</p>
			</div>
			<p class="mt-4"><a href={back}>{m.dsa_back()}</a></p>
		</Card>
	{:else}
		<Card title="{m.dsa_title()}: {title}" testid="report-listing">
			<p class="mb-4 text-sm text-[var(--muted)]">{m.dsa_intro()}</p>
			{#if form && 'error' in form && form.error}
				<div class="mb-3" role="alert"><Alert kind="error">{form.error}</Alert></div>
			{/if}
			<form
				method="POST"
				class="grid gap-4"
				data-testid="report-form"
				use:enhance={() => {
					sending = true;
					return async ({ update }) => {
						await update({ reset: false });
						sending = false;
					};
				}}
			>
				<fieldset
					class="grid gap-2 text-sm"
					aria-describedby={form && 'missingReason' in form && form.missingReason
						? 'reason-error'
						: undefined}
				>
					<legend class="mb-1 font-medium">{m.dsa_reason()}</legend>
					{#each data.reasons as r (r)}
						<label class="flex items-center gap-2">
							<input
								type="radio"
								name="reason"
								value={r}
								required
								checked={values?.reason === r}
								data-testid="report-reason-{r}"
							/>
							{reasonLabels[r]()}
						</label>
					{/each}
					{#if form && 'missingReason' in form && form.missingReason}
						<p id="reason-error" class="text-xs text-red-700 dark:text-red-400">
							{m.dsa_reason()}
						</p>
					{/if}
				</fieldset>
				<div class="grid gap-1">
					<label for="report-explanation" class="text-sm font-medium">{m.dsa_explanation()}</label>
					<textarea
						id="report-explanation"
						name="explanation"
						rows="5"
						required
						minlength="20"
						maxlength="2000"
						aria-describedby="report-explanation-hint"
						data-testid="report-explanation"
						class="rounded-lg border border-[var(--border)] bg-[var(--surface)] px-3 py-2"
						>{values?.explanation ?? ''}</textarea
					>
					<p id="report-explanation-hint" class="text-xs text-[var(--muted)]">
						{m.dsa_explanation_hint()}
					</p>
				</div>
				{#if page.data.me}
					<p class="text-sm text-[var(--muted)]">
						{m.dsa_signed_in_as({ email: page.data.me.email })}
					</p>
				{:else}
					<Field
						label={m.dsa_email()}
						name="email"
						type="email"
						autocomplete="email"
						required
						maxlength={254}
						hint={m.dsa_email_hint()}
						value={values?.email ?? ''}
						data-testid="report-email"
					/>
					<Field
						label={m.dsa_name()}
						name="name"
						autocomplete="name"
						maxlength={200}
						value={values?.name ?? ''}
						data-testid="report-name"
					/>
				{/if}
				<p class="text-xs text-[var(--muted)]">{m.dsa_good_faith()}</p>
				<Button type="submit" disabled={sending} data-testid="report-submit"
					>{m.dsa_submit()}</Button
				>
			</form>
		</Card>
	{/if}
</div>
