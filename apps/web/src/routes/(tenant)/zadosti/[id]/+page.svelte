<script lang="ts">
	import { enhance } from '$app/forms';
	import { m } from '#lib/paraglide/messages.js';
	import { getLocale, localizeHref } from '#lib/paraglide/runtime.js';
	import { t } from '#lib/catalog.js';
	import { fmtDateTime } from '#lib/labels.js';
	import { reasonLabel, statusLabel } from '#lib/applications.js';
	import Alert from '#lib/components/Alert.svelte';
	import Button from '#lib/components/Button.svelte';
	import Card from '#lib/components/Card.svelte';
	import type { PageProps } from './$types';

	let { data, form }: PageProps = $props();
	const locale = getLocale();
	const a = $derived(data.detail.application);
	const open = $derived(['pending_consent', 'submitted', 'invited'].includes(a.status));
</script>

<svelte:head><title>{t(a.listing_title, locale)} · {m.app_name()}</title></svelte:head>

<div class="grid gap-6 lg:grid-cols-[2fr_1fr]">
	<div class="grid content-start gap-6">
		<Card>
			<p class="text-sm"><a href={localizeHref('/zadosti')}>← {m.app_mine()}</a></p>
			<h1 class="mt-2 text-xl font-semibold">
				<a href={localizeHref(`/inzerat/${a.listing_id}`)}>{t(a.listing_title, locale)}</a>
			</h1>
			<p class="mt-2">
				<span class="rounded bg-[var(--border)]/60 px-2 py-0.5" data-testid="app-status"
					>{statusLabel[a.status]()}</span
				>
				{#if a.reject_reason}· {m.app_reason()}: {reasonLabel[a.reject_reason]()}{/if}
			</p>
			{#if a.group_name}<p class="mt-2 text-sm text-[var(--muted)]">{a.group_name}</p>{/if}
			{#if a.message}<p class="mt-3 text-sm whitespace-pre-line">{a.message}</p>{/if}
			{#if form?.error}<div class="mt-3"><Alert kind="error">{form.error}</Alert></div>{/if}
		</Card>

		{#if a.status === 'submitted' || a.status === 'invited'}
			<Card title={m.app_slots()} testid="slots">
				{#if data.detail.booking}
					<div class="mb-4 flex flex-wrap items-center gap-3">
						<span data-testid="booking"
							>{m.app_booking()}:
							<strong>{fmtDateTime(data.detail.booking.starts_at, locale)}</strong></span
						>
						<form method="POST" action="?/cancel" use:enhance>
							<input type="hidden" name="booking_id" value={data.detail.booking.id} />
							<Button type="submit" variant="secondary">{m.app_booking_cancel()}</Button>
						</form>
					</div>
				{/if}
				{#if data.detail.slots.length === 0}
					<p class="text-sm text-[var(--muted)]">{m.app_slots_empty()}</p>
				{/if}
				<ul class="grid gap-2">
					{#each data.detail.slots as s (s.id)}
						{@const free = s.capacity - s.booked}
						<li
							class="flex flex-wrap items-center gap-3 rounded-lg border border-[var(--border)] px-3 py-2"
						>
							<span>{fmtDateTime(s.starts_at, locale)} · {s.duration_min} min</span>
							{#if s.note}<span class="text-sm text-[var(--muted)]">{s.note}</span>{/if}
							<span class="ml-auto text-sm text-[var(--muted)]"
								>{free > 0 ? m.app_slot_free({ count: String(free) }) : m.app_slot_full()}</span
							>
							{#if free > 0}
								<form method="POST" action="?/book" use:enhance>
									<input type="hidden" name="slot_id" value={s.id} />
									<Button type="submit">{m.app_slot_book()}</Button>
								</form>
							{/if}
						</li>
					{/each}
				</ul>
			</Card>
		{/if}
	</div>

	<div class="grid content-start gap-4">
		{#if data.detail.consents.length}
			<Card title={m.app_consents()}>
				<ul class="grid gap-1 text-sm" data-testid="consents">
					{#each data.detail.consents as c (c.user_id)}
						<li>
							{c.display_name} · {c.consented_at
								? `✓ ${m.app_consent_given()}`
								: m.app_consent_waiting()}
						</li>
					{/each}
				</ul>
				{#if a.status === 'pending_consent' && a.consent_needed && !a.my_consent_at}
					<form method="POST" action="?/consent" use:enhance class="mt-4">
						<Button type="submit">{m.app_consent()}</Button>
					</form>
				{/if}
			</Card>
		{/if}
		{#if open}
			<form method="POST" action="?/withdraw" use:enhance>
				<Button type="submit" variant="danger">{m.app_withdraw()}</Button>
			</form>
		{/if}
	</div>
</div>
