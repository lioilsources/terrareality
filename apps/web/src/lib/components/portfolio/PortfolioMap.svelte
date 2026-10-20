<script lang="ts">
	import { onMount } from 'svelte';
	import { MAP_STYLE } from '$app/env/public';
	import 'maplibre-gl/dist/maplibre-gl.css';
	import { bandColor, type RiskBand } from '#lib/portfolio.js';
	import { loadMaplibre } from '#lib/map/maplibre.js';

	export type MapPoint = {
		id: string;
		lat: number;
		lng: number;
		label: string;
		band?: RiskBand | null;
		vacant?: boolean;
	};

	let { points, onPoint }: { points: MapPoint[]; onPoint?: (id: string) => void } = $props();

	const FONT = ['Noto Sans Regular'];
	let el: HTMLDivElement;
	let map: import('maplibre-gl').Map | undefined;

	function features(list: MapPoint[]) {
		return {
			type: 'FeatureCollection' as const,
			features: list.map((p) => ({
				type: 'Feature' as const,
				geometry: { type: 'Point' as const, coordinates: [p.lng, p.lat] },
				properties: {
					id: p.id,
					label: p.label,
					color: p.vacant ? '#64748b' : p.band ? bandColor[p.band] : '#94a3b8'
				}
			}))
		};
	}

	function fit() {
		if (!map || !points.length) return;
		const lngs = points.map((p) => p.lng);
		const lats = points.map((p) => p.lat);
		map.fitBounds([Math.min(...lngs), Math.min(...lats), Math.max(...lngs), Math.max(...lats)], {
			padding: 48,
			maxZoom: 13,
			duration: 0
		});
	}

	onMount(() => {
		let disposed = false;
		loadMaplibre().then((maplibregl) => {
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
				map.addSource('units', { type: 'geojson', data: features(points) });
				map.addLayer({
					id: 'units',
					type: 'circle',
					source: 'units',
					paint: {
						'circle-color': ['get', 'color'],
						'circle-radius': 8,
						'circle-stroke-color': '#fff',
						'circle-stroke-width': 2
					}
				});
				map.addLayer({
					id: 'units-label',
					type: 'symbol',
					source: 'units',
					layout: {
						'text-field': ['get', 'label'],
						'text-size': 11,
						'text-offset': [0, 1.4],
						'text-anchor': 'top',
						'text-font': FONT
					},
					paint: { 'text-color': '#1e293b', 'text-halo-color': '#fff', 'text-halo-width': 1.5 }
				});
				map.on('click', 'units', (e) => {
					const id = e.features?.[0]?.properties?.id;
					if (id && onPoint) onPoint(String(id));
				});
				map.on('mouseenter', 'units', () => map && (map.getCanvas().style.cursor = 'pointer'));
				map.on('mouseleave', 'units', () => map && (map.getCanvas().style.cursor = ''));
				fit();
			});
		});
		return () => {
			disposed = true;
			map?.remove();
		};
	});

	$effect(() => {
		const src = map?.getSource('units') as import('maplibre-gl').GeoJSONSource | undefined;
		src?.setData(features(points));
		fit();
	});
</script>

<div
	bind:this={el}
	class="h-[480px] w-full overflow-hidden rounded-xl border border-[var(--border)]"
	data-testid="portfolio-map"
	data-points={points.length}
></div>
