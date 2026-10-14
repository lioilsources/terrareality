<script lang="ts">
	import { enhance } from '$app/forms';
	import { m } from '#lib/paraglide/messages.js';
	import { getLocale, localizeHref } from '#lib/paraglide/runtime.js';
	import { formatMoney, t } from '#lib/catalog.js';
	import { fmtDate, fmtDateTime } from '#lib/labels.js';
	import {
		field,
		isirLabel,
		levelLabel,
		lifestyleLabel,
		reasonLabel,
		rejectReasons,
		statusLabel
	} from '#lib/applications.js';
	import Alert from '#lib/components/Alert.svelte';
	import Button from '#lib/components/Button.svelte';
	import Card from '#lib/components/Card.svelte';
	import type { PageProps } from './$types';

	let { data, form }: PageProps = $props();
	const locale = getLocale();
	const l = $derived(data.listing);
	const open = (s: string) => s === 'submitted' || s === 'invited';
</script>

<svelte:head><title>{m.own_applicants()} · {m.app_name()}</title></svelte:head>
<p class="mb-2 text-sm">
	<a href={localizeHref(`/admin/orgs/${l.org_id}/listings/${l.id}`)}>← {t(l.title, locale)}</a>
</p>
<h1 class="mb-2 text-2xl font-semibold">{m.own_applicants()}</h1>
<p class="mb-6 text-sm text-[var(--muted)]">{m.own_protected_note()}</p>
{#if form?.error}<div class="mb-4"><Alert kind="error">{form.error}</Alert></div>{/if}

<div class="grid gap-6 lg:grid-cols-[2fr_1fr]">
	<div class="grid content-start gap-4" data-testid="applicants">
		{#if data.applicants.length === 0}
			<Card><p class="text-sm text-[var(--muted)]">{m.own_applicants_empty()}</p></Card>
		{/if}
		{#each data.applicants as a (a.application.id)}
			{@const app = a.application}
			<section
				class="rounded-[var(--radius-card)] border border-[var(--border)] bg-[var(--surface)] p-5"
				data-testid="applicant"
			>
				<header class="flex flex-wrap items-baseline gap-x-3 gap-y-1">
					<h2 class="text-lg font-semibold">{app.group_name ?? a.applicant_name}</h2>
					<span class="text-sm text-[var(--muted)]"
						>{m.own_household({ count: String(app.household_size) })}</span
					>
					<span
						class="ml-auto rounded bg-[var(--border)]/60 px-2 py-0.5 text-sm"
						data-testid="app-status"
						>{statusLabel[app.status]()}{#if app.reject_reason}
							· {reasonLabel[app.reject_reason]()}{/if}</span
					>
				</header>
				<p class="mt-1 text-sm text-[var(--muted)]">
					{#if app.preferred_from}{m.app_preferred_from()}: {fmtDate(app.preferred_from, locale)} ·
					{/if}
					{#if app.duration_months}{m.app_duration()}: {app.duration_months}{/if}
				</p>
				<ul class="mt-3 grid gap-1 text-sm">
					{#each a.people as pp (pp.user_id)}
						<li>
							<strong>{pp.display_name}</strong> · {levelLabel[pp.verification_level]()} ·
							{m.pass_isir()}: {isirLabel[pp.insolvency]()}
							{#if pp.income_proof_url}·
								<a href={pp.income_proof_url} target="_blank" rel="noopener"
									>{m.own_income_proof()}</a
								>{/if}
						</li>
					{/each}
				</ul>
				{#if app.message}<p class="mt-3 text-sm whitespace-pre-line">{app.message}</p>{/if}
				{#if a.prescreen?.length}
					<dl class="mt-3 grid gap-1 text-sm">
						{#each a.prescreen as q (q.id)}
							<div>
								<dt class="inline text-[var(--muted)]">{q.question.cs}:</dt>
								<dd class="inline">
									{q.kind === 'yes_no' ? (q.answer === 'yes' ? m.msg_yes() : m.msg_no()) : q.answer}
								</dd>
							</div>
						{/each}
					</dl>
				{/if}
				<div class="mt-3 rounded-lg bg-[var(--border)]/30 p-3 text-sm" data-testid="ai-summary">
					<p class="font-semibold">{m.own_ai_summary()}</p>
					{#if a.ai_summary}
						<p class="mt-1">{a.ai_summary.summary}</p>
						{#if a.ai_summary.strengths.length}
							<p class="mt-1">
								<span class="text-[var(--muted)]">{m.own_strengths()}:</span>
								{a.ai_summary.strengths.join(' ')}
							</p>
						{/if}
						{#if a.ai_summary.gaps.length}
							<p class="mt-1">
								<span class="text-[var(--muted)]">{m.own_gaps()}:</span>
								{a.ai_summary.gaps.join(' ')}
							</p>
						{/if}
					{:else}
						<p class="mt-1 text-[var(--muted)]">{m.own_ai_pending()}</p>
					{/if}
				</div>
				{#if open(app.status)}
					<div class="mt-4 flex flex-wrap items-end gap-2">
						<form method="POST" action="?/decide" use:enhance>
							<input type="hidden" name="application_id" value={app.id} />
							{#if app.status === 'submitted'}
								<Button type="submit" name="action" value="invite" variant="secondary"
									>{m.own_invite()}</Button
								>
							{/if}
							<Button type="submit" name="action" value="accept" title={m.own_accept_hint()}
								>{m.own_accept()}</Button
							>
						</form>
						<form method="POST" action="?/decide" use:enhance class="flex items-end gap-2">
							<input type="hidden" name="application_id" value={app.id} />
							<input type="hidden" name="action" value="reject" />
							<select
								name="reason"
								required
								aria-label={m.app_reason()}
								class="{field} py-1.5 text-sm"
							>
								<option value="">{m.app_reason()}…</option>
								{#each rejectReasons as r (r)}<option value={r}>{reasonLabel[r]()}</option>{/each}
							</select>
							<Button type="submit" variant="danger">{m.own_reject()}</Button>
						</form>
					</div>
				{/if}
			</section>
		{/each}
	</div>

	<div class="grid content-start gap-4">
		<Card title={m.own_slots()} testid="owner-slots">
			<ul class="mb-4 grid gap-2 text-sm">
				{#each data.slots as s (s.id)}
					<li class="rounded-lg border border-[var(--border)] px-3 py-2">
						<div class="flex items-center gap-2">
							<span>{fmtDateTime(s.starts_at, locale)} · {s.booked}/{s.capacity}</span>
							<form method="POST" action="?/deleteSlot" use:enhance class="ml-auto">
								<input type="hidden" name="slot_id" value={s.id} />
								<button class="text-xs text-red-700 underline">{m.own_slot_delete()}</button>
							</form>
						</div>
						{#each s.bookings as b (b.id)}
							<p class="text-[var(--muted)]">✓ {b.applicant_name} ({b.household_size})</p>
						{/each}
					</li>
				{/each}
			</ul>
			<form method="POST" action="?/slot" use:enhance class="grid gap-2">
				<label class="grid gap-1 text-sm"
					>{m.own_slot_when()}<input
						type="datetime-local"
						name="starts_at"
						required
						class={field}
					/></label
				>
				<div class="grid grid-cols-2 gap-2">
					<label class="grid gap-1 text-sm"
						>{m.own_slot_duration()}<input
							type="number"
							name="duration_min"
							value="20"
							min="5"
							max="240"
							class={field}
						/></label
					>
					<label class="grid gap-1 text-sm"
						>{m.own_slot_capacity()}<input
							type="number"
							name="capacity"
							value="1"
							min="1"
							max="50"
							class={field}
						/></label
					>
				</div>
				<label class="grid gap-1 text-sm"
					>{m.own_slot_note()}<input name="note" maxlength="500" class={field} /></label
				>
				<Button type="submit" variant="secondary">{m.own_slot_add()}</Button>
			</form>
		</Card>
		{#if data.roommates.length}
			<Card title={m.own_roommates()}>
				<ul class="grid gap-2 text-sm">
					{#each data.roommates as r (r.user_id)}
						<li>
							<strong>{r.display_name}</strong> · {m.rm_score({ score: String(r.score) })} · ≤
							{formatMoney(r.profile.budget_max, locale)} Kč
							<br /><span class="text-[var(--muted)]"
								>{r.profile.lifestyle.map((x) => lifestyleLabel[x]?.() ?? x).join(' · ')}</span
							>
						</li>
					{/each}
				</ul>
			</Card>
		{/if}
	</div>
</div>
