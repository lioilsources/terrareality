<script lang="ts">
	import { enhance } from '$app/forms';
	import { m } from '#lib/paraglide/messages.js';
	import { SIGN_PROVIDER, signMethodLabel, type SignProvider } from '#lib/leasing.js';
	import Button from '#lib/components/Button.svelte';

	let { provider = SIGN_PROVIDER }: { provider?: SignProvider } = $props();
</script>

<!-- Signing is a legal act: the method is named and the user confirms explicitly. -->
<form method="POST" action="?/sign" use:enhance class="grid gap-2" data-testid="lease-sign">
	<p class="text-sm">
		{m.lease_sign_method()}:
		<strong data-testid="sign-method">{signMethodLabel[provider]()}</strong>
	</p>
	{#if provider === 'mock'}
		<p class="text-xs text-[var(--muted)]">{m.lease_sign_method_simple_hint()}</p>
	{/if}
	<label class="flex items-start gap-2 text-sm">
		<input type="checkbox" name="confirm" required class="mt-0.5" />
		<span>{m.lease_sign_confirm({ method: signMethodLabel[provider]() })}</span>
	</label>
	<Button type="submit">{m.lease_sign()}</Button>
</form>
