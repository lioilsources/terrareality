<script lang="ts">
	import { enhance } from '$app/forms';
	import { m } from '#lib/paraglide/messages.js';
	import Alert from '#lib/components/Alert.svelte';
	import Button from '#lib/components/Button.svelte';
	import Card from '#lib/components/Card.svelte';
	import type { PageProps } from './$types';

	let { data, form }: PageProps = $props();
	const field = 'rounded-lg border border-[var(--border)] bg-[var(--surface)] px-3 py-2';
</script>

<div class="grid gap-6">
	<Card title={m.msg_templates()}>
		{#if form?.error}<div class="mb-3"><Alert kind="error">{form.error}</Alert></div>{/if}
		{#if data.templates.length === 0}<p class="text-sm text-[var(--muted)]">
				{m.msg_templates_empty()}
			</p>{/if}
		<ul class="grid gap-4" data-testid="templates">
			{#each data.templates as tpl (tpl.id)}
				<li class="rounded-lg border border-[var(--border)] p-3">
					<form method="POST" action="?/update" use:enhance class="grid gap-2">
						<input type="hidden" name="id" value={tpl.id} />
						<input
							name="title"
							value={tpl.title}
							maxlength="80"
							aria-label={m.msg_template_title()}
							class={field}
						/>
						<textarea
							name="body"
							rows="3"
							maxlength="4000"
							aria-label={m.msg_template_body()}
							class={field}>{tpl.body}</textarea
						>
						<div class="flex gap-2">
							<Button type="submit" variant="secondary">{m.msg_template_save()}</Button>
							<Button type="submit" variant="danger" formaction="?/delete"
								>{m.msg_template_delete()}</Button
							>
						</div>
					</form>
				</li>
			{/each}
		</ul>
	</Card>
	<Card title={m.msg_template_add()}>
		<form method="POST" action="?/create" use:enhance class="grid gap-3">
			<label class="grid gap-1 text-sm font-medium"
				>{m.msg_template_title()}<input name="title" required maxlength="80" class={field} /></label
			>
			<label class="grid gap-1 text-sm font-medium"
				>{m.msg_template_body()}<textarea
					name="body"
					required
					rows="4"
					maxlength="4000"
					class={field}></textarea></label
			>
			<div><Button type="submit">{m.msg_template_add()}</Button></div>
		</form>
	</Card>
</div>
