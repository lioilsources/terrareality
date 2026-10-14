//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Media {
  /// Returns a new [Media] instance.
  Media({
    required this.id,
    required this.status,
    this.rejectionReason,
    required this.filename,
    required this.contentType,
    this.width,
    this.height,
    required this.position,
    required this.caption,
    this.urls = const {},
    this.roomType,
    this.tags = const [],
  });

  String id;

  MediaStatusEnum status;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? rejectionReason;

  String filename;

  String contentType;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? width;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? height;

  int position;

  I18nText caption;

  /// Signed imgproxy URLs by variant (thumb 400px, medium 1024px, large 1920px).
  Map<String, String> urls;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? roomType;

  List<String> tags;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Media &&
    other.id == id &&
    other.status == status &&
    other.rejectionReason == rejectionReason &&
    other.filename == filename &&
    other.contentType == contentType &&
    other.width == width &&
    other.height == height &&
    other.position == position &&
    other.caption == caption &&
    _deepEquality.equals(other.urls, urls) &&
    other.roomType == roomType &&
    _deepEquality.equals(other.tags, tags);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (status.hashCode) +
    (rejectionReason == null ? 0 : rejectionReason!.hashCode) +
    (filename.hashCode) +
    (contentType.hashCode) +
    (width == null ? 0 : width!.hashCode) +
    (height == null ? 0 : height!.hashCode) +
    (position.hashCode) +
    (caption.hashCode) +
    (urls.hashCode) +
    (roomType == null ? 0 : roomType!.hashCode) +
    (tags.hashCode);

  @override
  String toString() => 'Media[id=$id, status=$status, rejectionReason=$rejectionReason, filename=$filename, contentType=$contentType, width=$width, height=$height, position=$position, caption=$caption, urls=$urls, roomType=$roomType, tags=$tags]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'status'] = this.status;
    if (this.rejectionReason != null) {
      json[r'rejection_reason'] = this.rejectionReason;
    } else {
      json[r'rejection_reason'] = null;
    }
      json[r'filename'] = this.filename;
      json[r'content_type'] = this.contentType;
    if (this.width != null) {
      json[r'width'] = this.width;
    } else {
      json[r'width'] = null;
    }
    if (this.height != null) {
      json[r'height'] = this.height;
    } else {
      json[r'height'] = null;
    }
      json[r'position'] = this.position;
      json[r'caption'] = this.caption;
      json[r'urls'] = this.urls;
    if (this.roomType != null) {
      json[r'room_type'] = this.roomType;
    } else {
      json[r'room_type'] = null;
    }
      json[r'tags'] = this.tags;
    return json;
  }

  /// Returns a new [Media] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Media? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "Media[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "Media[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Media(
        id: mapValueOfType<String>(json, r'id')!,
        status: MediaStatusEnum.fromJson(json[r'status'])!,
        rejectionReason: mapValueOfType<String>(json, r'rejection_reason'),
        filename: mapValueOfType<String>(json, r'filename')!,
        contentType: mapValueOfType<String>(json, r'content_type')!,
        width: mapValueOfType<int>(json, r'width'),
        height: mapValueOfType<int>(json, r'height'),
        position: mapValueOfType<int>(json, r'position')!,
        caption: I18nText.fromJson(json[r'caption'])!,
        urls: mapCastOfType<String, String>(json, r'urls')!,
        roomType: mapValueOfType<String>(json, r'room_type'),
        tags: json[r'tags'] is Iterable
            ? (json[r'tags'] as Iterable).cast<String>().toList(growable: false)
            : const [],
      );
    }
    return null;
  }

  static List<Media> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Media>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Media.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Media> mapFromJson(dynamic json) {
    final map = <String, Media>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Media.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Media-objects as value to a dart map
  static Map<String, List<Media>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Media>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Media.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'status',
    'filename',
    'content_type',
    'position',
    'caption',
    'urls',
  };
}


class MediaStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const MediaStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const uploading = MediaStatusEnum._(r'uploading');
  static const processing = MediaStatusEnum._(r'processing');
  static const ready = MediaStatusEnum._(r'ready');
  static const rejected = MediaStatusEnum._(r'rejected');

  /// List of all possible values in this [enum][MediaStatusEnum].
  static const values = <MediaStatusEnum>[
    uploading,
    processing,
    ready,
    rejected,
  ];

  static MediaStatusEnum? fromJson(dynamic value) => MediaStatusEnumTypeTransformer().decode(value);

  static List<MediaStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MediaStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MediaStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [MediaStatusEnum] to String,
/// and [decode] dynamic data back to [MediaStatusEnum].
class MediaStatusEnumTypeTransformer {
  factory MediaStatusEnumTypeTransformer() => _instance ??= const MediaStatusEnumTypeTransformer._();

  const MediaStatusEnumTypeTransformer._();

  String encode(MediaStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a MediaStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  MediaStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'uploading': return MediaStatusEnum.uploading;
        case r'processing': return MediaStatusEnum.processing;
        case r'ready': return MediaStatusEnum.ready;
        case r'rejected': return MediaStatusEnum.rejected;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [MediaStatusEnumTypeTransformer] instance.
  static MediaStatusEnumTypeTransformer? _instance;
}


