<script lang="ts">
	import { enhance } from '$app/forms';
	import { invalidateAll } from '$app/navigation';
	import { onMount, tick } from 'svelte';
	import type { Message } from '@terra/contracts';
	import { m } from '#lib/paraglide/messages.js';
	import { getLocale, localizeHref } from '#lib/paraglide/runtime.js';
	import { t } from '#lib/catalog.js';
	import { fmtDateTime } from '#lib/labels.js';
	import { connect, type RealtimeEvent } from '#lib/realtime.js';
	import Alert from '#lib/components/Alert.svelte';
	import Button from '#lib/components/Button.svelte';
	import Card from '#lib/components/Card.svelte';
	import type { PageProps } from './$types';

	let { data, form }: PageProps = $props();
	const locale = getLocale();
	const c = $derived(data.detail.conversation);
	const peer = $derived(c.role === 'seeker' ? c.org_name : c.seeker_name);

	// Writable deriveds: reset on navigation, updated by realtime events.
	let messages = $derived<Message[]>(data.messages);
	let peerReadAt = $derived(data.detail.peer_read_at ?? null);
	let live = $state(false);
	let body = $state('');
	let list: HTMLElement | undefined = $state();

	const contactFlags = ['contact_phone', 'contact_email', 'contact_bank_account'];
	const reasons = [
		['scam', m.msg_reason_scam],
		['advance_payment', m.msg_reason_advance_payment],
		['harassment', m.msg_reason_harassment],
		['discrimination', m.msg_reason_discrimination],
		['spam', m.msg_reason_spam],
		['other', m.msg_reason_other]
	] as const;

	const mine = (msg: Message) => msg.sender_id === data.meId;
	const lastMineRead = $derived.by(() => {
		const own = messages.filter(mine);
		const last = own[own.length - 1];
		return last && peerReadAt && last.created_at <= peerReadAt ? last.id : null;
	});

	async function scrollDown() {
		await tick();
		list?.scrollTo({ top: list.scrollHeight });
	}

	function add(msg: Message) {
		if (messages.some((x) => x.id === msg.id)) return;
		messages = [...messages, msg];
		scrollDown();
		if (!mine(msg) && document.visibilityState === 'visible') {
			fetch(`/zpravy/api/${c.id}/read`, { method: 'POST' });
		}
	}

	function onEvent(e: RealtimeEvent) {
		if (e.conversation_id !== c.id) return;
		if (e.type === 'message') add(e.message);
		else if (e.type === 'read' && e.user_id !== data.meId) peerReadAt = e.at;
		else if (e.type === 'blocked' || e.type === 'removed') invalidateAll();
	}

	onMount(() => {
		scrollDown();
		return connect({ conversation: c.id, onEvent, onState: (on) => (live = on) });
	});
</script>

<svelte:head><title>{peer} · {m.msg_inbox_title()} · {m.app_name()}</title></svelte:head>

<div class="grid gap-6 lg:grid-cols-[2fr_1fr]">
	<section
		class="flex min-h-[32rem] flex-col rounded-[var(--radius-card)] border border-[var(--border)] bg-[var(--surface)]"
	>
		<header class="flex flex-wrap items-baseline gap-x-3 border-b border-[var(--border)] p-4">
			<a href={localizeHref('/zpravy')} class="text-sm">← {m.msg_inbox_title()}</a>
			<h1 class="text-lg font-semibold" data-testid="thread-peer">{peer}</h1>
			<a href={localizeHref(`/inzerat/${c.listing_id}`)} class="truncate text-sm"
				>{t(c.listing_title, locale)}</a
			>
			<span
				class="ml-auto text-xs {live ? 'text-emerald-700' : 'text-[var(--muted)]'}"
				data-testid="live">{live ? `● ${m.msg_live()}` : m.msg_offline()}</span
			>
		</header>
		<p class="bg-[var(--border)]/30 px-4 py-2 text-xs text-[var(--muted)]">{m.msg_safety()}</p>

		<ol
			bind:this={list}
			class="flex max-h-[60vh] flex-1 flex-col gap-3 overflow-y-auto p-4"
			data-testid="messages"
			aria-live="polite"
		>
			{#each messages as msg (msg.id)}
				<li
					class="grid max-w-[85%] gap-1 {mine(msg) ? 'justify-items-end self-end' : 'self-start'}"
					data-testid="message"
				>
					<div
						class="rounded-2xl px-4 py-2 whitespace-pre-line {mine(msg)
							? 'bg-[var(--accent)] text-white'
							: 'bg-[var(--border)]/50'}"
					>
						{#if msg.removed}
							<em class="opacity-80">{m.msg_removed()}</em>
						{:else}
							{msg.body}
							{#each msg.attachments as a (a.id)}
								<a
									href={a.url}
									target="_blank"
									rel="noopener"
									class="mt-1 block underline {mine(msg) ? 'text-white' : ''}">📎 {a.filename}</a
								>
							{/each}
						{/if}
					</div>
					{#if !msg.removed && msg.flags.includes('advance_payment')}
						<Alert kind="error">{m.msg_flag_advance()}</Alert>
					{:else if mine(msg) && msg.flags.some((f) => contactFlags.includes(f))}
						<p class="text-xs text-amber-700 dark:text-amber-400">{m.msg_flag_contact()}</p>
					{/if}
					<span class="text-xs text-[var(--muted)]">
						{fmtDateTime(msg.created_at, locale)}
						{#if msg.id === lastMineRead}· <span data-testid="read-receipt">{m.msg_read()}</span
							>{/if}
					</span>
				</li>
			{/each}
		</ol>

		<div class="border-t border-[var(--border)] p-4">
			{#if c.blocked}
				<Alert kind="info">{m.msg_blocked()}</Alert>
			{:else}
				{#if form?.error}<div class="mb-3"><Alert kind="error">{form.error}</Alert></div>{/if}
				<form
					method="POST"
					action="?/send"
					enctype="multipart/form-data"
					class="grid gap-2"
					use:enhance={() =>
						async ({ result, update }) => {
							if (result.type === 'success' && result.data?.sent) {
								add(result.data.sent as Message);
								body = '';
							}
							await update({ reset: result.type === 'success', invalidateAll: false });
						}}
				>
					{#if data.templates.length}
						<select
							aria-label={m.msg_templates()}
							class="justify-self-start rounded-lg border border-[var(--border)] bg-[var(--surface)] px-3 py-1.5 text-sm"
							onchange={(e) => {
								const tpl = data.templates.find((x) => x.id === e.currentTarget.value);
								if (tpl) body = body ? `${body}\n\n${tpl.body}` : tpl.body;
								e.currentTarget.value = '';
							}}
						>
							<option value="">{m.msg_template_insert()}</option>
							{#each data.templates as tpl (tpl.id)}<option value={tpl.id}>{tpl.title}</option
								>{/each}
						</select>
					{/if}
					<label class="grid gap-1 text-sm font-medium">
						<span class="sr-only">{m.msg_body_label()}</span>
						<textarea
							name="body"
							rows="3"
							maxlength="4000"
							bind:value={body}
							placeholder={m.msg_body_label()}
							class="rounded-lg border border-[var(--border)] bg-[var(--surface)] px-3 py-2"
							onkeydown={(e) => {
								if (e.key === 'Enter' && (e.metaKey || e.ctrlKey))
									e.currentTarget.form?.requestSubmit();
							}}></textarea>
					</label>
					<div class="flex flex-wrap items-center gap-3">
						<label class="text-sm text-[var(--muted)]">
							{m.msg_attach()}
							<input
								type="file"
								name="file"
								accept="image/jpeg,image/png,image/webp,image/heic,application/pdf"
								class="block text-sm"
							/>
						</label>
						<div class="ml-auto"><Button type="submit">{m.msg_send()}</Button></div>
					</div>
				</form>
			{/if}
		</div>
	</section>

	<aside class="grid content-start gap-4">
		{#if data.detail.prescreen.length}
			<Card title={c.role === 'owner' ? m.msg_prescreen_answers() : m.msg_prescreen_title()}>
				<dl class="grid gap-2 text-sm" data-testid="prescreen-answers">
					{#each data.detail.prescreen as a (a.id)}
						<div>
							<dt class="text-[var(--muted)]">{a.question[locale as 'cs'] || a.question.cs}</dt>
							<dd>
								{a.kind === 'yes_no' ? (a.answer === 'yes' ? m.msg_yes() : m.msg_no()) : a.answer}
							</dd>
						</div>
					{/each}
				</dl>
			</Card>
		{/if}
		{#if c.role === 'owner'}
			<a href={localizeHref(`/admin/orgs/${c.org_id}/sablony`)} class="text-sm"
				>{m.msg_templates_manage()}</a
			>
		{/if}
		<Card>
			{#if form?.reported}
				<Alert kind="success">{m.msg_report_sent()}</Alert>
			{:else}
				<details>
					<summary class="cursor-pointer text-sm font-medium">{m.msg_report()}</summary>
					{#if form?.reportError}<Alert kind="error">{form.reportError}</Alert>{/if}
					<form method="POST" action="?/report" use:enhance class="mt-3 grid gap-3">
						<label class="grid gap-1 text-sm font-medium"
							>{m.msg_report_reason()}
							<select
								name="reason"
								class="rounded-lg border border-[var(--border)] bg-[var(--surface)] px-3 py-2"
							>
								{#each reasons as [value, label] (value)}<option {value}>{label()}</option>{/each}
							</select>
						</label>
						<label class="grid gap-1 text-sm font-medium"
							>{m.msg_report_note()}
							<textarea
								name="note"
								rows="3"
								maxlength="2000"
								class="rounded-lg border border-[var(--border)] bg-[var(--surface)] px-3 py-2"
							></textarea>
						</label>
						<Button type="submit" variant="danger">{m.msg_report_send()}</Button>
					</form>
				</details>
			{/if}
			{#if !c.blocked || c.blocked_by_me}
				<form method="POST" action="?/block" use:enhance class="mt-4">
					<input type="hidden" name="blocked" value={String(!c.blocked)} />
					<Button type="submit" variant="secondary"
						>{c.blocked ? m.msg_unblock() : m.msg_block()}</Button
					>
				</form>
			{/if}
		</Card>
	</aside>
</div>
