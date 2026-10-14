// @ts-check
import { defineConfig } from 'astro/config';
import svelte from '@astrojs/svelte';
import tailwindcss from '@tailwindcss/vite';

// Marketing + SEO site. Locality pages (/pronajem-bytu/<obec>) are generated
// from the API in milestone M3; M0 ships the landing page in cs and en.
export default defineConfig({
  site: 'https://terrareality.cz',
  integrations: [svelte()],
  i18n: {
    locales: ['cs', 'en'],
    defaultLocale: 'cs',
    routing: { prefixDefaultLocale: false }
  },
  vite: {
    plugins: [tailwindcss()]
  }
});
