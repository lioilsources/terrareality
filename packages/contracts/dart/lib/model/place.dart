//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Place {
  /// Returns a new [Place] instance.
  Place({
    required this.path,
    required this.name,
    this.bbox = const [],
  });

  String path;

  String name;

  List<double> bbox;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Place &&
    other.path == path &&
    other.name == name &&
    _deepEquality.equals(other.bbox, bbox);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (path.hashCode) +
    (name.hashCode) +
    (bbox.hashCode);

  @override
  String toString() => 'Place[path=$path, name=$name, bbox=$bbox]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'path'] = this.path;
      json[r'name'] = this.name;
      json[r'bbox'] = this.bbox;
    return json;
  }

  /// Returns a new [Place] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Place? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "Place[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "Place[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Place(
        path: mapValueOfType<String>(json, r'path')!,
        name: mapValueOfType<String>(json, r'name')!,
        bbox: json[r'bbox'] is Iterable
            ? (json[r'bbox'] as Iterable).cast<double>().toList(growable: false)
            : const [],
      );
    }
    return null;
  }

  static List<Place> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Place>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Place.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Place> mapFromJson(dynamic json) {
    final map = <String, Place>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Place.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Place-objects as value to a dart map
  static Map<String, List<Place>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Place>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Place.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'path',
    'name',
    'bbox',
  };
}

