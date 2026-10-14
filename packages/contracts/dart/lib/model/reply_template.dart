//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ReplyTemplate {
  /// Returns a new [ReplyTemplate] instance.
  ReplyTemplate({
    required this.id,
    required this.title,
    required this.body,
    required this.updatedAt,
  });

  String id;

  String title;

  String body;

  DateTime updatedAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ReplyTemplate &&
    other.id == id &&
    other.title == title &&
    other.body == body &&
    other.updatedAt == updatedAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (title.hashCode) +
    (body.hashCode) +
    (updatedAt.hashCode);

  @override
  String toString() => 'ReplyTemplate[id=$id, title=$title, body=$body, updatedAt=$updatedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'title'] = this.title;
      json[r'body'] = this.body;
      json[r'updated_at'] = this.updatedAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [ReplyTemplate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ReplyTemplate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ReplyTemplate[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ReplyTemplate[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ReplyTemplate(
        id: mapValueOfType<String>(json, r'id')!,
        title: mapValueOfType<String>(json, r'title')!,
        body: mapValueOfType<String>(json, r'body')!,
        updatedAt: mapDateTime(json, r'updated_at', r'')!,
      );
    }
    return null;
  }

  static List<ReplyTemplate> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ReplyTemplate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ReplyTemplate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ReplyTemplate> mapFromJson(dynamic json) {
    final map = <String, ReplyTemplate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ReplyTemplate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ReplyTemplate-objects as value to a dart map
  static Map<String, List<ReplyTemplate>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ReplyTemplate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ReplyTemplate.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'title',
    'body',
    'updated_at',
  };
}

