//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class SavedSearch {
  /// Returns a new [SavedSearch] instance.
  SavedSearch({
    required this.id,
    required this.name,
    required this.query,
    required this.notify,
    required this.createdAt,
  });

  String id;

  String name;

  SearchQuery query;

  bool notify;

  DateTime createdAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SavedSearch &&
    other.id == id &&
    other.name == name &&
    other.query == query &&
    other.notify == notify &&
    other.createdAt == createdAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (name.hashCode) +
    (query.hashCode) +
    (notify.hashCode) +
    (createdAt.hashCode);

  @override
  String toString() => 'SavedSearch[id=$id, name=$name, query=$query, notify=$notify, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'name'] = this.name;
      json[r'query'] = this.query;
      json[r'notify'] = this.notify;
      json[r'created_at'] = this.createdAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [SavedSearch] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SavedSearch? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "SavedSearch[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "SavedSearch[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return SavedSearch(
        id: mapValueOfType<String>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        query: SearchQuery.fromJson(json[r'query'])!,
        notify: mapValueOfType<bool>(json, r'notify')!,
        createdAt: mapDateTime(json, r'created_at', r'')!,
      );
    }
    return null;
  }

  static List<SavedSearch> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SavedSearch>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SavedSearch.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SavedSearch> mapFromJson(dynamic json) {
    final map = <String, SavedSearch>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SavedSearch.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SavedSearch-objects as value to a dart map
  static Map<String, List<SavedSearch>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SavedSearch>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SavedSearch.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'name',
    'query',
    'notify',
    'created_at',
  };
}

