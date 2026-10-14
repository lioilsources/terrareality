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

	let { children, data }: LayoutProps = $props();

	const nav = $derived([
		{ href: '/', label: m.nav_search },
		{ href: '/admin', label: m.nav_admin },
		{ href: '/tenant', label: m.nav_tenant },
		...(data.me?.is_staff ? [{ href: '/backoffice', label: m.nav_backoffice }] : [])
	]);
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
			<div class="ml-auto flex items-center gap-3 text-sm">
				{#if data.me}
					<span class="text-[var(--muted)]" data-testid="user-menu"
						>{data.me.display_name || data.me.email}</span
					>
					<form method="POST" action={localizeHref('/logout')}>
						<button class="text-[var(--muted)] hover:text-[var(--text)]">{m.nav_logout()}</button>
					</form>
				{:else}
					<a href={resolve(localizeHref('/login') as Path)}>{m.nav_login()}</a>
				{/if}
			</div>
			<div class="flex items-center gap-2 text-sm" aria-label={m.language()}>
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
	{#if data.me?.impersonator}
		<div class="bg-amber-400 text-amber-950" role="status">
			<div
				class="mx-auto flex max-w-6xl flex-wrap items-center justify-between gap-2 px-4 py-2 text-sm"
			>
				<span data-testid="impersonation-banner"
					>{m.impersonation_banner({
						user: data.me.email,
						staff: data.me.impersonator.email
					})}</span
				>
				<form method="POST" action={localizeHref('/impersonation/end')}>
					<button class="font-semibold underline">{m.impersonation_end()}</button>
				</form>
			</div>
		</div>
	{/if}
	<main class="mx-auto max-w-6xl px-4 py-8">
		{@render children()}
	</main>
</div>
