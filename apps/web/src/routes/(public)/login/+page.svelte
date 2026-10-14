<script lang="ts">
	import { enhance } from '$app/forms';
	import { m } from '#lib/paraglide/messages.js';
	import { localizeHref } from '#lib/paraglide/runtime.js';
	import Alert from '#lib/components/Alert.svelte';
	import Button from '#lib/components/Button.svelte';
	import Card from '#lib/components/Card.svelte';
	import Field from '#lib/components/Field.svelte';
	import type { PageProps } from './$types';

	let { data, form }: PageProps = $props();
	const names: Record<string, string> = { google: 'Google', apple: 'Apple' };
	const nextQ = $derived(`?next=${encodeURIComponent(data.next)}`);
</script>

<svelte:head><title>{m.login_title()} · {m.app_name()}</title></svelte:head>

<div class="mx-auto grid max-w-md gap-6">
	<h1 class="text-2xl font-semibold">{m.login_title()}</h1>
	<Card>
		<form
			method="POST"
			action="?/login&next={encodeURIComponent(data.next)}"
			use:enhance
			class="grid gap-4"
		>
			{#if form?.error}<Alert kind="error">{form.error}</Alert>{/if}
			<Field
				label={m.field_email()}
				name="email"
				type="email"
				autocomplete="email"
				required
				value={form?.email ?? ''}
			/>
			<Field
				label={m.field_password()}
				name="password"
				type="password"
				autocomplete="current-password"
				required
			/>
			<Button type="submit">{m.login_submit()}</Button>
			<div class="flex justify-between text-sm">
				<a href={localizeHref('/login/forgot')}>{m.login_forgot()}</a>
				<span
					>{m.login_no_account()}
					<a href={localizeHref('/register') + nextQ}>{m.nav_register()}</a></span
				>
			</div>
		</form>
	</Card>

	{#if data.providers.length}
		<Card>
			<div class="grid gap-2">
				{#each data.providers as p (p.id)}
					<a
						class="rounded-lg border border-[var(--border)] px-4 py-2 text-center text-sm font-medium no-underline hover:bg-[var(--border)]/40"
						href="{localizeHref(`/auth/oidc/${p.id}`)}{nextQ}"
						data-sveltekit-reload
					>
						{m.login_social({ provider: names[p.id] ?? p.id })}{p.mock ? ' (mock)' : ''}
					</a>
				{/each}
				<p class="text-xs text-[var(--muted)]">{m.login_social_terms()}</p>
			</div>
		</Card>
	{/if}

	<Card title={m.login_magic_title()}>
		<form method="POST" action="?/magic" use:enhance class="grid gap-4">
			{#if form?.magicSent}<Alert kind="success">{m.login_magic_sent()}</Alert>{/if}
			{#if form?.magicError}<Alert kind="error">{form.magicError}</Alert>{/if}
			<Field label={m.field_email()} name="email" type="email" autocomplete="email" required />
			<Button type="submit" variant="secondary">{m.login_magic_submit()}</Button>
		</form>
	</Card>
</div>
