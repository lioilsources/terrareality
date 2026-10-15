//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AttributeSuggestion {
  /// Returns a new [AttributeSuggestion] instance.
  AttributeSuggestion({
    required this.id,
    required this.key,
    required this.type,
    required this.groupKey,
    required this.label,
    this.options = const [],
    this.exampleListingId,
    required this.occurrences,
    this.model,
    required this.status,
    this.note,
    this.decidedAt,
    required this.createdAt,
  });

  String id;

  String key;

  AttributeSuggestionTypeEnum type;

  String groupKey;

  I18nText label;

  List<AttributeSuggestionOptionsInner> options;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? exampleListingId;

  int occurrences;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? model;

  AttributeSuggestionStatusEnum status;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? note;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? decidedAt;

  DateTime createdAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AttributeSuggestion &&
    other.id == id &&
    other.key == key &&
    other.type == type &&
    other.groupKey == groupKey &&
    other.label == label &&
    _deepEquality.equals(other.options, options) &&
    other.exampleListingId == exampleListingId &&
    other.occurrences == occurrences &&
    other.model == model &&
    other.status == status &&
    other.note == note &&
    other.decidedAt == decidedAt &&
    other.createdAt == createdAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (key.hashCode) +
    (type.hashCode) +
    (groupKey.hashCode) +
    (label.hashCode) +
    (options.hashCode) +
    (exampleListingId == null ? 0 : exampleListingId!.hashCode) +
    (occurrences.hashCode) +
    (model == null ? 0 : model!.hashCode) +
    (status.hashCode) +
    (note == null ? 0 : note!.hashCode) +
    (decidedAt == null ? 0 : decidedAt!.hashCode) +
    (createdAt.hashCode);

  @override
  String toString() => 'AttributeSuggestion[id=$id, key=$key, type=$type, groupKey=$groupKey, label=$label, options=$options, exampleListingId=$exampleListingId, occurrences=$occurrences, model=$model, status=$status, note=$note, decidedAt=$decidedAt, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'key'] = this.key;
      json[r'type'] = this.type;
      json[r'group_key'] = this.groupKey;
      json[r'label'] = this.label;
      json[r'options'] = this.options;
    if (this.exampleListingId != null) {
      json[r'example_listing_id'] = this.exampleListingId;
    } else {
      json[r'example_listing_id'] = null;
    }
      json[r'occurrences'] = this.occurrences;
    if (this.model != null) {
      json[r'model'] = this.model;
    } else {
      json[r'model'] = null;
    }
      json[r'status'] = this.status;
    if (this.note != null) {
      json[r'note'] = this.note;
    } else {
      json[r'note'] = null;
    }
    if (this.decidedAt != null) {
      json[r'decided_at'] = this.decidedAt!.toUtc().toIso8601String();
    } else {
      json[r'decided_at'] = null;
    }
      json[r'created_at'] = this.createdAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [AttributeSuggestion] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AttributeSuggestion? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "AttributeSuggestion[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "AttributeSuggestion[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return AttributeSuggestion(
        id: mapValueOfType<String>(json, r'id')!,
        key: mapValueOfType<String>(json, r'key')!,
        type: AttributeSuggestionTypeEnum.fromJson(json[r'type'])!,
        groupKey: mapValueOfType<String>(json, r'group_key')!,
        label: I18nText.fromJson(json[r'label'])!,
        options: AttributeSuggestionOptionsInner.listFromJson(json[r'options']),
        exampleListingId: mapValueOfType<String>(json, r'example_listing_id'),
        occurrences: mapValueOfType<int>(json, r'occurrences')!,
        model: mapValueOfType<String>(json, r'model'),
        status: AttributeSuggestionStatusEnum.fromJson(json[r'status'])!,
        note: mapValueOfType<String>(json, r'note'),
        decidedAt: mapDateTime(json, r'decided_at', r''),
        createdAt: mapDateTime(json, r'created_at', r'')!,
      );
    }
    return null;
  }

  static List<AttributeSuggestion> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AttributeSuggestion>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AttributeSuggestion.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AttributeSuggestion> mapFromJson(dynamic json) {
    final map = <String, AttributeSuggestion>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AttributeSuggestion.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AttributeSuggestion-objects as value to a dart map
  static Map<String, List<AttributeSuggestion>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AttributeSuggestion>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AttributeSuggestion.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'key',
    'type',
    'group_key',
    'label',
    'options',
    'occurrences',
    'status',
    'created_at',
  };
}


class AttributeSuggestionTypeEnum {
  /// Instantiate a new enum with the provided [value].
  const AttributeSuggestionTypeEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const bool_ = AttributeSuggestionTypeEnum._(r'bool');
  static const int_ = AttributeSuggestionTypeEnum._(r'int');
  static const range = AttributeSuggestionTypeEnum._(r'range');
  static const enum_ = AttributeSuggestionTypeEnum._(r'enum');
  static const set_ = AttributeSuggestionTypeEnum._(r'set');
  static const text = AttributeSuggestionTypeEnum._(r'text');

  /// List of all possible values in this [enum][AttributeSuggestionTypeEnum].
  static const values = <AttributeSuggestionTypeEnum>[
    bool_,
    int_,
    range,
    enum_,
    set_,
    text,
  ];

  static AttributeSuggestionTypeEnum? fromJson(dynamic value) => AttributeSuggestionTypeEnumTypeTransformer().decode(value);

  static List<AttributeSuggestionTypeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AttributeSuggestionTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AttributeSuggestionTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [AttributeSuggestionTypeEnum] to String,
/// and [decode] dynamic data back to [AttributeSuggestionTypeEnum].
class AttributeSuggestionTypeEnumTypeTransformer {
  factory AttributeSuggestionTypeEnumTypeTransformer() => _instance ??= const AttributeSuggestionTypeEnumTypeTransformer._();

  const AttributeSuggestionTypeEnumTypeTransformer._();

  String encode(AttributeSuggestionTypeEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a AttributeSuggestionTypeEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  AttributeSuggestionTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'bool': return AttributeSuggestionTypeEnum.bool_;
        case r'int': return AttributeSuggestionTypeEnum.int_;
        case r'range': return AttributeSuggestionTypeEnum.range;
        case r'enum': return AttributeSuggestionTypeEnum.enum_;
        case r'set': return AttributeSuggestionTypeEnum.set_;
        case r'text': return AttributeSuggestionTypeEnum.text;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [AttributeSuggestionTypeEnumTypeTransformer] instance.
  static AttributeSuggestionTypeEnumTypeTransformer? _instance;
}



class AttributeSuggestionStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const AttributeSuggestionStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const open = AttributeSuggestionStatusEnum._(r'open');
  static const approved = AttributeSuggestionStatusEnum._(r'approved');
  static const rejected = AttributeSuggestionStatusEnum._(r'rejected');

  /// List of all possible values in this [enum][AttributeSuggestionStatusEnum].
  static const values = <AttributeSuggestionStatusEnum>[
    open,
    approved,
    rejected,
  ];

  static AttributeSuggestionStatusEnum? fromJson(dynamic value) => AttributeSuggestionStatusEnumTypeTransformer().decode(value);

  static List<AttributeSuggestionStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AttributeSuggestionStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AttributeSuggestionStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [AttributeSuggestionStatusEnum] to String,
/// and [decode] dynamic data back to [AttributeSuggestionStatusEnum].
class AttributeSuggestionStatusEnumTypeTransformer {
  factory AttributeSuggestionStatusEnumTypeTransformer() => _instance ??= const AttributeSuggestionStatusEnumTypeTransformer._();

  const AttributeSuggestionStatusEnumTypeTransformer._();

  String encode(AttributeSuggestionStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a AttributeSuggestionStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  AttributeSuggestionStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'open': return AttributeSuggestionStatusEnum.open;
        case r'approved': return AttributeSuggestionStatusEnum.approved;
        case r'rejected': return AttributeSuggestionStatusEnum.rejected;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [AttributeSuggestionStatusEnumTypeTransformer] instance.
  static AttributeSuggestionStatusEnumTypeTransformer? _instance;
}


