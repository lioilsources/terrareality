//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CreateAttachmentUploadRequest {
  /// Returns a new [CreateAttachmentUploadRequest] instance.
  CreateAttachmentUploadRequest({
    required this.filename,
    required this.contentType,
    required this.sizeBytes,
  });

  String filename;

  CreateAttachmentUploadRequestContentTypeEnum contentType;

  /// Minimum value: 1
  /// Maximum value: 10485760
  int sizeBytes;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CreateAttachmentUploadRequest &&
    other.filename == filename &&
    other.contentType == contentType &&
    other.sizeBytes == sizeBytes;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (filename.hashCode) +
    (contentType.hashCode) +
    (sizeBytes.hashCode);

  @override
  String toString() => 'CreateAttachmentUploadRequest[filename=$filename, contentType=$contentType, sizeBytes=$sizeBytes]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'filename'] = this.filename;
      json[r'content_type'] = this.contentType;
      json[r'size_bytes'] = this.sizeBytes;
    return json;
  }

  /// Returns a new [CreateAttachmentUploadRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CreateAttachmentUploadRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "CreateAttachmentUploadRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "CreateAttachmentUploadRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return CreateAttachmentUploadRequest(
        filename: mapValueOfType<String>(json, r'filename')!,
        contentType: CreateAttachmentUploadRequestContentTypeEnum.fromJson(json[r'content_type'])!,
        sizeBytes: mapValueOfType<int>(json, r'size_bytes')!,
      );
    }
    return null;
  }

  static List<CreateAttachmentUploadRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CreateAttachmentUploadRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreateAttachmentUploadRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CreateAttachmentUploadRequest> mapFromJson(dynamic json) {
    final map = <String, CreateAttachmentUploadRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CreateAttachmentUploadRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CreateAttachmentUploadRequest-objects as value to a dart map
  static Map<String, List<CreateAttachmentUploadRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CreateAttachmentUploadRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CreateAttachmentUploadRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'filename',
    'content_type',
    'size_bytes',
  };
}


class CreateAttachmentUploadRequestContentTypeEnum {
  /// Instantiate a new enum with the provided [value].
  const CreateAttachmentUploadRequestContentTypeEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const imageSlashJpeg = CreateAttachmentUploadRequestContentTypeEnum._(r'image/jpeg');
  static const imageSlashPng = CreateAttachmentUploadRequestContentTypeEnum._(r'image/png');
  static const imageSlashWebp = CreateAttachmentUploadRequestContentTypeEnum._(r'image/webp');
  static const imageSlashHeic = CreateAttachmentUploadRequestContentTypeEnum._(r'image/heic');
  static const applicationSlashPdf = CreateAttachmentUploadRequestContentTypeEnum._(r'application/pdf');

  /// List of all possible values in this [enum][CreateAttachmentUploadRequestContentTypeEnum].
  static const values = <CreateAttachmentUploadRequestContentTypeEnum>[
    imageSlashJpeg,
    imageSlashPng,
    imageSlashWebp,
    imageSlashHeic,
    applicationSlashPdf,
  ];

  static CreateAttachmentUploadRequestContentTypeEnum? fromJson(dynamic value) => CreateAttachmentUploadRequestContentTypeEnumTypeTransformer().decode(value);

  static List<CreateAttachmentUploadRequestContentTypeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CreateAttachmentUploadRequestContentTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreateAttachmentUploadRequestContentTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [CreateAttachmentUploadRequestContentTypeEnum] to String,
/// and [decode] dynamic data back to [CreateAttachmentUploadRequestContentTypeEnum].
class CreateAttachmentUploadRequestContentTypeEnumTypeTransformer {
  factory CreateAttachmentUploadRequestContentTypeEnumTypeTransformer() => _instance ??= const CreateAttachmentUploadRequestContentTypeEnumTypeTransformer._();

  const CreateAttachmentUploadRequestContentTypeEnumTypeTransformer._();

  String encode(CreateAttachmentUploadRequestContentTypeEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a CreateAttachmentUploadRequestContentTypeEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  CreateAttachmentUploadRequestContentTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'image/jpeg': return CreateAttachmentUploadRequestContentTypeEnum.imageSlashJpeg;
        case r'image/png': return CreateAttachmentUploadRequestContentTypeEnum.imageSlashPng;
        case r'image/webp': return CreateAttachmentUploadRequestContentTypeEnum.imageSlashWebp;
        case r'image/heic': return CreateAttachmentUploadRequestContentTypeEnum.imageSlashHeic;
        case r'application/pdf': return CreateAttachmentUploadRequestContentTypeEnum.applicationSlashPdf;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [CreateAttachmentUploadRequestContentTypeEnumTypeTransformer] instance.
  static CreateAttachmentUploadRequestContentTypeEnumTypeTransformer? _instance;
}


