//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DecideApplicationRequest {
  /// Returns a new [DecideApplicationRequest] instance.
  DecideApplicationRequest({
    required this.action,
    this.reason,
  });

  DecideApplicationRequestActionEnum action;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  RejectReason? reason;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DecideApplicationRequest &&
    other.action == action &&
    other.reason == reason;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (action.hashCode) +
    (reason == null ? 0 : reason!.hashCode);

  @override
  String toString() => 'DecideApplicationRequest[action=$action, reason=$reason]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'action'] = this.action;
    if (this.reason != null) {
      json[r'reason'] = this.reason;
    } else {
      json[r'reason'] = null;
    }
    return json;
  }

  /// Returns a new [DecideApplicationRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DecideApplicationRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "DecideApplicationRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "DecideApplicationRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return DecideApplicationRequest(
        action: DecideApplicationRequestActionEnum.fromJson(json[r'action'])!,
        reason: RejectReason.fromJson(json[r'reason']),
      );
    }
    return null;
  }

  static List<DecideApplicationRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DecideApplicationRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DecideApplicationRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DecideApplicationRequest> mapFromJson(dynamic json) {
    final map = <String, DecideApplicationRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DecideApplicationRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DecideApplicationRequest-objects as value to a dart map
  static Map<String, List<DecideApplicationRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DecideApplicationRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DecideApplicationRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'action',
  };
}


class DecideApplicationRequestActionEnum {
  /// Instantiate a new enum with the provided [value].
  const DecideApplicationRequestActionEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const invite = DecideApplicationRequestActionEnum._(r'invite');
  static const accept = DecideApplicationRequestActionEnum._(r'accept');
  static const reject = DecideApplicationRequestActionEnum._(r'reject');

  /// List of all possible values in this [enum][DecideApplicationRequestActionEnum].
  static const values = <DecideApplicationRequestActionEnum>[
    invite,
    accept,
    reject,
  ];

  static DecideApplicationRequestActionEnum? fromJson(dynamic value) => DecideApplicationRequestActionEnumTypeTransformer().decode(value);

  static List<DecideApplicationRequestActionEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DecideApplicationRequestActionEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DecideApplicationRequestActionEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [DecideApplicationRequestActionEnum] to String,
/// and [decode] dynamic data back to [DecideApplicationRequestActionEnum].
class DecideApplicationRequestActionEnumTypeTransformer {
  factory DecideApplicationRequestActionEnumTypeTransformer() => _instance ??= const DecideApplicationRequestActionEnumTypeTransformer._();

  const DecideApplicationRequestActionEnumTypeTransformer._();

  String encode(DecideApplicationRequestActionEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a DecideApplicationRequestActionEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  DecideApplicationRequestActionEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'invite': return DecideApplicationRequestActionEnum.invite;
        case r'accept': return DecideApplicationRequestActionEnum.accept;
        case r'reject': return DecideApplicationRequestActionEnum.reject;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [DecideApplicationRequestActionEnumTypeTransformer] instance.
  static DecideApplicationRequestActionEnumTypeTransformer? _instance;
}


