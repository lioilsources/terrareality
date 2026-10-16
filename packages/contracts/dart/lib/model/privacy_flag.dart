//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PrivacyFlag {
  /// Returns a new [PrivacyFlag] instance.
  PrivacyFlag({
    required this.mediaId,
    required this.status,
  });

  String mediaId;

  /// Status of the privacy_blur suggestion.
  PrivacyFlagStatusEnum status;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PrivacyFlag &&
    other.mediaId == mediaId &&
    other.status == status;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (mediaId.hashCode) +
    (status.hashCode);

  @override
  String toString() => 'PrivacyFlag[mediaId=$mediaId, status=$status]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'media_id'] = this.mediaId;
      json[r'status'] = this.status;
    return json;
  }

  /// Returns a new [PrivacyFlag] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PrivacyFlag? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PrivacyFlag[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PrivacyFlag[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PrivacyFlag(
        mediaId: mapValueOfType<String>(json, r'media_id')!,
        status: PrivacyFlagStatusEnum.fromJson(json[r'status'])!,
      );
    }
    return null;
  }

  static List<PrivacyFlag> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PrivacyFlag>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PrivacyFlag.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PrivacyFlag> mapFromJson(dynamic json) {
    final map = <String, PrivacyFlag>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PrivacyFlag.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PrivacyFlag-objects as value to a dart map
  static Map<String, List<PrivacyFlag>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PrivacyFlag>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PrivacyFlag.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'media_id',
    'status',
  };
}

/// Status of the privacy_blur suggestion.
class PrivacyFlagStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const PrivacyFlagStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const generating = PrivacyFlagStatusEnum._(r'generating');
  static const pending = PrivacyFlagStatusEnum._(r'pending');
  static const rejected = PrivacyFlagStatusEnum._(r'rejected');
  static const failed = PrivacyFlagStatusEnum._(r'failed');

  /// List of all possible values in this [enum][PrivacyFlagStatusEnum].
  static const values = <PrivacyFlagStatusEnum>[
    generating,
    pending,
    rejected,
    failed,
  ];

  static PrivacyFlagStatusEnum? fromJson(dynamic value) => PrivacyFlagStatusEnumTypeTransformer().decode(value);

  static List<PrivacyFlagStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PrivacyFlagStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PrivacyFlagStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [PrivacyFlagStatusEnum] to String,
/// and [decode] dynamic data back to [PrivacyFlagStatusEnum].
class PrivacyFlagStatusEnumTypeTransformer {
  factory PrivacyFlagStatusEnumTypeTransformer() => _instance ??= const PrivacyFlagStatusEnumTypeTransformer._();

  const PrivacyFlagStatusEnumTypeTransformer._();

  String encode(PrivacyFlagStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a PrivacyFlagStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  PrivacyFlagStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'generating': return PrivacyFlagStatusEnum.generating;
        case r'pending': return PrivacyFlagStatusEnum.pending;
        case r'rejected': return PrivacyFlagStatusEnum.rejected;
        case r'failed': return PrivacyFlagStatusEnum.failed;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [PrivacyFlagStatusEnumTypeTransformer] instance.
  static PrivacyFlagStatusEnumTypeTransformer? _instance;
}


