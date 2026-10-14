<script lang="ts">
	import { enhance } from '$app/forms';
	import { m } from '#lib/paraglide/messages.js';
	import { getLocale, localizeHref } from '#lib/paraglide/runtime.js';
	import { fmtDate, fmtDateTime, invitableRoles, levelLabel, roleLabel } from '#lib/labels.js';
	import Alert from '#lib/components/Alert.svelte';
	import Button from '#lib/components/Button.svelte';
	import Card from '#lib/components/Card.svelte';
	import Field from '#lib/components/Field.svelte';
	import type { Role } from '@terra/contracts';
	import type { PageProps } from './$types';

	let { data, form }: PageProps = $props();
	const org = $derived(data.org.organization);
	const roles: Role[] = ['owner', 'admin', 'agent', 'accountant', 'maintenance', 'viewer'];
	const select = 'rounded-lg border border-[var(--border)] bg-[var(--surface)] px-2 py-1.5 text-sm';
</script>

<svelte:head><title>{org.name} · {m.app_name()}</title></svelte:head>

<div class="grid gap-6">
	<div class="flex flex-wrap items-center justify-between gap-3">
		<h1 class="text-2xl font-semibold" data-testid="org-name">{org.name}</h1>
		<a href={localizeHref(`/admin/orgs/${org.id}/listings`)}>{m.nav_listings()} →</a>
	</div>
	{#if form?.error}<Alert kind="error">{form.error}</Alert>{/if}

	{#if data.manage}
		<Card title={m.org_details()}>
			<form method="POST" action="?/update" use:enhance class="grid max-w-md gap-3">
				{#if form?.saved}<Alert kind="success">{m.profile_saved()}</Alert>{/if}
				<Field label={m.field_org_name()} name="name" value={org.name} required maxlength={200} />
				{#if org.kind === 'company'}
					<Field
						label={m.field_registration_no()}
						name="registration_no"
						value={org.registration_no ?? ''}
					/>
					<Field label={m.field_vat_no()} name="vat_no" value={org.vat_no ?? ''} />
				{/if}
				<Button type="submit" variant="secondary">{m.save()}</Button>
			</form>
		</Card>
	{/if}

	<Card title={m.org_members()} testid="members">
		<ul class="grid gap-2">
			{#each data.members as mem (mem.user_id)}
				<li
					class="flex flex-wrap items-center justify-between gap-2 rounded-lg border border-[var(--border)] px-3 py-2 text-sm"
				>
					<span>
						<strong>{mem.display_name || mem.email}</strong>
						<span class="text-[var(--muted)]"
							>· {mem.email} · {levelLabel[mem.verification_level]()}</span
						>
					</span>
					{#if data.manage}
						<span class="flex items-center gap-2">
							<form method="POST" action="?/role" use:enhance class="flex items-center gap-2">
								<input type="hidden" name="user_id" value={mem.user_id} />
								<select
									name="role"
									class={select}
									aria-label={m.field_role()}
									onchange={(e) => e.currentTarget.form?.requestSubmit()}
								>
									{#each roles as r (r)}<option value={r} selected={r === mem.role}
											>{roleLabel[r]()}</option
										>{/each}
								</select>
							</form>
							{#if org.kind === 'company'}
								<form method="POST" action="?/remove" use:enhance>
									<input type="hidden" name="user_id" value={mem.user_id} />
									<Button type="submit" variant="secondary">{m.remove()}</Button>
								</form>
							{/if}
						</span>
					{:else}
						<span>{roleLabel[mem.role]()}</span>
					{/if}
				</li>
			{/each}
		</ul>
	</Card>

	{#if data.manage}
		<Card title={m.org_invitations()} testid="invitations">
			<form method="POST" action="?/invite" use:enhance class="mb-4 flex flex-wrap items-end gap-3">
				<div class="min-w-64 flex-1">
					<Field
						label={m.field_email()}
						name="email"
						type="email"
						required
						value={form?.email ?? ''}
					/>
				</div>
				<label class="grid gap-1 text-sm font-medium">
					{m.field_role()}
					<select name="role" class={select}>
						{#each invitableRoles as r (r)}<option value={r} selected={r === 'agent'}
								>{roleLabel[r]()}</option
							>{/each}
					</select>
				</label>
				<Button type="submit">{m.org_invite()}</Button>
			</form>
			{#if form?.invited}<div class="mb-3">
					<Alert kind="success">{m.org_invite_sent()}</Alert>
				</div>{/if}
			{#if form?.inviteError}<div class="mb-3">
					<Alert kind="error">{form.inviteError}</Alert>
				</div>{/if}
			{#if data.invitations.length === 0}
				<p class="text-sm text-[var(--muted)]">{m.org_no_invitations()}</p>
			{:else}
				<ul class="grid gap-2">
					{#each data.invitations as inv (inv.id)}
						<li
							class="flex flex-wrap items-center justify-between gap-2 rounded-lg border border-[var(--border)] px-3 py-2 text-sm"
						>
							<span
								>{inv.email} · {roleLabel[inv.role]()} · {m.org_expires({
									date: fmtDate(inv.expires_at, getLocale())
								})}</span
							>
							<form method="POST" action="?/revoke" use:enhance>
								<input type="hidden" name="id" value={inv.id} />
								<Button type="submit" variant="secondary">{m.revoke()}</Button>
							</form>
						</li>
					{/each}
				</ul>
			{/if}
		</Card>

		<Card title={m.org_audit()}>
			<div class="overflow-x-auto">
				<table class="w-full text-left text-sm">
					<thead class="text-[var(--muted)]">
						<tr
							><th class="py-1 pr-4">{m.audit_when()}</th><th class="pr-4">{m.audit_who()}</th><th
								>{m.audit_action()}</th
							></tr
						>
					</thead>
					<tbody>
						{#each data.audit as a (a.id)}
							<tr class="border-t border-[var(--border)]">
								<td class="py-1 pr-4 whitespace-nowrap"
									>{fmtDateTime(a.occurred_at, getLocale())}</td
								>
								<td class="pr-4">{a.actor_email}{a.impersonator_id ? ' *' : ''}</td>
								<td><code>{a.action}</code></td>
							</tr>
						{/each}
					</tbody>
				</table>
			</div>
		</Card>
	{/if}
</div>
