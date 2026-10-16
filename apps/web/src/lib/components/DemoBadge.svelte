<script lang="ts">
	import { m } from '#lib/paraglide/messages.js';

	/** Label for closed-beta demo listings; `short` for tight spaces (owner admin lists). */
	let { short = false, class: cls = '' }: { short?: boolean; class?: string } = $props();
</script>

<!-- Text, not only color: the listing cannot be rented. -->
<span
	class="inline-block rounded bg-amber-600/95 px-2 py-0.5 text-xs font-semibold text-white {cls}"
	data-testid="demo-label">{short ? m.listing_demo_short() : m.listing_demo_badge()}</span
>
