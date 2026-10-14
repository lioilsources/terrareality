<script lang="ts">
	import { m } from '#lib/paraglide/messages.js';
	import { localizeHref } from '#lib/paraglide/runtime.js';
	import type { LayoutProps } from './$types';

	let { children }: LayoutProps = $props();
</script>

<nav class="mb-6 flex gap-4 text-sm">
	<a href={localizeHref('/backoffice')}>{m.bo_users()}</a>
	<a href={localizeHref('/backoffice/audit')}>{m.bo_audit()}</a>
</nav>
{@render children()}
