//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class I18nText {
  /// Returns a new [I18nText] instance.
  I18nText({
    required this.cs,
    required this.en,
  });

  String cs;

  String en;

  @override
  bool operator ==(Object other) => identical(this, other) || other is I18nText &&
    other.cs == cs &&
    other.en == en;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (cs.hashCode) +
    (en.hashCode);

  @override
  String toString() => 'I18nText[cs=$cs, en=$en]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'cs'] = this.cs;
      json[r'en'] = this.en;
    return json;
  }

  /// Returns a new [I18nText] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static I18nText? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "I18nText[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "I18nText[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return I18nText(
        cs: mapValueOfType<String>(json, r'cs')!,
        en: mapValueOfType<String>(json, r'en')!,
      );
    }
    return null;
  }

  static List<I18nText> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <I18nText>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = I18nText.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, I18nText> mapFromJson(dynamic json) {
    final map = <String, I18nText>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = I18nText.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of I18nText-objects as value to a dart map
  static Map<String, List<I18nText>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<I18nText>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = I18nText.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'cs',
    'en',
  };
}

