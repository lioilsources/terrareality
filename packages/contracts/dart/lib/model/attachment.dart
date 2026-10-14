//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Attachment {
  /// Returns a new [Attachment] instance.
  Attachment({
    required this.id,
    required this.filename,
    required this.contentType,
    required this.sizeBytes,
    required this.url,
  });

  String id;

  String filename;

  String contentType;

  int sizeBytes;

  /// Short-lived download URL.
  String url;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Attachment &&
    other.id == id &&
    other.filename == filename &&
    other.contentType == contentType &&
    other.sizeBytes == sizeBytes &&
    other.url == url;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (filename.hashCode) +
    (contentType.hashCode) +
    (sizeBytes.hashCode) +
    (url.hashCode);

  @override
  String toString() => 'Attachment[id=$id, filename=$filename, contentType=$contentType, sizeBytes=$sizeBytes, url=$url]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'filename'] = this.filename;
      json[r'content_type'] = this.contentType;
      json[r'size_bytes'] = this.sizeBytes;
      json[r'url'] = this.url;
    return json;
  }

  /// Returns a new [Attachment] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Attachment? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "Attachment[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "Attachment[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Attachment(
        id: mapValueOfType<String>(json, r'id')!,
        filename: mapValueOfType<String>(json, r'filename')!,
        contentType: mapValueOfType<String>(json, r'content_type')!,
        sizeBytes: mapValueOfType<int>(json, r'size_bytes')!,
        url: mapValueOfType<String>(json, r'url')!,
      );
    }
    return null;
  }

  static List<Attachment> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Attachment>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Attachment.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Attachment> mapFromJson(dynamic json) {
    final map = <String, Attachment>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Attachment.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Attachment-objects as value to a dart map
  static Map<String, List<Attachment>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Attachment>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Attachment.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'filename',
    'content_type',
    'size_bytes',
    'url',
  };
}

