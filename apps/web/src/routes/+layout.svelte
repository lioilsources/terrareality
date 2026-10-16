<script lang="ts">
	import { page } from '$app/state';
	import { getLocale, locales, localizeHref } from '#lib/paraglide/runtime.js';
	import { m } from '#lib/paraglide/messages.js';
	import { Logo } from '@terra/ui';
	import CookieBanner from '#lib/components/CookieBanner.svelte';
	import { LEGAL_ROUTES } from '#lib/legal.js';
	import './layout.css';
	import favicon from '#lib/assets/favicon.svg';
	import type { LayoutProps } from './$types';

	let { children, data }: LayoutProps = $props();

	const nav = $derived([
		{ href: '/hledat', label: m.nav_search },
		...(data.me ? [{ href: '/zpravy', label: m.nav_messages }] : []),
		{ href: '/tenant', label: m.nav_tenant },
		{ href: '/admin', label: m.nav_admin },
		...(data.me?.is_staff ? [{ href: '/backoffice', label: m.nav_backoffice }] : [])
	]);

	const legalLinks = [
		{ href: LEGAL_ROUTES.terms, label: m.legal_terms },
		{ href: LEGAL_ROUTES.privacy, label: m.legal_privacy },
		{ href: LEGAL_ROUTES.cookies, label: m.legal_cookies },
		{ href: LEGAL_ROUTES.dsa, label: m.legal_dsa }
	];
</script>

<svelte:head>
	<link rel="icon" href={favicon} />
	<title>{m.app_name()}</title>
</svelte:head>

<div class="min-h-dvh">
	{#if !data.consent.decided}
		<CookieBanner />
	{/if}
	<header class="border-b border-[var(--border)] bg-[var(--surface)]">
		<div class="mx-auto flex max-w-6xl flex-wrap items-center gap-x-6 gap-y-2 px-4 py-3">
			<a href={localizeHref('/')} class="no-underline"><Logo /></a>
			<nav class="flex flex-wrap gap-4 text-sm">
				{#each nav as item (item.href)}
					<a
						href={localizeHref(item.href)}
						class="text-[var(--muted)] hover:text-[var(--text)]"
						aria-current={page.url.pathname.endsWith(item.href) ? 'page' : undefined}
					>
						{item.label()}
						{#if item.href === '/zpravy' && data.unread}<span
								class="ml-1 rounded-full bg-[var(--accent)] px-1.5 text-xs font-semibold text-white"
								data-testid="nav-unread">{data.unread}</span
							>{/if}
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
					<a href={localizeHref('/login')}>{m.nav_login()}</a>
				{/if}
			</div>
			<div class="flex items-center gap-2 text-sm" aria-label={m.language()}>
				{#each locales as locale (locale)}
					<a
						href={localizeHref(page.url.pathname + page.url.search, { locale })}
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
	<footer class="border-t border-[var(--border)]">
		<div
			class="mx-auto flex max-w-6xl flex-wrap items-center gap-x-6 gap-y-2 px-4 py-6 text-sm text-[var(--muted)]"
		>
			<span>{m.legal_footer_copyright({ year: new Date().getFullYear() })}</span>
			<nav aria-label={m.legal_nav()} class="flex flex-wrap gap-4" data-testid="footer-legal">
				{#each legalLinks as item (item.href)}
					<a href={localizeHref(item.href)} class="hover:text-[var(--text)]">{item.label()}</a>
				{/each}
			</nav>
		</div>
	</footer>
</div>
