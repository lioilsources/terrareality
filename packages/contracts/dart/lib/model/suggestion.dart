//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Suggestion {
  /// Returns a new [Suggestion] instance.
  Suggestion({
    required this.id,
    required this.kind,
    required this.status,
    this.mediaId,
    this.payload = const {},
    this.model,
    this.error,
    required this.createdAt,
    this.decidedAt,
  });

  String id;

  SuggestionKindEnum kind;

  SuggestionStatusEnum status;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? mediaId;

  Map<String, Object> payload;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? model;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? error;

  DateTime createdAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? decidedAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Suggestion &&
    other.id == id &&
    other.kind == kind &&
    other.status == status &&
    other.mediaId == mediaId &&
    _deepEquality.equals(other.payload, payload) &&
    other.model == model &&
    other.error == error &&
    other.createdAt == createdAt &&
    other.decidedAt == decidedAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (kind.hashCode) +
    (status.hashCode) +
    (mediaId == null ? 0 : mediaId!.hashCode) +
    (payload.hashCode) +
    (model == null ? 0 : model!.hashCode) +
    (error == null ? 0 : error!.hashCode) +
    (createdAt.hashCode) +
    (decidedAt == null ? 0 : decidedAt!.hashCode);

  @override
  String toString() => 'Suggestion[id=$id, kind=$kind, status=$status, mediaId=$mediaId, payload=$payload, model=$model, error=$error, createdAt=$createdAt, decidedAt=$decidedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'kind'] = this.kind;
      json[r'status'] = this.status;
    if (this.mediaId != null) {
      json[r'media_id'] = this.mediaId;
    } else {
      json[r'media_id'] = null;
    }
      json[r'payload'] = this.payload;
    if (this.model != null) {
      json[r'model'] = this.model;
    } else {
      json[r'model'] = null;
    }
    if (this.error != null) {
      json[r'error'] = this.error;
    } else {
      json[r'error'] = null;
    }
      json[r'created_at'] = this.createdAt.toUtc().toIso8601String();
    if (this.decidedAt != null) {
      json[r'decided_at'] = this.decidedAt!.toUtc().toIso8601String();
    } else {
      json[r'decided_at'] = null;
    }
    return json;
  }

  /// Returns a new [Suggestion] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Suggestion? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "Suggestion[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "Suggestion[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Suggestion(
        id: mapValueOfType<String>(json, r'id')!,
        kind: SuggestionKindEnum.fromJson(json[r'kind'])!,
        status: SuggestionStatusEnum.fromJson(json[r'status'])!,
        mediaId: mapValueOfType<String>(json, r'media_id'),
        payload: mapCastOfType<String, Object>(json, r'payload')!,
        model: mapValueOfType<String>(json, r'model'),
        error: mapValueOfType<String>(json, r'error'),
        createdAt: mapDateTime(json, r'created_at', r'')!,
        decidedAt: mapDateTime(json, r'decided_at', r''),
      );
    }
    return null;
  }

  static List<Suggestion> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Suggestion>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Suggestion.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Suggestion> mapFromJson(dynamic json) {
    final map = <String, Suggestion>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Suggestion.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Suggestion-objects as value to a dart map
  static Map<String, List<Suggestion>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Suggestion>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Suggestion.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'kind',
    'status',
    'payload',
    'created_at',
  };
}


class SuggestionKindEnum {
  /// Instantiate a new enum with the provided [value].
  const SuggestionKindEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const attributes = SuggestionKindEnum._(r'attributes');
  static const text = SuggestionKindEnum._(r'text');
  static const photoTags = SuggestionKindEnum._(r'photo_tags');
  static const privacyBlur = SuggestionKindEnum._(r'privacy_blur');

  /// List of all possible values in this [enum][SuggestionKindEnum].
  static const values = <SuggestionKindEnum>[
    attributes,
    text,
    photoTags,
    privacyBlur,
  ];

  static SuggestionKindEnum? fromJson(dynamic value) => SuggestionKindEnumTypeTransformer().decode(value);

  static List<SuggestionKindEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SuggestionKindEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SuggestionKindEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [SuggestionKindEnum] to String,
/// and [decode] dynamic data back to [SuggestionKindEnum].
class SuggestionKindEnumTypeTransformer {
  factory SuggestionKindEnumTypeTransformer() => _instance ??= const SuggestionKindEnumTypeTransformer._();

  const SuggestionKindEnumTypeTransformer._();

  String encode(SuggestionKindEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a SuggestionKindEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  SuggestionKindEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'attributes': return SuggestionKindEnum.attributes;
        case r'text': return SuggestionKindEnum.text;
        case r'photo_tags': return SuggestionKindEnum.photoTags;
        case r'privacy_blur': return SuggestionKindEnum.privacyBlur;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [SuggestionKindEnumTypeTransformer] instance.
  static SuggestionKindEnumTypeTransformer? _instance;
}



class SuggestionStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const SuggestionStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const generating = SuggestionStatusEnum._(r'generating');
  static const pending = SuggestionStatusEnum._(r'pending');
  static const accepted = SuggestionStatusEnum._(r'accepted');
  static const partiallyAccepted = SuggestionStatusEnum._(r'partially_accepted');
  static const rejected = SuggestionStatusEnum._(r'rejected');
  static const failed = SuggestionStatusEnum._(r'failed');

  /// List of all possible values in this [enum][SuggestionStatusEnum].
  static const values = <SuggestionStatusEnum>[
    generating,
    pending,
    accepted,
    partiallyAccepted,
    rejected,
    failed,
  ];

  static SuggestionStatusEnum? fromJson(dynamic value) => SuggestionStatusEnumTypeTransformer().decode(value);

  static List<SuggestionStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SuggestionStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SuggestionStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [SuggestionStatusEnum] to String,
/// and [decode] dynamic data back to [SuggestionStatusEnum].
class SuggestionStatusEnumTypeTransformer {
  factory SuggestionStatusEnumTypeTransformer() => _instance ??= const SuggestionStatusEnumTypeTransformer._();

  const SuggestionStatusEnumTypeTransformer._();

  String encode(SuggestionStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a SuggestionStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  SuggestionStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'generating': return SuggestionStatusEnum.generating;
        case r'pending': return SuggestionStatusEnum.pending;
        case r'accepted': return SuggestionStatusEnum.accepted;
        case r'partially_accepted': return SuggestionStatusEnum.partiallyAccepted;
        case r'rejected': return SuggestionStatusEnum.rejected;
        case r'failed': return SuggestionStatusEnum.failed;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [SuggestionStatusEnumTypeTransformer] instance.
  static SuggestionStatusEnumTypeTransformer? _instance;
}


