//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AreaAggregate {
  /// Returns a new [AreaAggregate] instance.
  AreaAggregate({
    required this.path,
    required this.name,
    required this.level,
    required this.count,
    required this.medianRent,
    required this.lat,
    required this.lng,
  });

  String path;

  String name;

  int level;

  int count;

  int medianRent;

  double lat;

  double lng;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AreaAggregate &&
    other.path == path &&
    other.name == name &&
    other.level == level &&
    other.count == count &&
    other.medianRent == medianRent &&
    other.lat == lat &&
    other.lng == lng;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (path.hashCode) +
    (name.hashCode) +
    (level.hashCode) +
    (count.hashCode) +
    (medianRent.hashCode) +
    (lat.hashCode) +
    (lng.hashCode);

  @override
  String toString() => 'AreaAggregate[path=$path, name=$name, level=$level, count=$count, medianRent=$medianRent, lat=$lat, lng=$lng]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'path'] = this.path;
      json[r'name'] = this.name;
      json[r'level'] = this.level;
      json[r'count'] = this.count;
      json[r'median_rent'] = this.medianRent;
      json[r'lat'] = this.lat;
      json[r'lng'] = this.lng;
    return json;
  }

  /// Returns a new [AreaAggregate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AreaAggregate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "AreaAggregate[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "AreaAggregate[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return AreaAggregate(
        path: mapValueOfType<String>(json, r'path')!,
        name: mapValueOfType<String>(json, r'name')!,
        level: mapValueOfType<int>(json, r'level')!,
        count: mapValueOfType<int>(json, r'count')!,
        medianRent: mapValueOfType<int>(json, r'median_rent')!,
        lat: mapValueOfType<double>(json, r'lat')!,
        lng: mapValueOfType<double>(json, r'lng')!,
      );
    }
    return null;
  }

  static List<AreaAggregate> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AreaAggregate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AreaAggregate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AreaAggregate> mapFromJson(dynamic json) {
    final map = <String, AreaAggregate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AreaAggregate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AreaAggregate-objects as value to a dart map
  static Map<String, List<AreaAggregate>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AreaAggregate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AreaAggregate.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'path',
    'name',
    'level',
    'count',
    'median_rent',
    'lat',
    'lng',
  };
}

