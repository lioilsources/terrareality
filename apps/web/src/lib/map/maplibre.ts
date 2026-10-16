// MapLibre 6 looks for its worker next to its own module (maplibre-gl-worker.mjs via a computed
// import.meta.url), which Vite does not emit in a production build: the map stayed blank with
// "Worker failed to load". Bundle the worker explicitly and point MapLibre at it (same origin,
// allowed by the CSP worker-src 'self').
import workerUrl from 'maplibre-gl/dist/maplibre-gl-worker.mjs?worker&url';

export async function loadMaplibre(): Promise<typeof import('maplibre-gl')> {
	const maplibregl = await import('maplibre-gl');
	maplibregl.setWorkerUrl(workerUrl);
	return maplibregl;
}
