//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class MapPoint {
  /// Returns a new [MapPoint] instance.
  MapPoint({
    required this.id,
    required this.lat,
    required this.lng,
    required this.rentAmount,
    this.isDemo = false,
  });

  String id;

  double lat;

  double lng;

  int rentAmount;

  /// Demo listing of the closed beta (terractl demo seed): shown with a prominent label, cannot be contacted, applied for or booked (problem code demo_listing).
  bool isDemo;

  @override
  bool operator ==(Object other) => identical(this, other) || other is MapPoint &&
    other.id == id &&
    other.lat == lat &&
    other.lng == lng &&
    other.rentAmount == rentAmount &&
    other.isDemo == isDemo;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (lat.hashCode) +
    (lng.hashCode) +
    (rentAmount.hashCode) +
    (isDemo.hashCode);

  @override
  String toString() => 'MapPoint[id=$id, lat=$lat, lng=$lng, rentAmount=$rentAmount, isDemo=$isDemo]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'lat'] = this.lat;
      json[r'lng'] = this.lng;
      json[r'rent_amount'] = this.rentAmount;
      json[r'is_demo'] = this.isDemo;
    return json;
  }

  /// Returns a new [MapPoint] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MapPoint? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "MapPoint[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "MapPoint[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return MapPoint(
        id: mapValueOfType<String>(json, r'id')!,
        lat: mapValueOfType<double>(json, r'lat')!,
        lng: mapValueOfType<double>(json, r'lng')!,
        rentAmount: mapValueOfType<int>(json, r'rent_amount')!,
        isDemo: mapValueOfType<bool>(json, r'is_demo')!,
      );
    }
    return null;
  }

  static List<MapPoint> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MapPoint>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MapPoint.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MapPoint> mapFromJson(dynamic json) {
    final map = <String, MapPoint>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MapPoint.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MapPoint-objects as value to a dart map
  static Map<String, List<MapPoint>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<MapPoint>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MapPoint.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'lat',
    'lng',
    'rent_amount',
    'is_demo',
  };
}

