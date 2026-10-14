//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AttrFilter {
  /// Returns a new [AttrFilter] instance.
  AttrFilter({
    this.values = const [],
    this.bool_,
    this.min,
    this.max,
  });

  List<String> values;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? bool_;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? min;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? max;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AttrFilter &&
    _deepEquality.equals(other.values, values) &&
    other.bool_ == bool_ &&
    other.min == min &&
    other.max == max;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (values.hashCode) +
    (bool_ == null ? 0 : bool_!.hashCode) +
    (min == null ? 0 : min!.hashCode) +
    (max == null ? 0 : max!.hashCode);

  @override
  String toString() => 'AttrFilter[values=$values, bool_=$bool_, min=$min, max=$max]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'values'] = this.values;
    if (this.bool_ != null) {
      json[r'bool'] = this.bool_;
    } else {
      json[r'bool'] = null;
    }
    if (this.min != null) {
      json[r'min'] = this.min;
    } else {
      json[r'min'] = null;
    }
    if (this.max != null) {
      json[r'max'] = this.max;
    } else {
      json[r'max'] = null;
    }
    return json;
  }

  /// Returns a new [AttrFilter] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AttrFilter? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "AttrFilter[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "AttrFilter[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return AttrFilter(
        values: json[r'values'] is Iterable
            ? (json[r'values'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        bool_: mapValueOfType<bool>(json, r'bool'),
        min: mapValueOfType<double>(json, r'min'),
        max: mapValueOfType<double>(json, r'max'),
      );
    }
    return null;
  }

  static List<AttrFilter> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AttrFilter>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AttrFilter.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AttrFilter> mapFromJson(dynamic json) {
    final map = <String, AttrFilter>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AttrFilter.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AttrFilter-objects as value to a dart map
  static Map<String, List<AttrFilter>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AttrFilter>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AttrFilter.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

