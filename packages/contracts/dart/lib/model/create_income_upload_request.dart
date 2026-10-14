//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CreateIncomeUploadRequest {
  /// Returns a new [CreateIncomeUploadRequest] instance.
  CreateIncomeUploadRequest({
    required this.contentType,
    required this.sizeBytes,
  });

  CreateIncomeUploadRequestContentTypeEnum contentType;

  /// Minimum value: 1
  /// Maximum value: 10485760
  int sizeBytes;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CreateIncomeUploadRequest &&
    other.contentType == contentType &&
    other.sizeBytes == sizeBytes;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (contentType.hashCode) +
    (sizeBytes.hashCode);

  @override
  String toString() => 'CreateIncomeUploadRequest[contentType=$contentType, sizeBytes=$sizeBytes]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'content_type'] = this.contentType;
      json[r'size_bytes'] = this.sizeBytes;
    return json;
  }

  /// Returns a new [CreateIncomeUploadRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CreateIncomeUploadRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "CreateIncomeUploadRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "CreateIncomeUploadRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return CreateIncomeUploadRequest(
        contentType: CreateIncomeUploadRequestContentTypeEnum.fromJson(json[r'content_type'])!,
        sizeBytes: mapValueOfType<int>(json, r'size_bytes')!,
      );
    }
    return null;
  }

  static List<CreateIncomeUploadRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CreateIncomeUploadRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreateIncomeUploadRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CreateIncomeUploadRequest> mapFromJson(dynamic json) {
    final map = <String, CreateIncomeUploadRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CreateIncomeUploadRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CreateIncomeUploadRequest-objects as value to a dart map
  static Map<String, List<CreateIncomeUploadRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CreateIncomeUploadRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CreateIncomeUploadRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'content_type',
    'size_bytes',
  };
}


class CreateIncomeUploadRequestContentTypeEnum {
  /// Instantiate a new enum with the provided [value].
  const CreateIncomeUploadRequestContentTypeEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const applicationSlashPdf = CreateIncomeUploadRequestContentTypeEnum._(r'application/pdf');
  static const imageSlashJpeg = CreateIncomeUploadRequestContentTypeEnum._(r'image/jpeg');
  static const imageSlashPng = CreateIncomeUploadRequestContentTypeEnum._(r'image/png');

  /// List of all possible values in this [enum][CreateIncomeUploadRequestContentTypeEnum].
  static const values = <CreateIncomeUploadRequestContentTypeEnum>[
    applicationSlashPdf,
    imageSlashJpeg,
    imageSlashPng,
  ];

  static CreateIncomeUploadRequestContentTypeEnum? fromJson(dynamic value) => CreateIncomeUploadRequestContentTypeEnumTypeTransformer().decode(value);

  static List<CreateIncomeUploadRequestContentTypeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CreateIncomeUploadRequestContentTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreateIncomeUploadRequestContentTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [CreateIncomeUploadRequestContentTypeEnum] to String,
/// and [decode] dynamic data back to [CreateIncomeUploadRequestContentTypeEnum].
class CreateIncomeUploadRequestContentTypeEnumTypeTransformer {
  factory CreateIncomeUploadRequestContentTypeEnumTypeTransformer() => _instance ??= const CreateIncomeUploadRequestContentTypeEnumTypeTransformer._();

  const CreateIncomeUploadRequestContentTypeEnumTypeTransformer._();

  String encode(CreateIncomeUploadRequestContentTypeEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a CreateIncomeUploadRequestContentTypeEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  CreateIncomeUploadRequestContentTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'application/pdf': return CreateIncomeUploadRequestContentTypeEnum.applicationSlashPdf;
        case r'image/jpeg': return CreateIncomeUploadRequestContentTypeEnum.imageSlashJpeg;
        case r'image/png': return CreateIncomeUploadRequestContentTypeEnum.imageSlashPng;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [CreateIncomeUploadRequestContentTypeEnumTypeTransformer] instance.
  static CreateIncomeUploadRequestContentTypeEnumTypeTransformer? _instance;
}


