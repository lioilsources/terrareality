<script lang="ts">
	import { page } from '$app/state';
	import { m } from '#lib/paraglide/messages.js';
	import { localizeHref } from '#lib/paraglide/runtime.js';
	import type { LayoutProps } from './$types';

	let { children }: LayoutProps = $props();
	const tabs = [
		{ href: '/admin', label: m.dashboard_title },
		{ href: '/admin/settings/profile', label: m.settings_profile },
		{ href: '/admin/settings/security', label: m.settings_security },
		{ href: '/admin/settings/privacy', label: m.settings_privacy },
		{ href: '/admin/settings/searches', label: m.nav_saved_searches },
		{ href: '/admin/settings/notifications', label: m.settings_notifications }
	];
</script>

<nav class="mb-6 flex flex-wrap gap-2 text-sm" aria-label={m.nav_settings()}>
	{#each tabs as t (t.href)}
		{@const active = page.url.pathname.endsWith(t.href)}
		<a
			href={localizeHref(t.href)}
			class="rounded-lg px-3 py-1.5 no-underline {active
				? 'bg-[var(--accent)] text-white'
				: 'text-[var(--muted)] hover:bg-[var(--border)]/40'}"
			aria-current={active ? 'page' : undefined}>{t.label()}</a
		>
	{/each}
</nav>
{@render children()}
