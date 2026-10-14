//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AttachmentUpload {
  /// Returns a new [AttachmentUpload] instance.
  AttachmentUpload({
    required this.id,
    required this.uploadUrl,
    required this.expiresAt,
  });

  String id;

  String uploadUrl;

  DateTime expiresAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AttachmentUpload &&
    other.id == id &&
    other.uploadUrl == uploadUrl &&
    other.expiresAt == expiresAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (uploadUrl.hashCode) +
    (expiresAt.hashCode);

  @override
  String toString() => 'AttachmentUpload[id=$id, uploadUrl=$uploadUrl, expiresAt=$expiresAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'upload_url'] = this.uploadUrl;
      json[r'expires_at'] = this.expiresAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [AttachmentUpload] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AttachmentUpload? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "AttachmentUpload[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "AttachmentUpload[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return AttachmentUpload(
        id: mapValueOfType<String>(json, r'id')!,
        uploadUrl: mapValueOfType<String>(json, r'upload_url')!,
        expiresAt: mapDateTime(json, r'expires_at', r'')!,
      );
    }
    return null;
  }

  static List<AttachmentUpload> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AttachmentUpload>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AttachmentUpload.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AttachmentUpload> mapFromJson(dynamic json) {
    final map = <String, AttachmentUpload>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AttachmentUpload.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AttachmentUpload-objects as value to a dart map
  static Map<String, List<AttachmentUpload>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AttachmentUpload>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AttachmentUpload.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'upload_url',
    'expires_at',
  };
}

