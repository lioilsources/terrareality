<script lang="ts">
	import { m } from '#lib/paraglide/messages.js';
	import { localizeHref } from '#lib/paraglide/runtime.js';
	import type { LayoutProps } from './$types';

	let { children }: LayoutProps = $props();
</script>

<nav class="mb-6 flex flex-wrap gap-4 text-sm" aria-label={m.nav_backoffice()}>
	<a href={localizeHref('/backoffice')}>{m.bo_dashboard()}</a>
	<a href={localizeHref('/backoffice/reviews')}>{m.bo_reviews()}</a>
	<a href={localizeHref('/backoffice/moderation')}>{m.bo_moderation()}</a>
	<a href={localizeHref('/backoffice/filters')}>{m.bo_filters()}</a>
	<a href={localizeHref('/backoffice/atributy')}>{m.bo_attrs()}</a>
	<a href={localizeHref('/backoffice/flags')}>{m.bo_flags()}</a>
	<a href={localizeHref('/backoffice/promo')}>{m.bo_promo()}</a>
	<a href={localizeHref('/backoffice/sablony')}>{m.bo_templates()}</a>
	<a href={localizeHref('/backoffice/audit')}>{m.bo_audit()}</a>
</nav>
{@render children()}
