//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class RequestSuggestionRequest {
  /// Returns a new [RequestSuggestionRequest] instance.
  RequestSuggestionRequest({
    required this.kind,
  });

  RequestSuggestionRequestKindEnum kind;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RequestSuggestionRequest &&
    other.kind == kind;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (kind.hashCode);

  @override
  String toString() => 'RequestSuggestionRequest[kind=$kind]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'kind'] = this.kind;
    return json;
  }

  /// Returns a new [RequestSuggestionRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RequestSuggestionRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "RequestSuggestionRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "RequestSuggestionRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return RequestSuggestionRequest(
        kind: RequestSuggestionRequestKindEnum.fromJson(json[r'kind'])!,
      );
    }
    return null;
  }

  static List<RequestSuggestionRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RequestSuggestionRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RequestSuggestionRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RequestSuggestionRequest> mapFromJson(dynamic json) {
    final map = <String, RequestSuggestionRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RequestSuggestionRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RequestSuggestionRequest-objects as value to a dart map
  static Map<String, List<RequestSuggestionRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RequestSuggestionRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RequestSuggestionRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'kind',
  };
}


class RequestSuggestionRequestKindEnum {
  /// Instantiate a new enum with the provided [value].
  const RequestSuggestionRequestKindEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const attributes = RequestSuggestionRequestKindEnum._(r'attributes');
  static const text = RequestSuggestionRequestKindEnum._(r'text');

  /// List of all possible values in this [enum][RequestSuggestionRequestKindEnum].
  static const values = <RequestSuggestionRequestKindEnum>[
    attributes,
    text,
  ];

  static RequestSuggestionRequestKindEnum? fromJson(dynamic value) => RequestSuggestionRequestKindEnumTypeTransformer().decode(value);

  static List<RequestSuggestionRequestKindEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RequestSuggestionRequestKindEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RequestSuggestionRequestKindEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [RequestSuggestionRequestKindEnum] to String,
/// and [decode] dynamic data back to [RequestSuggestionRequestKindEnum].
class RequestSuggestionRequestKindEnumTypeTransformer {
  factory RequestSuggestionRequestKindEnumTypeTransformer() => _instance ??= const RequestSuggestionRequestKindEnumTypeTransformer._();

  const RequestSuggestionRequestKindEnumTypeTransformer._();

  String encode(RequestSuggestionRequestKindEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a RequestSuggestionRequestKindEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  RequestSuggestionRequestKindEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'attributes': return RequestSuggestionRequestKindEnum.attributes;
        case r'text': return RequestSuggestionRequestKindEnum.text;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [RequestSuggestionRequestKindEnumTypeTransformer] instance.
  static RequestSuggestionRequestKindEnumTypeTransformer? _instance;
}


