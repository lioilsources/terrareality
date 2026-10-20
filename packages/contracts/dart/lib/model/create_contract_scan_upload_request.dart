//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CreateContractScanUploadRequest {
  /// Returns a new [CreateContractScanUploadRequest] instance.
  CreateContractScanUploadRequest({
    required this.contentType,
    required this.sizeBytes,
  });

  CreateContractScanUploadRequestContentTypeEnum contentType;

  /// Minimum value: 1
  /// Maximum value: 20971520
  int sizeBytes;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CreateContractScanUploadRequest &&
    other.contentType == contentType &&
    other.sizeBytes == sizeBytes;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (contentType.hashCode) +
    (sizeBytes.hashCode);

  @override
  String toString() => 'CreateContractScanUploadRequest[contentType=$contentType, sizeBytes=$sizeBytes]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'content_type'] = this.contentType;
      json[r'size_bytes'] = this.sizeBytes;
    return json;
  }

  /// Returns a new [CreateContractScanUploadRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CreateContractScanUploadRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "CreateContractScanUploadRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "CreateContractScanUploadRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return CreateContractScanUploadRequest(
        contentType: CreateContractScanUploadRequestContentTypeEnum.fromJson(json[r'content_type'])!,
        sizeBytes: mapValueOfType<int>(json, r'size_bytes')!,
      );
    }
    return null;
  }

  static List<CreateContractScanUploadRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CreateContractScanUploadRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreateContractScanUploadRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CreateContractScanUploadRequest> mapFromJson(dynamic json) {
    final map = <String, CreateContractScanUploadRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CreateContractScanUploadRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CreateContractScanUploadRequest-objects as value to a dart map
  static Map<String, List<CreateContractScanUploadRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CreateContractScanUploadRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CreateContractScanUploadRequest.listFromJson(entry.value, growable: growable,);
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


class CreateContractScanUploadRequestContentTypeEnum {
  /// Instantiate a new enum with the provided [value].
  const CreateContractScanUploadRequestContentTypeEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const applicationSlashPdf = CreateContractScanUploadRequestContentTypeEnum._(r'application/pdf');
  static const imageSlashJpeg = CreateContractScanUploadRequestContentTypeEnum._(r'image/jpeg');
  static const imageSlashPng = CreateContractScanUploadRequestContentTypeEnum._(r'image/png');

  /// List of all possible values in this [enum][CreateContractScanUploadRequestContentTypeEnum].
  static const values = <CreateContractScanUploadRequestContentTypeEnum>[
    applicationSlashPdf,
    imageSlashJpeg,
    imageSlashPng,
  ];

  static CreateContractScanUploadRequestContentTypeEnum? fromJson(dynamic value) => CreateContractScanUploadRequestContentTypeEnumTypeTransformer().decode(value);

  static List<CreateContractScanUploadRequestContentTypeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CreateContractScanUploadRequestContentTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreateContractScanUploadRequestContentTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [CreateContractScanUploadRequestContentTypeEnum] to String,
/// and [decode] dynamic data back to [CreateContractScanUploadRequestContentTypeEnum].
class CreateContractScanUploadRequestContentTypeEnumTypeTransformer {
  factory CreateContractScanUploadRequestContentTypeEnumTypeTransformer() => _instance ??= const CreateContractScanUploadRequestContentTypeEnumTypeTransformer._();

  const CreateContractScanUploadRequestContentTypeEnumTypeTransformer._();

  String encode(CreateContractScanUploadRequestContentTypeEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a CreateContractScanUploadRequestContentTypeEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  CreateContractScanUploadRequestContentTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'application/pdf': return CreateContractScanUploadRequestContentTypeEnum.applicationSlashPdf;
        case r'image/jpeg': return CreateContractScanUploadRequestContentTypeEnum.imageSlashJpeg;
        case r'image/png': return CreateContractScanUploadRequestContentTypeEnum.imageSlashPng;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [CreateContractScanUploadRequestContentTypeEnumTypeTransformer] instance.
  static CreateContractScanUploadRequestContentTypeEnumTypeTransformer? _instance;
}


