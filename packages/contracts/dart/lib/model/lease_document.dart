//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class LeaseDocument {
  /// Returns a new [LeaseDocument] instance.
  LeaseDocument({
    required this.id,
    required this.kind,
    required this.version,
    required this.filename,
    required this.sha256,
    required this.url,
    required this.createdAt,
  });

  String id;

  LeaseDocumentKindEnum kind;

  int version;

  String filename;

  String sha256;

  String url;

  DateTime createdAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is LeaseDocument &&
    other.id == id &&
    other.kind == kind &&
    other.version == version &&
    other.filename == filename &&
    other.sha256 == sha256 &&
    other.url == url &&
    other.createdAt == createdAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (kind.hashCode) +
    (version.hashCode) +
    (filename.hashCode) +
    (sha256.hashCode) +
    (url.hashCode) +
    (createdAt.hashCode);

  @override
  String toString() => 'LeaseDocument[id=$id, kind=$kind, version=$version, filename=$filename, sha256=$sha256, url=$url, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'kind'] = this.kind;
      json[r'version'] = this.version;
      json[r'filename'] = this.filename;
      json[r'sha256'] = this.sha256;
      json[r'url'] = this.url;
      json[r'created_at'] = this.createdAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [LeaseDocument] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LeaseDocument? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "LeaseDocument[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "LeaseDocument[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return LeaseDocument(
        id: mapValueOfType<String>(json, r'id')!,
        kind: LeaseDocumentKindEnum.fromJson(json[r'kind'])!,
        version: mapValueOfType<int>(json, r'version')!,
        filename: mapValueOfType<String>(json, r'filename')!,
        sha256: mapValueOfType<String>(json, r'sha256')!,
        url: mapValueOfType<String>(json, r'url')!,
        createdAt: mapDateTime(json, r'created_at', r'')!,
      );
    }
    return null;
  }

  static List<LeaseDocument> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LeaseDocument>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LeaseDocument.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LeaseDocument> mapFromJson(dynamic json) {
    final map = <String, LeaseDocument>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LeaseDocument.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LeaseDocument-objects as value to a dart map
  static Map<String, List<LeaseDocument>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<LeaseDocument>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LeaseDocument.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'kind',
    'version',
    'filename',
    'sha256',
    'url',
    'created_at',
  };
}


class LeaseDocumentKindEnum {
  /// Instantiate a new enum with the provided [value].
  const LeaseDocumentKindEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const draft = LeaseDocumentKindEnum._(r'draft');
  static const final_ = LeaseDocumentKindEnum._(r'final');
  static const signed = LeaseDocumentKindEnum._(r'signed');
  static const scan = LeaseDocumentKindEnum._(r'scan');
  static const evidence = LeaseDocumentKindEnum._(r'evidence');

  /// List of all possible values in this [enum][LeaseDocumentKindEnum].
  static const values = <LeaseDocumentKindEnum>[
    draft,
    final_,
    signed,
    scan,
    evidence,
  ];

  static LeaseDocumentKindEnum? fromJson(dynamic value) => LeaseDocumentKindEnumTypeTransformer().decode(value);

  static List<LeaseDocumentKindEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LeaseDocumentKindEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LeaseDocumentKindEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [LeaseDocumentKindEnum] to String,
/// and [decode] dynamic data back to [LeaseDocumentKindEnum].
class LeaseDocumentKindEnumTypeTransformer {
  factory LeaseDocumentKindEnumTypeTransformer() => _instance ??= const LeaseDocumentKindEnumTypeTransformer._();

  const LeaseDocumentKindEnumTypeTransformer._();

  String encode(LeaseDocumentKindEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a LeaseDocumentKindEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  LeaseDocumentKindEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'draft': return LeaseDocumentKindEnum.draft;
        case r'final': return LeaseDocumentKindEnum.final_;
        case r'signed': return LeaseDocumentKindEnum.signed;
        case r'scan': return LeaseDocumentKindEnum.scan;
        case r'evidence': return LeaseDocumentKindEnum.evidence;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [LeaseDocumentKindEnumTypeTransformer] instance.
  static LeaseDocumentKindEnumTypeTransformer? _instance;
}


