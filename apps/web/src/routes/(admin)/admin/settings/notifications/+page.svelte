<script lang="ts">
	import { enhance } from '$app/forms';
	import { m } from '#lib/paraglide/messages.js';
	import Alert from '#lib/components/Alert.svelte';
	import Button from '#lib/components/Button.svelte';
	import Card from '#lib/components/Card.svelte';
	import type { PageProps } from './$types';

	let { data, form }: PageProps = $props();
	let browserState = $state<'idle' | 'on' | 'denied' | 'unsupported'>('idle');

	function keyBytes(b64: string): Uint8Array<ArrayBuffer> {
		const s = atob(b64.replace(/-/g, '+').replace(/_/g, '/'));
		return Uint8Array.from(s, (c) => c.charCodeAt(0));
	}

	async function enableBrowserPush() {
		if (!('serviceWorker' in navigator) || !('PushManager' in window)) {
			browserState = 'unsupported';
			return;
		}
		if ((await Notification.requestPermission()) !== 'granted') {
			browserState = 'denied';
			return;
		}
		const reg = await navigator.serviceWorker.ready;
		const sub = await reg.pushManager.subscribe({
			userVisibleOnly: true,
			applicationServerKey: keyBytes(data.vapidKey)
		});
		const res = await fetch('/zpravy/api/push', {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify(sub.toJSON())
		});
		browserState = res.ok ? 'on' : 'idle';
	}
	const options = [
		['instant', m.notif_email_instant],
		['daily', m.notif_email_daily],
		['off', m.notif_email_off]
	] as const;
</script>

<Card title={m.settings_notifications()}>
	{#if form?.saved}<div class="mb-3"><Alert kind="success">{m.notif_saved()}</Alert></div>{/if}
	{#if form?.error}<div class="mb-3"><Alert kind="error">{form.error}</Alert></div>{/if}
	<form
		method="POST"
		use:enhance={() =>
			({ update }) =>
				update({ reset: false })}
		class="grid gap-4"
	>
		<fieldset class="grid gap-2 text-sm">
			<legend class="mb-1 font-semibold">{m.notif_email_label()}</legend>
			{#each options as [value, label] (value)}
				<label class="flex items-center gap-2">
					<input
						type="radio"
						name="email_messages"
						{value}
						checked={data.prefs.email_messages === value}
					/>
					{label()}
				</label>
			{/each}
		</fieldset>
		<label class="flex items-center gap-2 text-sm">
			<input type="checkbox" name="push_messages" checked={data.prefs.push_messages} />
			{m.notif_push_label()}
		</label>
		<div><Button type="submit">{m.notif_save()}</Button></div>
	</form>
	<div class="mt-6 grid gap-2 border-t border-[var(--border)] pt-4 text-sm">
		<span class="font-semibold">{m.notif_browser_label()}</span>
		{#if browserState === 'on'}<Alert kind="success">{m.notif_browser_on()}</Alert>
		{:else if browserState === 'denied'}<Alert kind="error">{m.notif_browser_denied()}</Alert>
		{:else if browserState === 'unsupported'}<Alert kind="info"
				>{m.notif_browser_unsupported()}</Alert
			>
		{:else}
			<div>
				<Button type="button" variant="secondary" onclick={enableBrowserPush}
					>{m.notif_browser_enable()}</Button
				>
			</div>
		{/if}
	</div>
</Card>
