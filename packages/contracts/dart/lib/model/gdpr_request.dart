//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class GdprRequest {
  /// Returns a new [GdprRequest] instance.
  GdprRequest({
    required this.id,
    required this.kind,
    required this.status,
    required this.scheduledAt,
    this.detail,
    required this.createdAt,
    this.completedAt,
  });

  String id;

  GdprRequestKindEnum kind;

  GdprRequestStatusEnum status;

  DateTime scheduledAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? detail;

  DateTime createdAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? completedAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is GdprRequest &&
    other.id == id &&
    other.kind == kind &&
    other.status == status &&
    other.scheduledAt == scheduledAt &&
    other.detail == detail &&
    other.createdAt == createdAt &&
    other.completedAt == completedAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (kind.hashCode) +
    (status.hashCode) +
    (scheduledAt.hashCode) +
    (detail == null ? 0 : detail!.hashCode) +
    (createdAt.hashCode) +
    (completedAt == null ? 0 : completedAt!.hashCode);

  @override
  String toString() => 'GdprRequest[id=$id, kind=$kind, status=$status, scheduledAt=$scheduledAt, detail=$detail, createdAt=$createdAt, completedAt=$completedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'kind'] = this.kind;
      json[r'status'] = this.status;
      json[r'scheduled_at'] = this.scheduledAt.toUtc().toIso8601String();
    if (this.detail != null) {
      json[r'detail'] = this.detail;
    } else {
      json[r'detail'] = null;
    }
      json[r'created_at'] = this.createdAt.toUtc().toIso8601String();
    if (this.completedAt != null) {
      json[r'completed_at'] = this.completedAt!.toUtc().toIso8601String();
    } else {
      json[r'completed_at'] = null;
    }
    return json;
  }

  /// Returns a new [GdprRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GdprRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "GdprRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "GdprRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return GdprRequest(
        id: mapValueOfType<String>(json, r'id')!,
        kind: GdprRequestKindEnum.fromJson(json[r'kind'])!,
        status: GdprRequestStatusEnum.fromJson(json[r'status'])!,
        scheduledAt: mapDateTime(json, r'scheduled_at', r'')!,
        detail: mapValueOfType<String>(json, r'detail'),
        createdAt: mapDateTime(json, r'created_at', r'')!,
        completedAt: mapDateTime(json, r'completed_at', r''),
      );
    }
    return null;
  }

  static List<GdprRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <GdprRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GdprRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GdprRequest> mapFromJson(dynamic json) {
    final map = <String, GdprRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GdprRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GdprRequest-objects as value to a dart map
  static Map<String, List<GdprRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<GdprRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GdprRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'kind',
    'status',
    'scheduled_at',
    'created_at',
  };
}


class GdprRequestKindEnum {
  /// Instantiate a new enum with the provided [value].
  const GdprRequestKindEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const export_ = GdprRequestKindEnum._(r'export');
  static const erasure = GdprRequestKindEnum._(r'erasure');

  /// List of all possible values in this [enum][GdprRequestKindEnum].
  static const values = <GdprRequestKindEnum>[
    export_,
    erasure,
  ];

  static GdprRequestKindEnum? fromJson(dynamic value) => GdprRequestKindEnumTypeTransformer().decode(value);

  static List<GdprRequestKindEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <GdprRequestKindEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GdprRequestKindEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [GdprRequestKindEnum] to String,
/// and [decode] dynamic data back to [GdprRequestKindEnum].
class GdprRequestKindEnumTypeTransformer {
  factory GdprRequestKindEnumTypeTransformer() => _instance ??= const GdprRequestKindEnumTypeTransformer._();

  const GdprRequestKindEnumTypeTransformer._();

  String encode(GdprRequestKindEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a GdprRequestKindEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  GdprRequestKindEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'export': return GdprRequestKindEnum.export_;
        case r'erasure': return GdprRequestKindEnum.erasure;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [GdprRequestKindEnumTypeTransformer] instance.
  static GdprRequestKindEnumTypeTransformer? _instance;
}



class GdprRequestStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const GdprRequestStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const pending = GdprRequestStatusEnum._(r'pending');
  static const processing = GdprRequestStatusEnum._(r'processing');
  static const done = GdprRequestStatusEnum._(r'done');
  static const failed = GdprRequestStatusEnum._(r'failed');
  static const cancelled = GdprRequestStatusEnum._(r'cancelled');
  static const rejected = GdprRequestStatusEnum._(r'rejected');

  /// List of all possible values in this [enum][GdprRequestStatusEnum].
  static const values = <GdprRequestStatusEnum>[
    pending,
    processing,
    done,
    failed,
    cancelled,
    rejected,
  ];

  static GdprRequestStatusEnum? fromJson(dynamic value) => GdprRequestStatusEnumTypeTransformer().decode(value);

  static List<GdprRequestStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <GdprRequestStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GdprRequestStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [GdprRequestStatusEnum] to String,
/// and [decode] dynamic data back to [GdprRequestStatusEnum].
class GdprRequestStatusEnumTypeTransformer {
  factory GdprRequestStatusEnumTypeTransformer() => _instance ??= const GdprRequestStatusEnumTypeTransformer._();

  const GdprRequestStatusEnumTypeTransformer._();

  String encode(GdprRequestStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a GdprRequestStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  GdprRequestStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'pending': return GdprRequestStatusEnum.pending;
        case r'processing': return GdprRequestStatusEnum.processing;
        case r'done': return GdprRequestStatusEnum.done;
        case r'failed': return GdprRequestStatusEnum.failed;
        case r'cancelled': return GdprRequestStatusEnum.cancelled;
        case r'rejected': return GdprRequestStatusEnum.rejected;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [GdprRequestStatusEnumTypeTransformer] instance.
  static GdprRequestStatusEnumTypeTransformer? _instance;
}


