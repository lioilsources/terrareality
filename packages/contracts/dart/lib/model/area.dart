//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Area {
  /// Returns a new [Area] instance.
  Area({
    required this.path,
    required this.name,
    required this.slug,
    required this.level,
    required this.lat,
    required this.lng,
    this.geometry = const {},
  });

  String path;

  String name;

  String slug;

  int level;

  double lat;

  double lng;

  /// GeoJSON MultiPolygon (simplified).
  Map<String, Object> geometry;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Area &&
    other.path == path &&
    other.name == name &&
    other.slug == slug &&
    other.level == level &&
    other.lat == lat &&
    other.lng == lng &&
    _deepEquality.equals(other.geometry, geometry);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (path.hashCode) +
    (name.hashCode) +
    (slug.hashCode) +
    (level.hashCode) +
    (lat.hashCode) +
    (lng.hashCode) +
    (geometry.hashCode);

  @override
  String toString() => 'Area[path=$path, name=$name, slug=$slug, level=$level, lat=$lat, lng=$lng, geometry=$geometry]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'path'] = this.path;
      json[r'name'] = this.name;
      json[r'slug'] = this.slug;
      json[r'level'] = this.level;
      json[r'lat'] = this.lat;
      json[r'lng'] = this.lng;
      json[r'geometry'] = this.geometry;
    return json;
  }

  /// Returns a new [Area] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Area? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "Area[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "Area[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Area(
        path: mapValueOfType<String>(json, r'path')!,
        name: mapValueOfType<String>(json, r'name')!,
        slug: mapValueOfType<String>(json, r'slug')!,
        level: mapValueOfType<int>(json, r'level')!,
        lat: mapValueOfType<double>(json, r'lat')!,
        lng: mapValueOfType<double>(json, r'lng')!,
        geometry: mapCastOfType<String, Object>(json, r'geometry')!,
      );
    }
    return null;
  }

  static List<Area> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Area>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Area.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Area> mapFromJson(dynamic json) {
    final map = <String, Area>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Area.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Area-objects as value to a dart map
  static Map<String, List<Area>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Area>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Area.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'path',
    'name',
    'slug',
    'level',
    'lat',
    'lng',
    'geometry',
  };
}

