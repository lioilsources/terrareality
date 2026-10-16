<script lang="ts">
	import { enhance } from '$app/forms';
	import { invalidateAll } from '$app/navigation';
	import { m } from '#lib/paraglide/messages.js';
	import { signLevelHint, signLevelLabel, type SignProvider } from '#lib/leasing.js';
	import Button from '#lib/components/Button.svelte';

	/** The methods enabled on the server (LeaseDetail.sign_providers), in order of preference. */
	let { providers }: { providers: SignProvider[] } = $props();
	const single = $derived(providers.length === 1 ? providers[0] : null);

	// A failed signature (document_changed: a new version was proposed meanwhile) reloads
	// the lease, so the user sees and signs the current document.
	const reloadOnFailure =
		() =>
		async ({ result, update }: { result: { type: string }; update: () => Promise<void> }) => {
			await update();
			if (result.type === 'failure') await invalidateAll();
		};
</script>

<!-- Signing is a legal act: the method is named and the user confirms explicitly. -->
{#if providers.length === 0}
	<p class="text-sm text-[var(--muted)]" data-testid="lease-sign-unavailable">
		{m.lease_sign_unavailable()}
	</p>
{:else}
	<form
		method="POST"
		action="?/sign"
		use:enhance={reloadOnFailure}
		class="grid gap-2"
		data-testid="lease-sign"
	>
		{#if single}
			<input type="hidden" name="provider" value={single.id} />
			<p class="text-sm">
				{m.lease_sign_method()}:
				<strong data-testid="sign-method">{signLevelLabel[single.level]()}</strong>
			</p>
			<p class="text-xs text-[var(--muted)]">{signLevelHint[single.level]()}</p>
			<label class="flex items-start gap-2 text-sm">
				<input type="checkbox" name="confirm" required class="mt-0.5" />
				<span>{m.lease_sign_confirm({ method: signLevelLabel[single.level]() })}</span>
			</label>
		{:else}
			<fieldset class="grid gap-2" data-testid="sign-methods">
				<legend class="mb-1 text-sm font-medium">{m.lease_sign_choose()}</legend>
				{#each providers as p, i (p.id)}
					<label class="flex items-start gap-2 text-sm">
						<input
							type="radio"
							name="provider"
							value={p.id}
							checked={i === 0}
							required
							class="mt-0.5"
						/>
						<span>
							<strong>{signLevelLabel[p.level]()}</strong>
							<span class="block text-xs text-[var(--muted)]">{signLevelHint[p.level]()}</span>
						</span>
					</label>
				{/each}
			</fieldset>
			<label class="flex items-start gap-2 text-sm">
				<input type="checkbox" name="confirm" required class="mt-0.5" />
				<span>{m.lease_sign_confirm_chosen()}</span>
			</label>
		{/if}
		<Button type="submit">{m.lease_sign()}</Button>
	</form>
{/if}
