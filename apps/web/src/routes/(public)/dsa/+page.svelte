<script lang="ts">
	import LegalPage from '#lib/components/legal/LegalPage.svelte';
	import type { PageProps } from './$types';

	let { data }: PageProps = $props();
</script>

<LegalPage page={data.doc} />
