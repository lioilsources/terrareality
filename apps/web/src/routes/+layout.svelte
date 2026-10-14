<script lang="ts">
	import type { Path } from '$app/types';
	import { resolve } from '$app/paths';
	import { page } from '$app/state';
	import { getLocale, locales, localizeHref } from '#lib/paraglide/runtime.js';
	import { m } from '#lib/paraglide/messages.js';
	import { Logo } from '@terra/ui';
	import './layout.css';
	import favicon from '#lib/assets/favicon.svg';
	import type { LayoutProps } from './$types';

	let { children }: LayoutProps = $props();

	const nav = [
		{ href: '/', label: m.nav_search },
		{ href: '/admin', label: m.nav_admin },
		{ href: '/tenant', label: m.nav_tenant },
		{ href: '/backoffice', label: m.nav_backoffice }
	] as const;
</script>

<svelte:head>
	<link rel="icon" href={favicon} />
	<title>{m.app_name()}</title>
</svelte:head>

<div class="min-h-dvh">
	<header class="border-b border-[var(--border)] bg-[var(--surface)]">
		<div class="mx-auto flex max-w-6xl flex-wrap items-center gap-x-6 gap-y-2 px-4 py-3">
			<a href={resolve(localizeHref('/') as Path)} class="no-underline"><Logo /></a>
			<nav class="flex flex-wrap gap-4 text-sm">
				{#each nav as item (item.href)}
					<a
						href={resolve(localizeHref(item.href) as Path)}
						class="text-[var(--muted)] hover:text-[var(--text)]"
						aria-current={page.url.pathname.endsWith(item.href) ? 'page' : undefined}
					>
						{item.label()}
					</a>
				{/each}
			</nav>
			<div class="ml-auto flex items-center gap-2 text-sm" aria-label={m.language()}>
				{#each locales as locale (locale)}
					<a
						href={resolve(localizeHref(page.url.pathname, { locale }) as Path)}
						data-sveltekit-reload
						class="rounded px-2 py-1 uppercase {locale === getLocale()
							? 'bg-[var(--accent)] text-white'
							: 'text-[var(--muted)]'}">{locale}</a
					>
				{/each}
			</div>
		</div>
	</header>
	<main class="mx-auto max-w-6xl px-4 py-8">
		{@render children()}
	</main>
</div>
