//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ChatResponse {
  /// Returns a new [ChatResponse] instance.
  ChatResponse({
    required this.query,
    this.place,
    required this.reply,
    required this.model,
    required this.degraded,
    required this.result,
  });

  SearchQuery query;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  Place? place;

  String reply;

  /// LLM route or \"rules\" for the offline parser.
  String model;

  /// The LLM was unavailable and rules were used.
  bool degraded;

  SearchResult result;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ChatResponse &&
    other.query == query &&
    other.place == place &&
    other.reply == reply &&
    other.model == model &&
    other.degraded == degraded &&
    other.result == result;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (query.hashCode) +
    (place == null ? 0 : place!.hashCode) +
    (reply.hashCode) +
    (model.hashCode) +
    (degraded.hashCode) +
    (result.hashCode);

  @override
  String toString() => 'ChatResponse[query=$query, place=$place, reply=$reply, model=$model, degraded=$degraded, result=$result]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'query'] = this.query;
    if (this.place != null) {
      json[r'place'] = this.place;
    } else {
      json[r'place'] = null;
    }
      json[r'reply'] = this.reply;
      json[r'model'] = this.model;
      json[r'degraded'] = this.degraded;
      json[r'result'] = this.result;
    return json;
  }

  /// Returns a new [ChatResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ChatResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ChatResponse[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ChatResponse[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ChatResponse(
        query: SearchQuery.fromJson(json[r'query'])!,
        place: Place.fromJson(json[r'place']),
        reply: mapValueOfType<String>(json, r'reply')!,
        model: mapValueOfType<String>(json, r'model')!,
        degraded: mapValueOfType<bool>(json, r'degraded')!,
        result: SearchResult.fromJson(json[r'result'])!,
      );
    }
    return null;
  }

  static List<ChatResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ChatResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ChatResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ChatResponse> mapFromJson(dynamic json) {
    final map = <String, ChatResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ChatResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ChatResponse-objects as value to a dart map
  static Map<String, List<ChatResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ChatResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ChatResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'query',
    'reply',
    'model',
    'degraded',
    'result',
  };
}

