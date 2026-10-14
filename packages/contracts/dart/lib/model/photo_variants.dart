//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PhotoVariants {
  /// Returns a new [PhotoVariants] instance.
  PhotoVariants({
    required this.thumb,
    required this.medium,
    required this.large,
  });

  String thumb;

  String medium;

  String large;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PhotoVariants &&
    other.thumb == thumb &&
    other.medium == medium &&
    other.large == large;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (thumb.hashCode) +
    (medium.hashCode) +
    (large.hashCode);

  @override
  String toString() => 'PhotoVariants[thumb=$thumb, medium=$medium, large=$large]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'thumb'] = this.thumb;
      json[r'medium'] = this.medium;
      json[r'large'] = this.large;
    return json;
  }

  /// Returns a new [PhotoVariants] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PhotoVariants? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PhotoVariants[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PhotoVariants[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PhotoVariants(
        thumb: mapValueOfType<String>(json, r'thumb')!,
        medium: mapValueOfType<String>(json, r'medium')!,
        large: mapValueOfType<String>(json, r'large')!,
      );
    }
    return null;
  }

  static List<PhotoVariants> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PhotoVariants>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PhotoVariants.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PhotoVariants> mapFromJson(dynamic json) {
    final map = <String, PhotoVariants>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PhotoVariants.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PhotoVariants-objects as value to a dart map
  static Map<String, List<PhotoVariants>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PhotoVariants>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PhotoVariants.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'thumb',
    'medium',
    'large',
  };
}

