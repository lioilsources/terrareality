<script lang="ts">
	import { enhance } from '$app/forms';
	import { m } from '#lib/paraglide/messages.js';
	import { localizeHref } from '#lib/paraglide/runtime.js';
	import { OPTIONAL_CATEGORIES } from '#lib/consent.js';
	import LegalPage from '#lib/components/legal/LegalPage.svelte';
	import type { PageProps } from './$types';

	let { data }: PageProps = $props();

	const labels = { analytics: [m.cookie_category_analytics, m.cookie_category_analytics_hint] };
</script>

<LegalPage page={data.doc}>
	<form
		method="POST"
		action={localizeHref('/cookies') + '?/consent'}
		use:enhance
		class="mt-6 rounded-[var(--radius-card)] border border-[var(--border)] bg-[var(--surface)] p-4"
		data-testid="cookie-settings"
	>
		<input type="hidden" name="next" value={localizeHref('/cookies')} />
		<fieldset class="grid gap-3">
			<legend class="font-semibold">{m.cookie_settings_title()}</legend>
			<label class="flex items-start gap-3">
				<input type="checkbox" checked disabled class="mt-1" />
				<span>
					<span class="font-medium">{m.cookie_category_necessary()}</span>
					<span class="block text-sm text-[var(--muted)]">{m.cookie_category_necessary_hint()}</span
					>
				</span>
			</label>
			{#each OPTIONAL_CATEGORIES as c (c)}
				<label class="flex items-start gap-3">
					<input
						type="checkbox"
						name="category"
						value={c}
						checked={data.consent.categories.includes(c)}
						class="mt-1"
					/>
					<span>
						<span class="font-medium">{labels[c][0]()}</span>
						<span class="block text-sm text-[var(--muted)]">{labels[c][1]()}</span>
					</span>
				</label>
			{/each}
		</fieldset>
		<div class="mt-4 flex flex-wrap items-center gap-3">
			<button class="rounded-lg bg-[var(--accent)] px-4 py-2 text-sm font-medium text-white"
				>{m.cookie_save()}</button
			>
			{#if data.consent.decided}
				<span class="text-sm text-[var(--muted)]" data-testid="cookie-saved" role="status"
					>{m.cookie_saved()}</span
				>
			{/if}
		</div>
	</form>
</LegalPage>
