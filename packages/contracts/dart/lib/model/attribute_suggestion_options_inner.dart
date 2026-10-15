//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AttributeSuggestionOptionsInner {
  /// Returns a new [AttributeSuggestionOptionsInner] instance.
  AttributeSuggestionOptionsInner({
    required this.value,
    required this.label,
  });

  String value;

  I18nText label;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AttributeSuggestionOptionsInner &&
    other.value == value &&
    other.label == label;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (value.hashCode) +
    (label.hashCode);

  @override
  String toString() => 'AttributeSuggestionOptionsInner[value=$value, label=$label]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'value'] = this.value;
      json[r'label'] = this.label;
    return json;
  }

  /// Returns a new [AttributeSuggestionOptionsInner] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AttributeSuggestionOptionsInner? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "AttributeSuggestionOptionsInner[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "AttributeSuggestionOptionsInner[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return AttributeSuggestionOptionsInner(
        value: mapValueOfType<String>(json, r'value')!,
        label: I18nText.fromJson(json[r'label'])!,
      );
    }
    return null;
  }

  static List<AttributeSuggestionOptionsInner> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AttributeSuggestionOptionsInner>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AttributeSuggestionOptionsInner.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AttributeSuggestionOptionsInner> mapFromJson(dynamic json) {
    final map = <String, AttributeSuggestionOptionsInner>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AttributeSuggestionOptionsInner.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AttributeSuggestionOptionsInner-objects as value to a dart map
  static Map<String, List<AttributeSuggestionOptionsInner>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AttributeSuggestionOptionsInner>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AttributeSuggestionOptionsInner.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'value',
    'label',
  };
}

