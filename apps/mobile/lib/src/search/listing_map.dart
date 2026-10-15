import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// MapLibre style. Override with `--dart-define=MAP_STYLE_URL=...`; the
/// default is the same free OpenFreeMap style the web uses (no API key).
const mapStyleUrl = String.fromEnvironment(
  'MAP_STYLE_URL',
  defaultValue: 'https://tiles.openfreemap.org/styles/positron',
);

/// One marker on the map: a listing, or an aggregated area when zoomed out.
class MapMarker {
  const MapMarker({required this.id, required this.lat, required this.lng, this.count = 1, this.areaPath});

  final String id;
  final double lat;
  final double lng;
  final int count;

  /// Set for area aggregates; tapping one narrows the search to the area.
  final String? areaPath;

  bool get isArea => areaPath != null;
}

/// Builds the map widget. The screens only see this interface so widget
/// tests can use a fake (MapLibre needs a platform view).
abstract class ListingMapFactory {
  const ListingMapFactory();

  /// [onBoundsChanged] gets west, south, east, north after the user moves
  /// the map. [onUnavailable] fires when the style cannot be loaded; the
  /// caller then falls back to the list.
  Widget build({
    Key? key,
    required List<MapMarker> markers,
    ValueChanged<MapMarker>? onTap,
    ValueChanged<List<double>>? onBoundsChanged,
    VoidCallback? onUnavailable,
    bool interactive = true,
  });
}

class MapLibreListingMap extends ListingMapFactory {
  const MapLibreListingMap({this.styleUrl = mapStyleUrl, this.loadTimeout = const Duration(seconds: 12)});

  final String styleUrl;
  final Duration loadTimeout;

  @override
  Widget build({
    Key? key,
    required List<MapMarker> markers,
    ValueChanged<MapMarker>? onTap,
    ValueChanged<List<double>>? onBoundsChanged,
    VoidCallback? onUnavailable,
    bool interactive = true,
  }) =>
      _MapLibreView(
        key: key,
        styleUrl: styleUrl,
        loadTimeout: loadTimeout,
        markers: markers,
        onTap: onTap,
        onBoundsChanged: onBoundsChanged,
        onUnavailable: onUnavailable,
        interactive: interactive,
      );
}

final listingMapProvider = Provider<ListingMapFactory>((ref) => const MapLibreListingMap());

class _MapLibreView extends StatefulWidget {
  const _MapLibreView({
    super.key,
    required this.styleUrl,
    required this.loadTimeout,
    required this.markers,
    required this.interactive,
    this.onTap,
    this.onBoundsChanged,
    this.onUnavailable,
  });

  final String styleUrl;
  final Duration loadTimeout;
  final List<MapMarker> markers;
  final bool interactive;
  final ValueChanged<MapMarker>? onTap;
  final ValueChanged<List<double>>? onBoundsChanged;
  final VoidCallback? onUnavailable;

  @override
  State<_MapLibreView> createState() => _MapLibreViewState();
}

class _MapLibreViewState extends State<_MapLibreView> {
  MapLibreMapController? _controller;
  Timer? _timeout;
  bool _styleLoaded = false;
  bool _programmaticMove = false;

  @override
  void initState() {
    super.initState();
    if (widget.styleUrl.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onUnavailable?.call());
      return;
    }
    _timeout = Timer(widget.loadTimeout, () {
      if (!_styleLoaded) widget.onUnavailable?.call();
    });
  }

  @override
  void didUpdateWidget(_MapLibreView old) {
    super.didUpdateWidget(old);
    if (_styleLoaded && !identical(old.markers, widget.markers)) unawaited(_draw(fit: false));
  }

  @override
  void dispose() {
    _timeout?.cancel();
    _controller?.onCircleTapped.remove(_circleTapped);
    super.dispose();
  }

  void _circleTapped(Circle c) {
    final id = c.data?['id'];
    final m = widget.markers.where((m) => m.id == id).firstOrNull;
    if (m != null) widget.onTap?.call(m);
  }

  Future<void> _draw({required bool fit}) async {
    final c = _controller;
    if (c == null) return;
    try {
      await c.clearCircles();
      if (widget.markers.isEmpty) return;
      await c.addCircles(
        [
          for (final m in widget.markers)
            CircleOptions(
              geometry: LatLng(m.lat, m.lng),
              circleRadius: m.isArea ? 10 + math.min(20, m.count.toDouble()) : 7,
              circleColor: m.isArea ? '#0f766e' : '#2f7d4f',
              circleOpacity: m.isArea ? 0.6 : 0.9,
              circleStrokeWidth: 2,
              circleStrokeColor: '#ffffff',
            ),
        ],
        [for (final m in widget.markers) {'id': m.id}],
      );
      if (fit) await _fit(c);
    } catch (_) {
      // Annotations are best effort; the list stays usable.
    }
  }

  Future<void> _fit(MapLibreMapController c) async {
    final ms = widget.markers;
    _programmaticMove = true;
    if (ms.length == 1) {
      await c.moveCamera(CameraUpdate.newLatLngZoom(LatLng(ms.first.lat, ms.first.lng), 14));
      return;
    }
    final lats = ms.map((m) => m.lat);
    final lngs = ms.map((m) => m.lng);
    await c.moveCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(lats.reduce(math.min), lngs.reduce(math.min)),
        northeast: LatLng(lats.reduce(math.max), lngs.reduce(math.max)),
      ),
      left: 32,
      top: 32,
      right: 32,
      bottom: 32,
    ));
  }

  Future<void> _idle() async {
    if (_programmaticMove) {
      _programmaticMove = false;
      return;
    }
    final c = _controller;
    if (c == null || widget.onBoundsChanged == null) return;
    final b = await c.getVisibleRegion();
    widget.onBoundsChanged!([b.southwest.longitude, b.southwest.latitude, b.northeast.longitude, b.northeast.latitude]);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.styleUrl.isEmpty) return const SizedBox.shrink();
    return MapLibreMap(
      styleString: widget.styleUrl,
      initialCameraPosition: const CameraPosition(target: LatLng(49.8, 15.4), zoom: 6),
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      scrollGesturesEnabled: widget.interactive,
      zoomGesturesEnabled: widget.interactive,
      trackCameraPosition: true,
      onMapCreated: (c) {
        _controller = c;
        c.onCircleTapped.add(_circleTapped);
      },
      onStyleLoadedCallback: () {
        _styleLoaded = true;
        _timeout?.cancel();
        unawaited(_draw(fit: true));
      },
      onCameraIdle: widget.interactive ? () => unawaited(_idle()) : null,
    );
  }
}
