//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ChatRequest {
  /// Returns a new [ChatRequest] instance.
  ChatRequest({
    required this.message,
    this.query,
    this.locale,
  });

  String message;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  SearchQuery? query;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  UserLocale? locale;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ChatRequest &&
    other.message == message &&
    other.query == query &&
    other.locale == locale;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (message.hashCode) +
    (query == null ? 0 : query!.hashCode) +
    (locale == null ? 0 : locale!.hashCode);

  @override
  String toString() => 'ChatRequest[message=$message, query=$query, locale=$locale]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'message'] = this.message;
    if (this.query != null) {
      json[r'query'] = this.query;
    } else {
      json[r'query'] = null;
    }
    if (this.locale != null) {
      json[r'locale'] = this.locale;
    } else {
      json[r'locale'] = null;
    }
    return json;
  }

  /// Returns a new [ChatRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ChatRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ChatRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ChatRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ChatRequest(
        message: mapValueOfType<String>(json, r'message')!,
        query: SearchQuery.fromJson(json[r'query']),
        locale: UserLocale.fromJson(json[r'locale']),
      );
    }
    return null;
  }

  static List<ChatRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ChatRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ChatRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ChatRequest> mapFromJson(dynamic json) {
    final map = <String, ChatRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ChatRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ChatRequest-objects as value to a dart map
  static Map<String, List<ChatRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ChatRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ChatRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'message',
  };
}

