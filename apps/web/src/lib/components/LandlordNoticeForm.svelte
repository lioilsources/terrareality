<script lang="ts">
	import { enhance } from '$app/forms';
	import { m } from '#lib/paraglide/messages.js';
	import { field } from '#lib/applications.js';
	import { deliveredOnRange, noticeReasonsFor } from '#lib/leasing.js';
	import Alert from '#lib/components/Alert.svelte';
	import Button from '#lib/components/Button.svelte';

	/**
	 * A landlord's notice (§ 2288 OZ): the platform only records the reason and the
	 * delivery date; the written notice with the instruction about the court review is
	 * the landlord's job, which the statutory hint and the confirmation make explicit.
	 */
	let { endsOn, error = null }: { endsOn?: string | null; error?: string | null } = $props();
	const reasons = $derived(noticeReasonsFor(endsOn));
	const range = deliveredOnRange();
	const id = $props.id();
</script>

<div class="grid gap-3" data-testid="landlord-notice">
	<div class="grid gap-2 text-sm" id="{id}-info" data-testid="landlord-notice-info">
		<p>{m.lease_notice_landlord_intro()}</p>
		<p class="text-[var(--muted)]">{m.lease_notice_landlord_written()}</p>
	</div>
	{#if error}<Alert kind="error">{error}</Alert>{/if}
	<form
		method="POST"
		action="?/notice"
		use:enhance={() =>
			({ update }) =>
				update({ reset: false })}
		class="grid gap-3"
		aria-describedby="{id}-info"
	>
		<label class="grid gap-1 text-sm font-medium"
			>{m.lease_notice_reason()}
			<select name="reason" required class="{field} font-normal" data-testid="notice-reason">
				<option value="">{m.lease_notice_reason_choose()}</option>
				{#each reasons as [value, label] (value)}<option {value}>{label()}</option>{/each}
			</select>
		</label>
		<label class="grid gap-1 text-sm font-medium"
			>{m.lease_notice_explanation()}
			<textarea
				name="explanation"
				rows="4"
				maxlength="2000"
				aria-describedby="{id}-explanation"
				class="{field} font-normal"></textarea>
			<span id="{id}-explanation" class="text-xs font-normal text-[var(--muted)]"
				>{m.lease_notice_explanation_hint()}</span
			>
		</label>
		<label class="grid gap-1 text-sm font-medium"
			>{m.lease_notice_on()}
			<input
				type="date"
				name="delivered_on"
				required
				min={range.min}
				max={range.max}
				aria-describedby="{id}-delivered"
				class="{field} font-normal"
			/>
			<span id="{id}-delivered" class="text-xs font-normal text-[var(--muted)]"
				>{m.lease_notice_delivered_hint()}</span
			>
		</label>
		<label class="flex items-start gap-2 text-sm">
			<input type="checkbox" name="confirm" required class="mt-0.5" />
			<span>{m.lease_notice_landlord_confirm()}</span>
		</label>
		<Button type="submit" variant="danger">{m.lease_notice_landlord_submit()}</Button>
	</form>
</div>
