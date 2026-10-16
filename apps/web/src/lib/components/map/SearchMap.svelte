<script lang="ts">
	import type { Area, AreaAggregate, SearchResult } from '@terra/contracts';
	import { onMount } from 'svelte';
	import { MAP_STYLE } from '$app/env/public';
	import { markerLabel } from '#lib/demo.js';
	import { loadMaplibre } from '#lib/map/maplibre.js';

	let {
		result,
		areas,
		bbox,
		onArea,
		onBounds,
		onListing,
		formatPrice,
		boundsLabel
	}: {
		result: SearchResult;
		areas: Area[];
		bbox: number[] | null;
		onArea: (path: string) => void;
		onBounds: (bbox: number[]) => void;
		onListing: (id: string) => void;
		formatPrice: (minor: number) => string;
		boundsLabel: string;
	} = $props();

	type Geometry = { type: string; coordinates: unknown };
	type Outline = { type: 'Polygon' | 'MultiPolygon'; coordinates: number[][][] | number[][][][] };

	// Glyphs available on OpenFreeMap (the default font stack is not).
	const FONT = ['Noto Sans Regular'];

	let el: HTMLDivElement;
	let map: import('maplibre-gl').Map | undefined;
	let ready = $state(false);

	function areaFeatures(list: Area[], aggs: AreaAggregate[]) {
		const counts = new Map(aggs.map((a) => [a.path, a]));
		return {
			type: 'FeatureCollection' as const,
			features: list.map((a) => ({
				type: 'Feature' as const,
				geometry: a.geometry as unknown as Geometry,
				properties: { path: a.path, name: a.name, count: counts.get(a.path)?.count ?? 0 }
			}))
		};
	}

	function pointFeatures(r: SearchResult) {
		return {
			type: 'FeatureCollection' as const,
			features: r.points.map((p) => ({
				type: 'Feature' as const,
				geometry: { type: 'Point' as const, coordinates: [p.lng, p.lat] },
				properties: {
					id: p.id,
					price: markerLabel(formatPrice(p.rent_amount), p.is_demo),
					demo: p.is_demo
				}
			}))
		};
	}

	function fit() {
		if (!map) return;
		const coords: [number, number][] = [];
		if (bbox?.length === 4) {
			map.fitBounds([bbox[0], bbox[1], bbox[2], bbox[3]], { padding: 24, duration: 0 });
			return;
		}
		for (const a of areas) {
			const g = a.geometry as unknown as Outline;
			const polygons = (g.type === 'Polygon' ? [g.coordinates] : g.coordinates) as number[][][][];
			polygons.forEach((poly) => poly[0]?.forEach((c) => coords.push([c[0], c[1]])));
		}
		if (!coords.length) result.points.forEach((p) => coords.push([p.lng, p.lat]));
		const valid = coords.filter((c) => Number.isFinite(c[0]) && Number.isFinite(c[1]));
		coords.length = 0;
		coords.push(...valid);
		if (!coords.length) return;
		const lngs = coords.map((c) => c[0]);
		const lats = coords.map((c) => c[1]);
		map.fitBounds([Math.min(...lngs), Math.min(...lats), Math.max(...lngs), Math.max(...lats)], {
			padding: 24,
			maxZoom: 15,
			duration: 0
		});
	}

	onMount(() => {
		let disposed = false;
		// maplibre-gl (JS and CSS, ~1 MB) loads only in the browser, after hydration,
		// so it stays out of the /hledat entry chunk and the SSR bundle.
		Promise.all([loadMaplibre(), import('maplibre-gl/dist/maplibre-gl.css')]).then(
			([maplibregl]) => {
				if (disposed) return;
				map = new maplibregl.Map({
					container: el,
					style: MAP_STYLE,
					center: [15.4, 49.8],
					zoom: 6,
					attributionControl: { compact: true }
				});
				map.addControl(new maplibregl.NavigationControl({ showCompass: false }));
				map.on('load', () => {
					if (!map) return;
					map.addSource('areas', {
						type: 'geojson',
						data: areaFeatures(areas, result.areas) as never
					});
					map.addLayer({
						id: 'areas-fill',
						type: 'fill',
						source: 'areas',
						paint: {
							'fill-color': '#0f766e',
							'fill-opacity': ['interpolate', ['linear'], ['get', 'count'], 0, 0.04, 50, 0.25]
						}
					});
					map.addLayer({
						id: 'areas-line',
						type: 'line',
						source: 'areas',
						paint: { 'line-color': '#0f766e', 'line-width': 1.5 }
					});
					map.addLayer({
						id: 'areas-label',
						type: 'symbol',
						source: 'areas',
						layout: {
							'text-field': ['concat', ['get', 'name'], '\n', ['to-string', ['get', 'count']]],
							'text-size': 12,
							'text-font': FONT
						},
						paint: { 'text-color': '#134e4a', 'text-halo-color': '#fff', 'text-halo-width': 1.5 }
					});
					map.addSource('points', {
						type: 'geojson',
						data: pointFeatures(result),
						cluster: true,
						clusterRadius: 40
					});
					map.addLayer({
						id: 'clusters',
						type: 'circle',
						source: 'points',
						filter: ['has', 'point_count'],
						paint: {
							'circle-color': '#115e59',
							'circle-radius': ['step', ['get', 'point_count'], 14, 20, 18, 100, 24],
							'circle-opacity': 0.85
						}
					});
					map.addLayer({
						id: 'cluster-count',
						type: 'symbol',
						source: 'points',
						filter: ['has', 'point_count'],
						layout: {
							'text-field': ['get', 'point_count_abbreviated'],
							'text-size': 12,
							'text-font': FONT
						},
						paint: { 'text-color': '#fff' }
					});
					map.addLayer({
						id: 'price',
						type: 'symbol',
						source: 'points',
						filter: ['!', ['has', 'point_count']],
						layout: {
							'text-field': ['get', 'price'],
							'text-size': 11,
							'text-allow-overlap': false,
							'text-font': FONT
						},
						paint: {
							'text-color': '#fff',
							// Demo listings (closed beta) in amber, matching the demo label on cards.
							'text-halo-color': [
								'case',
								['boolean', ['get', 'demo'], false],
								'#d97706',
								'#0f766e'
							],
							'text-halo-width': 6
						}
					});
					map.on('click', 'areas-fill', (e) => {
						const hit = map?.queryRenderedFeatures(e.point, { layers: ['clusters', 'price'] });
						if (hit?.length) return;
						const path = e.features?.[0]?.properties?.path;
						if (path) onArea(String(path));
					});
					map.on('click', 'price', (e) => {
						const id = e.features?.[0]?.properties?.id;
						if (id) onListing(String(id));
					});
					map.on('click', 'clusters', (e) => {
						const f = e.features?.[0];
						if (f?.geometry.type === 'Point')
							map?.easeTo({
								center: f.geometry.coordinates as [number, number],
								zoom: (map?.getZoom() ?? 10) + 2
							});
					});
					for (const layer of ['areas-fill', 'price', 'clusters']) {
						map.on('mouseenter', layer, () => map && (map.getCanvas().style.cursor = 'pointer'));
						map.on('mouseleave', layer, () => map && (map.getCanvas().style.cursor = ''));
					}
					ready = true;
					fit();
				});
			}
		);
		return () => {
			disposed = true;
			map?.remove();
		};
	});

	// Update sources when the search changes (client-side navigation).
	$effect(() => {
		const a = areaFeatures(areas, result.areas);
		const p = pointFeatures(result);
		if (!ready || !map) return;
		(map.getSource('areas') as import('maplibre-gl').GeoJSONSource | undefined)?.setData(
			a as never
		);
		(map.getSource('points') as import('maplibre-gl').GeoJSONSource | undefined)?.setData(
			p as never
		);
		fit();
	});

	export function currentBounds(): number[] | null {
		if (!map) return null;
		const b = map.getBounds();
		return [b.getWest(), b.getSouth(), b.getEast(), b.getNorth()];
	}
</script>

<div
	class="relative h-full min-h-80 w-full overflow-hidden rounded-[var(--radius-card)] border border-[var(--border)]"
>
	<!-- Inline position: maplibre sets .maplibregl-map { position: relative } which would win over a class. -->
	<div bind:this={el} style="position: absolute; inset: 0" data-testid="search-map"></div>
	<button
		type="button"
		class="absolute top-2 left-2 rounded-lg bg-white/95 px-3 py-1.5 text-sm font-medium text-stone-900 shadow"
		onclick={() => {
			const b = currentBounds();
			if (b) onBounds(b);
		}}>⌖ {boundsLabel}</button
	>
</div>
