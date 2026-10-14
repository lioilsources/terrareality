//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class MunicipalityStat {
  /// Returns a new [MunicipalityStat] instance.
  MunicipalityStat({
    required this.name,
    required this.slug,
    required this.path,
    required this.listings,
    required this.medianRent,
  });

  String name;

  String slug;

  String path;

  int listings;

  int medianRent;

  @override
  bool operator ==(Object other) => identical(this, other) || other is MunicipalityStat &&
    other.name == name &&
    other.slug == slug &&
    other.path == path &&
    other.listings == listings &&
    other.medianRent == medianRent;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name.hashCode) +
    (slug.hashCode) +
    (path.hashCode) +
    (listings.hashCode) +
    (medianRent.hashCode);

  @override
  String toString() => 'MunicipalityStat[name=$name, slug=$slug, path=$path, listings=$listings, medianRent=$medianRent]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'name'] = this.name;
      json[r'slug'] = this.slug;
      json[r'path'] = this.path;
      json[r'listings'] = this.listings;
      json[r'median_rent'] = this.medianRent;
    return json;
  }

  /// Returns a new [MunicipalityStat] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MunicipalityStat? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "MunicipalityStat[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "MunicipalityStat[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return MunicipalityStat(
        name: mapValueOfType<String>(json, r'name')!,
        slug: mapValueOfType<String>(json, r'slug')!,
        path: mapValueOfType<String>(json, r'path')!,
        listings: mapValueOfType<int>(json, r'listings')!,
        medianRent: mapValueOfType<int>(json, r'median_rent')!,
      );
    }
    return null;
  }

  static List<MunicipalityStat> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MunicipalityStat>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MunicipalityStat.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MunicipalityStat> mapFromJson(dynamic json) {
    final map = <String, MunicipalityStat>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MunicipalityStat.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MunicipalityStat-objects as value to a dart map
  static Map<String, List<MunicipalityStat>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<MunicipalityStat>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MunicipalityStat.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'name',
    'slug',
    'path',
    'listings',
    'median_rent',
  };
}

