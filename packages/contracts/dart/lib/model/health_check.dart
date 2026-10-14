//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class HealthCheck {
  /// Returns a new [HealthCheck] instance.
  HealthCheck({
    required this.status,
    this.latencyMs,
    this.error,
  });

  HealthCheckStatusEnum status;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? latencyMs;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? error;

  @override
  bool operator ==(Object other) => identical(this, other) || other is HealthCheck &&
    other.status == status &&
    other.latencyMs == latencyMs &&
    other.error == error;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (status.hashCode) +
    (latencyMs == null ? 0 : latencyMs!.hashCode) +
    (error == null ? 0 : error!.hashCode);

  @override
  String toString() => 'HealthCheck[status=$status, latencyMs=$latencyMs, error=$error]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'status'] = this.status;
    if (this.latencyMs != null) {
      json[r'latency_ms'] = this.latencyMs;
    } else {
      json[r'latency_ms'] = null;
    }
    if (this.error != null) {
      json[r'error'] = this.error;
    } else {
      json[r'error'] = null;
    }
    return json;
  }

  /// Returns a new [HealthCheck] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static HealthCheck? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "HealthCheck[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "HealthCheck[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return HealthCheck(
        status: HealthCheckStatusEnum.fromJson(json[r'status'])!,
        latencyMs: mapValueOfType<int>(json, r'latency_ms'),
        error: mapValueOfType<String>(json, r'error'),
      );
    }
    return null;
  }

  static List<HealthCheck> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <HealthCheck>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = HealthCheck.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, HealthCheck> mapFromJson(dynamic json) {
    final map = <String, HealthCheck>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = HealthCheck.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of HealthCheck-objects as value to a dart map
  static Map<String, List<HealthCheck>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<HealthCheck>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = HealthCheck.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'status',
  };
}


class HealthCheckStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const HealthCheckStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const ok = HealthCheckStatusEnum._(r'ok');
  static const fail = HealthCheckStatusEnum._(r'fail');
  static const disabled = HealthCheckStatusEnum._(r'disabled');

  /// List of all possible values in this [enum][HealthCheckStatusEnum].
  static const values = <HealthCheckStatusEnum>[
    ok,
    fail,
    disabled,
  ];

  static HealthCheckStatusEnum? fromJson(dynamic value) => HealthCheckStatusEnumTypeTransformer().decode(value);

  static List<HealthCheckStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <HealthCheckStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = HealthCheckStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [HealthCheckStatusEnum] to String,
/// and [decode] dynamic data back to [HealthCheckStatusEnum].
class HealthCheckStatusEnumTypeTransformer {
  factory HealthCheckStatusEnumTypeTransformer() => _instance ??= const HealthCheckStatusEnumTypeTransformer._();

  const HealthCheckStatusEnumTypeTransformer._();

  String encode(HealthCheckStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a HealthCheckStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  HealthCheckStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'ok': return HealthCheckStatusEnum.ok;
        case r'fail': return HealthCheckStatusEnum.fail;
        case r'disabled': return HealthCheckStatusEnum.disabled;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [HealthCheckStatusEnumTypeTransformer] instance.
  static HealthCheckStatusEnumTypeTransformer? _instance;
}


