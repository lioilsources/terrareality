//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ListingVersionInfo {
  /// Returns a new [ListingVersionInfo] instance.
  ListingVersionInfo({
    required this.id,
    required this.version,
    required this.status,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewNote,
  });

  String id;

  int version;

  ListingVersionInfoStatusEnum status;

  DateTime submittedAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? reviewedAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? reviewNote;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ListingVersionInfo &&
    other.id == id &&
    other.version == version &&
    other.status == status &&
    other.submittedAt == submittedAt &&
    other.reviewedAt == reviewedAt &&
    other.reviewNote == reviewNote;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (version.hashCode) +
    (status.hashCode) +
    (submittedAt.hashCode) +
    (reviewedAt == null ? 0 : reviewedAt!.hashCode) +
    (reviewNote == null ? 0 : reviewNote!.hashCode);

  @override
  String toString() => 'ListingVersionInfo[id=$id, version=$version, status=$status, submittedAt=$submittedAt, reviewedAt=$reviewedAt, reviewNote=$reviewNote]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'version'] = this.version;
      json[r'status'] = this.status;
      json[r'submitted_at'] = this.submittedAt.toUtc().toIso8601String();
    if (this.reviewedAt != null) {
      json[r'reviewed_at'] = this.reviewedAt!.toUtc().toIso8601String();
    } else {
      json[r'reviewed_at'] = null;
    }
    if (this.reviewNote != null) {
      json[r'review_note'] = this.reviewNote;
    } else {
      json[r'review_note'] = null;
    }
    return json;
  }

  /// Returns a new [ListingVersionInfo] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ListingVersionInfo? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ListingVersionInfo[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ListingVersionInfo[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ListingVersionInfo(
        id: mapValueOfType<String>(json, r'id')!,
        version: mapValueOfType<int>(json, r'version')!,
        status: ListingVersionInfoStatusEnum.fromJson(json[r'status'])!,
        submittedAt: mapDateTime(json, r'submitted_at', r'')!,
        reviewedAt: mapDateTime(json, r'reviewed_at', r''),
        reviewNote: mapValueOfType<String>(json, r'review_note'),
      );
    }
    return null;
  }

  static List<ListingVersionInfo> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ListingVersionInfo>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ListingVersionInfo.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ListingVersionInfo> mapFromJson(dynamic json) {
    final map = <String, ListingVersionInfo>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ListingVersionInfo.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ListingVersionInfo-objects as value to a dart map
  static Map<String, List<ListingVersionInfo>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ListingVersionInfo>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ListingVersionInfo.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'version',
    'status',
    'submitted_at',
  };
}


class ListingVersionInfoStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const ListingVersionInfoStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const pending = ListingVersionInfoStatusEnum._(r'pending');
  static const approved = ListingVersionInfoStatusEnum._(r'approved');
  static const rejected = ListingVersionInfoStatusEnum._(r'rejected');
  static const withdrawn = ListingVersionInfoStatusEnum._(r'withdrawn');

  /// List of all possible values in this [enum][ListingVersionInfoStatusEnum].
  static const values = <ListingVersionInfoStatusEnum>[
    pending,
    approved,
    rejected,
    withdrawn,
  ];

  static ListingVersionInfoStatusEnum? fromJson(dynamic value) => ListingVersionInfoStatusEnumTypeTransformer().decode(value);

  static List<ListingVersionInfoStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ListingVersionInfoStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ListingVersionInfoStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ListingVersionInfoStatusEnum] to String,
/// and [decode] dynamic data back to [ListingVersionInfoStatusEnum].
class ListingVersionInfoStatusEnumTypeTransformer {
  factory ListingVersionInfoStatusEnumTypeTransformer() => _instance ??= const ListingVersionInfoStatusEnumTypeTransformer._();

  const ListingVersionInfoStatusEnumTypeTransformer._();

  String encode(ListingVersionInfoStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a ListingVersionInfoStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ListingVersionInfoStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'pending': return ListingVersionInfoStatusEnum.pending;
        case r'approved': return ListingVersionInfoStatusEnum.approved;
        case r'rejected': return ListingVersionInfoStatusEnum.rejected;
        case r'withdrawn': return ListingVersionInfoStatusEnum.withdrawn;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ListingVersionInfoStatusEnumTypeTransformer] instance.
  static ListingVersionInfoStatusEnumTypeTransformer? _instance;
}


