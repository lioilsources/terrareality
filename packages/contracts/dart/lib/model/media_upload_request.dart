//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class MediaUploadRequest {
  /// Returns a new [MediaUploadRequest] instance.
  MediaUploadRequest({
    required this.filename,
    required this.contentType,
    required this.size,
  });

  String filename;

  MediaUploadRequestContentTypeEnum contentType;

  /// Minimum value: 1
  /// Maximum value: 20971520
  int size;

  @override
  bool operator ==(Object other) => identical(this, other) || other is MediaUploadRequest &&
    other.filename == filename &&
    other.contentType == contentType &&
    other.size == size;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (filename.hashCode) +
    (contentType.hashCode) +
    (size.hashCode);

  @override
  String toString() => 'MediaUploadRequest[filename=$filename, contentType=$contentType, size=$size]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'filename'] = this.filename;
      json[r'content_type'] = this.contentType;
      json[r'size'] = this.size;
    return json;
  }

  /// Returns a new [MediaUploadRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MediaUploadRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "MediaUploadRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "MediaUploadRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return MediaUploadRequest(
        filename: mapValueOfType<String>(json, r'filename')!,
        contentType: MediaUploadRequestContentTypeEnum.fromJson(json[r'content_type'])!,
        size: mapValueOfType<int>(json, r'size')!,
      );
    }
    return null;
  }

  static List<MediaUploadRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MediaUploadRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MediaUploadRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MediaUploadRequest> mapFromJson(dynamic json) {
    final map = <String, MediaUploadRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MediaUploadRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MediaUploadRequest-objects as value to a dart map
  static Map<String, List<MediaUploadRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<MediaUploadRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MediaUploadRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'filename',
    'content_type',
    'size',
  };
}


class MediaUploadRequestContentTypeEnum {
  /// Instantiate a new enum with the provided [value].
  const MediaUploadRequestContentTypeEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const imageSlashJpeg = MediaUploadRequestContentTypeEnum._(r'image/jpeg');
  static const imageSlashPng = MediaUploadRequestContentTypeEnum._(r'image/png');
  static const imageSlashWebp = MediaUploadRequestContentTypeEnum._(r'image/webp');

  /// List of all possible values in this [enum][MediaUploadRequestContentTypeEnum].
  static const values = <MediaUploadRequestContentTypeEnum>[
    imageSlashJpeg,
    imageSlashPng,
    imageSlashWebp,
  ];

  static MediaUploadRequestContentTypeEnum? fromJson(dynamic value) => MediaUploadRequestContentTypeEnumTypeTransformer().decode(value);

  static List<MediaUploadRequestContentTypeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MediaUploadRequestContentTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MediaUploadRequestContentTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [MediaUploadRequestContentTypeEnum] to String,
/// and [decode] dynamic data back to [MediaUploadRequestContentTypeEnum].
class MediaUploadRequestContentTypeEnumTypeTransformer {
  factory MediaUploadRequestContentTypeEnumTypeTransformer() => _instance ??= const MediaUploadRequestContentTypeEnumTypeTransformer._();

  const MediaUploadRequestContentTypeEnumTypeTransformer._();

  String encode(MediaUploadRequestContentTypeEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a MediaUploadRequestContentTypeEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  MediaUploadRequestContentTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'image/jpeg': return MediaUploadRequestContentTypeEnum.imageSlashJpeg;
        case r'image/png': return MediaUploadRequestContentTypeEnum.imageSlashPng;
        case r'image/webp': return MediaUploadRequestContentTypeEnum.imageSlashWebp;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [MediaUploadRequestContentTypeEnumTypeTransformer] instance.
  static MediaUploadRequestContentTypeEnumTypeTransformer? _instance;
}


