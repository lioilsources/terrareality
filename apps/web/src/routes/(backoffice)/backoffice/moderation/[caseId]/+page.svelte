<script lang="ts">
	import { enhance } from '$app/forms';
	import { m } from '#lib/paraglide/messages.js';
	import { getLocale } from '#lib/paraglide/runtime.js';
	import { t } from '#lib/catalog.js';
	import { fmtDateTime } from '#lib/labels.js';
	import Alert from '#lib/components/Alert.svelte';
	import Button from '#lib/components/Button.svelte';
	import Card from '#lib/components/Card.svelte';
	import { reasonLabel, verdictLabel, verdicts } from '../labels.js';
	import type { PageProps } from './$types';

	let { data, form }: PageProps = $props();
	const locale = getLocale();
	const c = $derived(data.detail.case);
</script>

<div class="grid gap-6 lg:grid-cols-[2fr_1fr]">
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
	<div class="grid content-start gap-4">
		<Card title={c.source === 'auto' ? m.bo_case_auto() : m.bo_case_report()}>
			<dl class="grid gap-1 text-sm">
				<dt class="text-[var(--muted)]">{m.msg_report_reason()}</dt>
				<dd>
					<strong>{reasonLabel(c.reason)}</strong>{#if c.note}
						· {c.note}{/if}
				</dd>
				{#if c.reporter_email}
					<dt class="text-[var(--muted)]">{m.bo_reporter()}</dt>
					<dd>{c.reporter_name} ({c.reporter_email})</dd>
				{/if}
				{#if c.reported_email}
					<dt class="text-[var(--muted)]">{m.bo_reported()}</dt>
					<dd>{c.reported_name} ({c.reported_email})</dd>
				{/if}
			</dl>
		</Card>
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
		<Card title={m.bo_decision()}>
			{#if form?.error}<div class="mb-3"><Alert kind="error">{form.error}</Alert></div>{/if}
			<form method="POST" use:enhance class="grid gap-3">
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
				<label class="grid gap-1 text-sm font-medium"
					>{m.bo_note()}
					<textarea
						name="note"
						rows="3"
						maxlength="2000"
						class="rounded-lg border border-[var(--border)] bg-[var(--surface)] px-3 py-2"
					></textarea>
				</label>
				<Button type="submit">{m.bo_decide()}</Button>
			</form>
		</Card>
	</div>
</div>
