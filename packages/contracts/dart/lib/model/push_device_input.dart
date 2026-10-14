//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PushDeviceInput {
  /// Returns a new [PushDeviceInput] instance.
  PushDeviceInput({
    required this.platform,
    required this.token,
    this.keys,
    this.label,
  });

  PushDeviceInputPlatformEnum platform;

  /// FCM/APNs token or the web push endpoint URL.
  String token;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  PushDeviceInputKeys? keys;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? label;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PushDeviceInput &&
    other.platform == platform &&
    other.token == token &&
    other.keys == keys &&
    other.label == label;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (platform.hashCode) +
    (token.hashCode) +
    (keys == null ? 0 : keys!.hashCode) +
    (label == null ? 0 : label!.hashCode);

  @override
  String toString() => 'PushDeviceInput[platform=$platform, token=$token, keys=$keys, label=$label]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'platform'] = this.platform;
      json[r'token'] = this.token;
    if (this.keys != null) {
      json[r'keys'] = this.keys;
    } else {
      json[r'keys'] = null;
    }
    if (this.label != null) {
      json[r'label'] = this.label;
    } else {
      json[r'label'] = null;
    }
    return json;
  }

  /// Returns a new [PushDeviceInput] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PushDeviceInput? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PushDeviceInput[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PushDeviceInput[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PushDeviceInput(
        platform: PushDeviceInputPlatformEnum.fromJson(json[r'platform'])!,
        token: mapValueOfType<String>(json, r'token')!,
        keys: PushDeviceInputKeys.fromJson(json[r'keys']),
        label: mapValueOfType<String>(json, r'label'),
      );
    }
    return null;
  }

  static List<PushDeviceInput> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PushDeviceInput>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PushDeviceInput.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PushDeviceInput> mapFromJson(dynamic json) {
    final map = <String, PushDeviceInput>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PushDeviceInput.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PushDeviceInput-objects as value to a dart map
  static Map<String, List<PushDeviceInput>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PushDeviceInput>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PushDeviceInput.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'platform',
    'token',
  };
}


class PushDeviceInputPlatformEnum {
  /// Instantiate a new enum with the provided [value].
  const PushDeviceInputPlatformEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const fcm = PushDeviceInputPlatformEnum._(r'fcm');
  static const apns = PushDeviceInputPlatformEnum._(r'apns');
  static const webpush = PushDeviceInputPlatformEnum._(r'webpush');

  /// List of all possible values in this [enum][PushDeviceInputPlatformEnum].
  static const values = <PushDeviceInputPlatformEnum>[
    fcm,
    apns,
    webpush,
  ];

  static PushDeviceInputPlatformEnum? fromJson(dynamic value) => PushDeviceInputPlatformEnumTypeTransformer().decode(value);

  static List<PushDeviceInputPlatformEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PushDeviceInputPlatformEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PushDeviceInputPlatformEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [PushDeviceInputPlatformEnum] to String,
/// and [decode] dynamic data back to [PushDeviceInputPlatformEnum].
class PushDeviceInputPlatformEnumTypeTransformer {
  factory PushDeviceInputPlatformEnumTypeTransformer() => _instance ??= const PushDeviceInputPlatformEnumTypeTransformer._();

  const PushDeviceInputPlatformEnumTypeTransformer._();

  String encode(PushDeviceInputPlatformEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a PushDeviceInputPlatformEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  PushDeviceInputPlatformEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'fcm': return PushDeviceInputPlatformEnum.fcm;
        case r'apns': return PushDeviceInputPlatformEnum.apns;
        case r'webpush': return PushDeviceInputPlatformEnum.webpush;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [PushDeviceInputPlatformEnumTypeTransformer] instance.
  static PushDeviceInputPlatformEnumTypeTransformer? _instance;
}


