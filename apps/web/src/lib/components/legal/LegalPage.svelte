<script lang="ts">
	import { m } from '#lib/paraglide/messages.js';
	import { localizeHref } from '#lib/paraglide/runtime.js';
	import { LEGAL_DOCS, LEGAL_ROUTES, type LegalPage } from '#lib/legal.js';
	import type { Snippet } from 'svelte';

	let { page, children }: { page: LegalPage; children?: Snippet } = $props();

	const titles = {
		terms: m.legal_terms,
		privacy: m.legal_privacy,
		cookies: m.legal_cookies,
		dsa: m.legal_dsa
	};
</script>

<svelte:head>
	<title>{page.title} | {m.app_name()}</title>
	<meta name="description" content={page.title} />
</svelte:head>

<div class="grid gap-8 lg:grid-cols-[14rem_1fr]">
	<nav aria-label={m.legal_nav()} class="text-sm">
		<ul class="grid gap-2">
			{#each LEGAL_DOCS as doc (doc)}
				<li>
					<a
						href={localizeHref(LEGAL_ROUTES[doc])}
						aria-current={doc === page.doc ? 'page' : undefined}
						class={doc === page.doc
							? 'font-semibold text-[var(--text)]'
							: 'text-[var(--muted)] hover:text-[var(--text)]'}>{titles[doc]()}</a
					>
				</li>
			{/each}
		</ul>
	</nav>
	<article class="legal max-w-3xl" data-testid="legal-{page.doc}">
		<h1 class="text-3xl font-semibold tracking-tight">{page.title}</h1>
		<p class="mt-2 text-sm text-[var(--muted)]">
			{m.legal_version({ version: page.version })}
			{#if page.draft}
				<span
					class="ml-2 rounded bg-amber-200 px-2 py-0.5 text-xs font-semibold text-amber-950"
					data-testid="legal-draft">{m.legal_draft()}</span
				>
			{/if}
		</p>
		{@render children?.()}
		<!-- Escaped by renderLegalMarkdown; the source is our own repository. -->
		<!-- eslint-disable-next-line svelte/no-at-html-tags -->
		<div class="mt-6">{@html page.html}</div>
	</article>
</div>

<style>
	.legal :global(h2) {
		margin-top: 2rem;
		font-size: 1.25rem;
		font-weight: 600;
	}
	.legal :global(h3) {
		margin-top: 1.5rem;
		font-weight: 600;
	}
	.legal :global(p),
	.legal :global(ul),
	.legal :global(ol) {
		margin-top: 0.75rem;
		line-height: 1.65;
	}
	.legal :global(ul) {
		list-style: disc;
		padding-left: 1.5rem;
	}
	.legal :global(ol) {
		list-style: decimal;
		padding-left: 1.5rem;
	}
	.legal :global(li + li) {
		margin-top: 0.35rem;
	}
	.legal :global(a) {
		text-decoration: underline;
	}
	.legal :global(.legal-note) {
		margin-top: 1rem;
		border-left: 4px solid #f59e0b;
		background: var(--surface);
		padding: 0.75rem 1rem;
	}
	.legal :global(.legal-table) {
		margin-top: 1rem;
		overflow-x: auto;
	}
	.legal :global(table) {
		width: 100%;
		border-collapse: collapse;
		font-size: 0.875rem;
	}
	.legal :global(th),
	.legal :global(td) {
		border: 1px solid var(--border);
		padding: 0.4rem 0.6rem;
		text-align: left;
		vertical-align: top;
	}
</style>
