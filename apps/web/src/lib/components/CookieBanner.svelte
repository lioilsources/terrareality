<script lang="ts">
	import { applyAction, enhance, type SubmitFunction } from '$app/forms';
	import { invalidateAll } from '$app/navigation';
	import { page } from '$app/state';
	import { m } from '#lib/paraglide/messages.js';
	import { localizeHref } from '#lib/paraglide/runtime.js';
	import { OPTIONAL_CATEGORIES } from '#lib/consent.js';

	// Rendered in the page flow above the header (never covers content) and
	// without inline scripts or styles: works without JS (form POST + redirect)
	// and is enhanced when JS is available (CSP friendly). It does not steal
	// focus; it is the first landmark, reachable with Tab before the header.
	const next = $derived(page.url.pathname + page.url.search);
	let pending = $state(false);

	const submit: SubmitFunction = () => {
		pending = true;
		return async ({ result }) => {
			pending = false;
			if (result.type === 'redirect') await invalidateAll();
			else await applyAction(result);
		};
	};
</script>

<div
	role="region"
	aria-labelledby="cookie-banner-title"
	class="border-b border-[var(--border)] bg-[var(--surface)]"
	data-testid="cookie-banner"
>
	<form
		method="POST"
		action={localizeHref('/cookies') + '?/consent'}
		use:enhance={submit}
		class="mx-auto flex max-w-6xl flex-wrap items-center gap-x-6 gap-y-3 px-4 py-4 text-sm"
	>
		<input type="hidden" name="next" value={next} />
		<div class="min-w-0 flex-1 basis-80">
			<h2 id="cookie-banner-title" class="font-semibold">{m.cookie_banner_title()}</h2>
			<p class="mt-1 text-[var(--muted)]">
				{OPTIONAL_CATEGORIES.length ? m.cookie_banner_text_optional() : m.cookie_banner_text()}
				<a href={localizeHref('/cookies')} class="underline">{m.cookie_banner_more()}</a>
			</p>
		</div>
		<div class="flex flex-wrap gap-2">
			{#if OPTIONAL_CATEGORIES.length}
				<button
					name="all"
					value="1"
					disabled={pending}
					class="rounded-lg bg-[var(--accent)] px-4 py-2 font-medium text-white focus-visible:outline-2 focus-visible:outline-offset-2"
					>{m.cookie_accept_all()}</button
				>
				<button
					disabled={pending}
					class="rounded-lg border border-[var(--border)] px-4 py-2 font-medium focus-visible:outline-2 focus-visible:outline-offset-2"
					>{m.cookie_necessary_only()}</button
				>
			{:else}
				<button
					disabled={pending}
					class="rounded-lg bg-[var(--accent)] px-4 py-2 font-medium text-white focus-visible:outline-2 focus-visible:outline-offset-2"
					data-testid="cookie-dismiss">{m.cookie_banner_ok()}</button
				>
			{/if}
		</div>
	</form>
</div>
