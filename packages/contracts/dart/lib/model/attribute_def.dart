//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AttributeDef {
  /// Returns a new [AttributeDef] instance.
  AttributeDef({
    required this.key,
    required this.type,
    required this.group,
    required this.label,
    required this.filter,
    this.unit,
    this.min,
    this.max,
    this.appliesTo = const [],
    this.options = const [],
  });

  String key;

  AttributeDefTypeEnum type;

  String group;

  I18nText label;

  bool filter;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? unit;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? min;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? max;

  List<UnitKind> appliesTo;

  List<AttributeOption> options;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AttributeDef &&
    other.key == key &&
    other.type == type &&
    other.group == group &&
    other.label == label &&
    other.filter == filter &&
    other.unit == unit &&
    other.min == min &&
    other.max == max &&
    _deepEquality.equals(other.appliesTo, appliesTo) &&
    _deepEquality.equals(other.options, options);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (key.hashCode) +
    (type.hashCode) +
    (group.hashCode) +
    (label.hashCode) +
    (filter.hashCode) +
    (unit == null ? 0 : unit!.hashCode) +
    (min == null ? 0 : min!.hashCode) +
    (max == null ? 0 : max!.hashCode) +
    (appliesTo.hashCode) +
    (options.hashCode);

  @override
  String toString() => 'AttributeDef[key=$key, type=$type, group=$group, label=$label, filter=$filter, unit=$unit, min=$min, max=$max, appliesTo=$appliesTo, options=$options]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'key'] = this.key;
      json[r'type'] = this.type;
      json[r'group'] = this.group;
      json[r'label'] = this.label;
      json[r'filter'] = this.filter;
    if (this.unit != null) {
      json[r'unit'] = this.unit;
    } else {
      json[r'unit'] = null;
    }
    if (this.min != null) {
      json[r'min'] = this.min;
    } else {
      json[r'min'] = null;
    }
    if (this.max != null) {
      json[r'max'] = this.max;
    } else {
      json[r'max'] = null;
    }
      json[r'applies_to'] = this.appliesTo;
      json[r'options'] = this.options;
    return json;
  }

  /// Returns a new [AttributeDef] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AttributeDef? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "AttributeDef[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "AttributeDef[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return AttributeDef(
        key: mapValueOfType<String>(json, r'key')!,
        type: AttributeDefTypeEnum.fromJson(json[r'type'])!,
        group: mapValueOfType<String>(json, r'group')!,
        label: I18nText.fromJson(json[r'label'])!,
        filter: mapValueOfType<bool>(json, r'filter')!,
        unit: mapValueOfType<String>(json, r'unit'),
        min: mapValueOfType<double>(json, r'min'),
        max: mapValueOfType<double>(json, r'max'),
        appliesTo: UnitKind.listFromJson(json[r'applies_to']),
        options: AttributeOption.listFromJson(json[r'options']),
      );
    }
    return null;
  }

  static List<AttributeDef> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AttributeDef>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AttributeDef.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AttributeDef> mapFromJson(dynamic json) {
    final map = <String, AttributeDef>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AttributeDef.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AttributeDef-objects as value to a dart map
  static Map<String, List<AttributeDef>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AttributeDef>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AttributeDef.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'key',
    'type',
    'group',
    'label',
    'filter',
    'applies_to',
    'options',
  };
}


class AttributeDefTypeEnum {
  /// Instantiate a new enum with the provided [value].
  const AttributeDefTypeEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const bool_ = AttributeDefTypeEnum._(r'bool');
  static const int_ = AttributeDefTypeEnum._(r'int');
  static const range = AttributeDefTypeEnum._(r'range');
  static const enum_ = AttributeDefTypeEnum._(r'enum');
  static const set_ = AttributeDefTypeEnum._(r'set');
  static const text = AttributeDefTypeEnum._(r'text');

  /// List of all possible values in this [enum][AttributeDefTypeEnum].
  static const values = <AttributeDefTypeEnum>[
    bool_,
    int_,
    range,
    enum_,
    set_,
    text,
  ];

  static AttributeDefTypeEnum? fromJson(dynamic value) => AttributeDefTypeEnumTypeTransformer().decode(value);

  static List<AttributeDefTypeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AttributeDefTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AttributeDefTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [AttributeDefTypeEnum] to String,
/// and [decode] dynamic data back to [AttributeDefTypeEnum].
class AttributeDefTypeEnumTypeTransformer {
  factory AttributeDefTypeEnumTypeTransformer() => _instance ??= const AttributeDefTypeEnumTypeTransformer._();

  const AttributeDefTypeEnumTypeTransformer._();

  String encode(AttributeDefTypeEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a AttributeDefTypeEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  AttributeDefTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'bool': return AttributeDefTypeEnum.bool_;
        case r'int': return AttributeDefTypeEnum.int_;
        case r'range': return AttributeDefTypeEnum.range;
        case r'enum': return AttributeDefTypeEnum.enum_;
        case r'set': return AttributeDefTypeEnum.set_;
        case r'text': return AttributeDefTypeEnum.text;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [AttributeDefTypeEnumTypeTransformer] instance.
  static AttributeDefTypeEnumTypeTransformer? _instance;
}


