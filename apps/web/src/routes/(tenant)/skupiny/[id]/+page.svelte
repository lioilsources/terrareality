<script lang="ts">
	import { enhance } from '$app/forms';
	import { onMount } from 'svelte';
	import { m } from '#lib/paraglide/messages.js';
	import { getLocale } from '#lib/paraglide/runtime.js';
	import { fmtDateTime } from '#lib/labels.js';
	import { field, levelLabel } from '#lib/applications.js';
	import { connect } from '#lib/realtime.js';
	import Alert from '#lib/components/Alert.svelte';
	import Button from '#lib/components/Button.svelte';
	import Card from '#lib/components/Card.svelte';
	import type { PageProps } from './$types';

	type Msg = {
		id: string;
		sender_id?: string;
		sender_name: string;
		body: string;
		created_at: string;
	};

	let { data, form }: PageProps = $props();
	const locale = getLocale();
	const g = $derived(data.group);
	let messages = $derived<Msg[]>(data.group.messages);

	function add(msg: Msg) {
		if (!messages.some((x) => x.id === msg.id)) messages = [...messages, msg];
	}

	onMount(() =>
		connect({
			onEvent: (e) => {
				const ev = e as unknown as { type: string; group_id: string; message: Msg };
				if (ev.type === 'group_message' && ev.group_id === g.id) add(ev.message);
			}
		})
	);
</script>

<svelte:head><title>{g.name} · {m.app_name()}</title></svelte:head>
<h1 class="mb-6 text-2xl font-semibold">{g.name}</h1>
{#if form?.error}<div class="mb-4"><Alert kind="error">{form.error}</Alert></div>{/if}
<div class="grid gap-6 lg:grid-cols-[1fr_2fr]">
	<Card title={m.group_members()}>
		<ul class="grid gap-2 text-sm" data-testid="members">
			{#each g.members as mem (mem.id)}
				<li>
					<strong>{mem.display_name || mem.invited_email}</strong>
					<span class="text-[var(--muted)]"
						>· {mem.joined ? levelLabel[mem.verification_level]() : m.group_invited()}</span
					>
				</li>
			{/each}
		</ul>
		{#if g.joined}
			<form method="POST" action="?/invite" use:enhance class="mt-4 flex gap-2">
				<input
					name="email"
					type="email"
					required
					placeholder="email@example.com"
					class="{field} flex-1"
				/>
				<Button type="submit" variant="secondary">{m.group_invite()}</Button>
			</form>
			<form method="POST" action="?/leave" use:enhance class="mt-4">
				<Button type="submit" variant="danger">{m.group_leave()}</Button>
			</form>
		{:else}
			<p class="mt-4 text-sm text-[var(--muted)]">{m.group_join_hint()}</p>
			<form method="POST" action="?/join" use:enhance class="mt-2">
				<Button type="submit">{m.group_join()}</Button>
			</form>
		{/if}
	</Card>
	{#if g.joined}
		<Card title={m.group_chat()}>
			<ol class="mb-4 grid max-h-[50vh] gap-2 overflow-y-auto" data-testid="group-chat">
				{#each messages as msg (msg.id)}
					<li class="rounded-lg bg-[var(--border)]/40 px-3 py-2 text-sm">
						<span class="text-xs text-[var(--muted)]"
							>{msg.sender_name} · {fmtDateTime(msg.created_at, locale)}</span
						>
						<p class="whitespace-pre-line">{msg.body}</p>
					</li>
				{/each}
			</ol>
			<form
				method="POST"
				action="?/send"
				class="flex gap-2"
				use:enhance={() =>
					async ({ result, update }) => {
						if (result.type === 'success' && result.data?.sent) add(result.data.sent as Msg);
						await update({ invalidateAll: false });
					}}
			>
				<input
					name="body"
					required
					maxlength="4000"
					placeholder={m.group_chat_placeholder()}
					class="{field} flex-1"
				/>
				<Button type="submit">{m.msg_send()}</Button>
			</form>
		</Card>
	{/if}
</div>
