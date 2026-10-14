//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PushDevice {
  /// Returns a new [PushDevice] instance.
  PushDevice({
    required this.id,
    required this.platform,
    required this.label,
    required this.createdAt,
    required this.lastSeenAt,
  });

  String id;

  PushDevicePlatformEnum platform;

  String label;

  DateTime createdAt;

  DateTime lastSeenAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PushDevice &&
    other.id == id &&
    other.platform == platform &&
    other.label == label &&
    other.createdAt == createdAt &&
    other.lastSeenAt == lastSeenAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (platform.hashCode) +
    (label.hashCode) +
    (createdAt.hashCode) +
    (lastSeenAt.hashCode);

  @override
  String toString() => 'PushDevice[id=$id, platform=$platform, label=$label, createdAt=$createdAt, lastSeenAt=$lastSeenAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'platform'] = this.platform;
      json[r'label'] = this.label;
      json[r'created_at'] = this.createdAt.toUtc().toIso8601String();
      json[r'last_seen_at'] = this.lastSeenAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [PushDevice] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PushDevice? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PushDevice[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PushDevice[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PushDevice(
        id: mapValueOfType<String>(json, r'id')!,
        platform: PushDevicePlatformEnum.fromJson(json[r'platform'])!,
        label: mapValueOfType<String>(json, r'label')!,
        createdAt: mapDateTime(json, r'created_at', r'')!,
        lastSeenAt: mapDateTime(json, r'last_seen_at', r'')!,
      );
    }
    return null;
  }

  static List<PushDevice> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PushDevice>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PushDevice.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PushDevice> mapFromJson(dynamic json) {
    final map = <String, PushDevice>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PushDevice.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PushDevice-objects as value to a dart map
  static Map<String, List<PushDevice>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PushDevice>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PushDevice.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'platform',
    'label',
    'created_at',
    'last_seen_at',
  };
}


class PushDevicePlatformEnum {
  /// Instantiate a new enum with the provided [value].
  const PushDevicePlatformEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const fcm = PushDevicePlatformEnum._(r'fcm');
  static const apns = PushDevicePlatformEnum._(r'apns');
  static const webpush = PushDevicePlatformEnum._(r'webpush');

  /// List of all possible values in this [enum][PushDevicePlatformEnum].
  static const values = <PushDevicePlatformEnum>[
    fcm,
    apns,
    webpush,
  ];

  static PushDevicePlatformEnum? fromJson(dynamic value) => PushDevicePlatformEnumTypeTransformer().decode(value);

  static List<PushDevicePlatformEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PushDevicePlatformEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PushDevicePlatformEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [PushDevicePlatformEnum] to String,
/// and [decode] dynamic data back to [PushDevicePlatformEnum].
class PushDevicePlatformEnumTypeTransformer {
  factory PushDevicePlatformEnumTypeTransformer() => _instance ??= const PushDevicePlatformEnumTypeTransformer._();

  const PushDevicePlatformEnumTypeTransformer._();

  String encode(PushDevicePlatformEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a PushDevicePlatformEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  PushDevicePlatformEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'fcm': return PushDevicePlatformEnum.fcm;
        case r'apns': return PushDevicePlatformEnum.apns;
        case r'webpush': return PushDevicePlatformEnum.webpush;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [PushDevicePlatformEnumTypeTransformer] instance.
  static PushDevicePlatformEnumTypeTransformer? _instance;
}


