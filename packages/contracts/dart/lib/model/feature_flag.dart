//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class FeatureFlag {
  /// Returns a new [FeatureFlag] instance.
  FeatureFlag({
    required this.key,
    required this.enabled,
    required this.description,
    required this.source_,
    this.updatedAt,
  });

  String key;

  bool enabled;

  String description;

  FeatureFlagSource_Enum source_;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? updatedAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is FeatureFlag &&
    other.key == key &&
    other.enabled == enabled &&
    other.description == description &&
    other.source_ == source_ &&
    other.updatedAt == updatedAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (key.hashCode) +
    (enabled.hashCode) +
    (description.hashCode) +
    (source_.hashCode) +
    (updatedAt == null ? 0 : updatedAt!.hashCode);

  @override
  String toString() => 'FeatureFlag[key=$key, enabled=$enabled, description=$description, source_=$source_, updatedAt=$updatedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'key'] = this.key;
      json[r'enabled'] = this.enabled;
      json[r'description'] = this.description;
      json[r'source'] = this.source_;
    if (this.updatedAt != null) {
      json[r'updated_at'] = this.updatedAt!.toUtc().toIso8601String();
    } else {
      json[r'updated_at'] = null;
    }
    return json;
  }

  /// Returns a new [FeatureFlag] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static FeatureFlag? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "FeatureFlag[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "FeatureFlag[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return FeatureFlag(
        key: mapValueOfType<String>(json, r'key')!,
        enabled: mapValueOfType<bool>(json, r'enabled')!,
        description: mapValueOfType<String>(json, r'description')!,
        source_: FeatureFlagSource_Enum.fromJson(json[r'source'])!,
        updatedAt: mapDateTime(json, r'updated_at', r''),
      );
    }
    return null;
  }

  static List<FeatureFlag> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <FeatureFlag>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = FeatureFlag.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, FeatureFlag> mapFromJson(dynamic json) {
    final map = <String, FeatureFlag>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = FeatureFlag.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of FeatureFlag-objects as value to a dart map
  static Map<String, List<FeatureFlag>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<FeatureFlag>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = FeatureFlag.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'key',
    'enabled',
    'description',
    'source',
  };
}


class FeatureFlagSource_Enum {
  /// Instantiate a new enum with the provided [value].
  const FeatureFlagSource_Enum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const db = FeatureFlagSource_Enum._(r'db');
  static const default_ = FeatureFlagSource_Enum._(r'default');

  /// List of all possible values in this [enum][FeatureFlagSource_Enum].
  static const values = <FeatureFlagSource_Enum>[
    db,
    default_,
  ];

  static FeatureFlagSource_Enum? fromJson(dynamic value) => FeatureFlagSource_EnumTypeTransformer().decode(value);

  static List<FeatureFlagSource_Enum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <FeatureFlagSource_Enum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = FeatureFlagSource_Enum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [FeatureFlagSource_Enum] to String,
/// and [decode] dynamic data back to [FeatureFlagSource_Enum].
class FeatureFlagSource_EnumTypeTransformer {
  factory FeatureFlagSource_EnumTypeTransformer() => _instance ??= const FeatureFlagSource_EnumTypeTransformer._();

  const FeatureFlagSource_EnumTypeTransformer._();

  String encode(FeatureFlagSource_Enum data) => data.value;

  /// Decodes a [dynamic value][data] to a FeatureFlagSource_Enum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  FeatureFlagSource_Enum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'db': return FeatureFlagSource_Enum.db;
        case r'default': return FeatureFlagSource_Enum.default_;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [FeatureFlagSource_EnumTypeTransformer] instance.
  static FeatureFlagSource_EnumTypeTransformer? _instance;
}


