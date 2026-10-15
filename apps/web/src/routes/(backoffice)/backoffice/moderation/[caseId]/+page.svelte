<script lang="ts">
	import { enhance } from '$app/forms';
	import { m } from '#lib/paraglide/messages.js';
	import { getLocale, localizeHref } from '#lib/paraglide/runtime.js';
	import { t } from '#lib/catalog.js';
	import { fmtDateTime } from '#lib/labels.js';
	import Alert from '#lib/components/Alert.svelte';
	import Button from '#lib/components/Button.svelte';
	import Card from '#lib/components/Card.svelte';
	import { listingVerdicts, reasonLabel, verdictLabel, verdicts } from '../labels.js';
	import type { PageProps } from './$types';

	let { data, form }: PageProps = $props();
	const locale = getLocale();
	const c = $derived(data.detail.case);
	const isListing = $derived(c.kind === 'listing');
</script>

<div class="grid gap-6 lg:grid-cols-[2fr_1fr]">
	{#if isListing}
		<Card title="{m.bo_case_listing()} · {t(c.listing_title, locale)}" testid="listing-report">
			<p class="text-sm">
				<strong>{reasonLabel(c.reason)}</strong> · {fmtDateTime(c.created_at, locale)}
			</p>
			{#if c.note}<p class="mt-2 whitespace-pre-line" data-testid="report-explanation">
					{c.note}
				</p>{/if}
			{#if c.listing_id}
				<p class="mt-4 text-sm">
					<a href={localizeHref(`/inzerat/${c.listing_id}`)} target="_blank" rel="noopener"
						>{m.bo_open_listing()}</a
					>
				</p>
			{/if}
		</Card>
	{:else}
		<Card title="{m.bo_transcript()} · {t(c.listing_title, locale)}">
			<ol class="grid gap-3" data-testid="transcript">
				{#each data.detail.transcript as msg (msg.id)}
					<li
						class="rounded-lg border p-3 text-sm {msg.id === c.message_id
							? 'border-red-400 bg-red-50 dark:bg-red-950'
							: 'border-[var(--border)]'}"
					>
						<p class="mb-1 text-xs text-[var(--muted)]">
							<strong>{msg.sender_name}</strong> ·
							{msg.role === 'seeker' ? m.msg_role_seeker() : m.msg_role_owner()} ·
							{fmtDateTime(msg.created_at, locale)}
							{#if msg.flags.length}· {msg.flags.join(', ')}{/if}
						</p>
						<p class="whitespace-pre-line">{msg.removed ? m.msg_removed() : msg.body}</p>
					</li>
				{/each}
			</ol>
		</Card>
	{/if}
	<div class="grid content-start gap-4">
		<Card
			title={isListing
				? m.bo_case_listing()
				: c.source === 'auto'
					? m.bo_case_auto()
					: m.bo_case_report()}
		>
			<dl class="grid gap-1 text-sm">
				<dt class="text-[var(--muted)]">{m.msg_report_reason()}</dt>
				<dd>
					<strong>{reasonLabel(c.reason)}</strong>{#if c.note}
						· {c.note}{/if}
				</dd>
				{#if c.reporter_email}
					<dt class="text-[var(--muted)]">{m.bo_reporter()}</dt>
					<dd data-testid="case-reporter">
						{c.reporter_name ?? ''} ({c.reporter_email}){#if c.reporter_anonymous}
							· {m.bo_reporter_anonymous()}{/if}
					</dd>
				{/if}
				{#if c.reported_email}
					<dt class="text-[var(--muted)]">{m.bo_reported()}</dt>
					<dd>{c.reported_name} ({c.reported_email})</dd>
				{/if}
			</dl>
		</Card>
		{#if !isListing}
			<Card title={m.bo_ai_suggestion()} testid="ai-suggestion">
				{#if c.ai_status === 'ready' && c.ai_suggestion}
					<p class="text-lg font-semibold" data-testid="ai-verdict">
						{verdictLabel(c.ai_suggestion.verdict)}
					</p>
					<p class="text-sm text-[var(--muted)]">
						{m.bo_confidence({ pct: String(Math.round(c.ai_suggestion.confidence * 100)) })}
						{#if c.ai_suggestion.model}· {c.ai_suggestion.model}{/if}
					</p>
					<p class="mt-2 text-sm">{c.ai_suggestion.reason}</p>
					<p class="mt-2 text-xs text-[var(--muted)]">{m.bo_ai_hint()}</p>
				{:else if c.ai_status === 'pending'}
					<p class="text-sm">{m.bo_ai_pending()}</p>
				{:else if c.ai_status === 'failed'}
					<p class="text-sm">{m.bo_ai_failed()}</p>
				{:else}
					<p class="text-sm">{m.bo_ai_disabled()}</p>
				{/if}
			</Card>
		{/if}
		<Card title={m.bo_decision()} testid="decision">
			{#if form?.error}<div class="mb-3"><Alert kind="error">{form.error}</Alert></div>{/if}
			<form method="POST" use:enhance class="grid gap-3">
				{#if isListing}
					<p class="text-xs text-[var(--muted)]">{m.bo_dsa_hint()}</p>
					<fieldset class="grid gap-2 text-sm">
						<legend class="sr-only">{m.bo_decision()}</legend>
						{#each listingVerdicts as v (v)}
							<label class="flex items-center gap-2">
								<input type="radio" name="decision" value={v} required data-testid="decision-{v}" />
								{verdictLabel(v)}
							</label>
						{/each}
					</fieldset>
				{:else}
					<fieldset class="grid gap-2 text-sm">
						{#each verdicts as v (v)}
							{#if (v !== 'remove_message' || c.message_id) && (v === 'dismiss' || v === 'remove_message' || c.reported_id)}
								<label class="flex items-center gap-2">
									<input
										type="radio"
										name="decision"
										value={v}
										required
										checked={c.ai_suggestion?.verdict === v}
									/>
									{verdictLabel(v)}
								</label>
							{/if}
						{/each}
					</fieldset>
				{/if}
				<label class="grid gap-1 text-sm font-medium"
					>{isListing ? m.bo_dsa_reasons() : m.bo_note()}
					<textarea
						name="note"
						data-testid="decision-note"
						rows="3"
						maxlength="2000"
						class="rounded-lg border border-[var(--border)] bg-[var(--surface)] px-3 py-2"
					></textarea>
				</label>
				<Button type="submit" data-testid="decision-submit">{m.bo_decide()}</Button>
			</form>
		</Card>
	</div>
</div>
