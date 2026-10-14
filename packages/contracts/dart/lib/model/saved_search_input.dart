//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class SavedSearchInput {
  /// Returns a new [SavedSearchInput] instance.
  SavedSearchInput({
    required this.name,
    required this.query,
    this.notify = true,
  });

  String name;

  SearchQuery query;

  bool notify;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SavedSearchInput &&
    other.name == name &&
    other.query == query &&
    other.notify == notify;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name.hashCode) +
    (query.hashCode) +
    (notify.hashCode);

  @override
  String toString() => 'SavedSearchInput[name=$name, query=$query, notify=$notify]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'name'] = this.name;
      json[r'query'] = this.query;
      json[r'notify'] = this.notify;
    return json;
  }

  /// Returns a new [SavedSearchInput] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SavedSearchInput? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "SavedSearchInput[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "SavedSearchInput[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return SavedSearchInput(
        name: mapValueOfType<String>(json, r'name')!,
        query: SearchQuery.fromJson(json[r'query'])!,
        notify: mapValueOfType<bool>(json, r'notify') ?? true,
      );
    }
    return null;
  }

  static List<SavedSearchInput> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SavedSearchInput>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SavedSearchInput.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SavedSearchInput> mapFromJson(dynamic json) {
    final map = <String, SavedSearchInput>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SavedSearchInput.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SavedSearchInput-objects as value to a dart map
  static Map<String, List<SavedSearchInput>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SavedSearchInput>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SavedSearchInput.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'name',
    'query',
  };
}

