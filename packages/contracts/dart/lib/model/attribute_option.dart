//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AttributeOption {
  /// Returns a new [AttributeOption] instance.
  AttributeOption({
    required this.value,
    required this.label,
    this.source_,
  });

  String value;

  I18nText label;

  AttributeOptionSource_Enum? source_;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AttributeOption &&
    other.value == value &&
    other.label == label &&
    other.source_ == source_;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (value.hashCode) +
    (label.hashCode) +
    (source_ == null ? 0 : source_!.hashCode);

  @override
  String toString() => 'AttributeOption[value=$value, label=$label, source_=$source_]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'value'] = this.value;
      json[r'label'] = this.label;
    if (this.source_ != null) {
      json[r'source'] = this.source_;
    } else {
      json[r'source'] = null;
    }
    return json;
  }

  /// Returns a new [AttributeOption] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AttributeOption? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "AttributeOption[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "AttributeOption[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return AttributeOption(
        value: mapValueOfType<String>(json, r'value')!,
        label: I18nText.fromJson(json[r'label'])!,
        source_: AttributeOptionSource_Enum.fromJson(json[r'source']),
      );
    }
    return null;
  }

  static List<AttributeOption> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AttributeOption>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AttributeOption.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AttributeOption> mapFromJson(dynamic json) {
    final map = <String, AttributeOption>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AttributeOption.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AttributeOption-objects as value to a dart map
  static Map<String, List<AttributeOption>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AttributeOption>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AttributeOption.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'value',
    'label',
  };
}


class AttributeOptionSource_Enum {
  /// Instantiate a new enum with the provided [value].
  const AttributeOptionSource_Enum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const catalog = AttributeOptionSource_Enum._(r'catalog');
  static const ingest = AttributeOptionSource_Enum._(r'ingest');

  /// List of all possible values in this [enum][AttributeOptionSource_Enum].
  static const values = <AttributeOptionSource_Enum>[
    catalog,
    ingest,
  ];

  static AttributeOptionSource_Enum? fromJson(dynamic value) => AttributeOptionSource_EnumTypeTransformer().decode(value);

  static List<AttributeOptionSource_Enum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AttributeOptionSource_Enum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AttributeOptionSource_Enum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [AttributeOptionSource_Enum] to String,
/// and [decode] dynamic data back to [AttributeOptionSource_Enum].
class AttributeOptionSource_EnumTypeTransformer {
  factory AttributeOptionSource_EnumTypeTransformer() => _instance ??= const AttributeOptionSource_EnumTypeTransformer._();

  const AttributeOptionSource_EnumTypeTransformer._();

  String encode(AttributeOptionSource_Enum data) => data.value;

  /// Decodes a [dynamic value][data] to a AttributeOptionSource_Enum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  AttributeOptionSource_Enum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'catalog': return AttributeOptionSource_Enum.catalog;
        case r'ingest': return AttributeOptionSource_Enum.ingest;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [AttributeOptionSource_EnumTypeTransformer] instance.
  static AttributeOptionSource_EnumTypeTransformer? _instance;
}


