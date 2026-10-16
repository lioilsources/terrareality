//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DownloadLink {
  /// Returns a new [DownloadLink] instance.
  DownloadLink({
    required this.url,
    required this.expiresAt,
    this.filename,
  });

  String url;

  DateTime expiresAt;

  /// Suggested file name (income proofs).
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? filename;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DownloadLink &&
    other.url == url &&
    other.expiresAt == expiresAt &&
    other.filename == filename;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (url.hashCode) +
    (expiresAt.hashCode) +
    (filename == null ? 0 : filename!.hashCode);

  @override
  String toString() => 'DownloadLink[url=$url, expiresAt=$expiresAt, filename=$filename]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'url'] = this.url;
      json[r'expires_at'] = this.expiresAt.toUtc().toIso8601String();
    if (this.filename != null) {
      json[r'filename'] = this.filename;
    } else {
      json[r'filename'] = null;
    }
    return json;
  }

  /// Returns a new [DownloadLink] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DownloadLink? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "DownloadLink[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "DownloadLink[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return DownloadLink(
        url: mapValueOfType<String>(json, r'url')!,
        expiresAt: mapDateTime(json, r'expires_at', r'')!,
        filename: mapValueOfType<String>(json, r'filename'),
      );
    }
    return null;
  }

  static List<DownloadLink> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DownloadLink>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DownloadLink.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DownloadLink> mapFromJson(dynamic json) {
    final map = <String, DownloadLink>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DownloadLink.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DownloadLink-objects as value to a dart map
  static Map<String, List<DownloadLink>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DownloadLink>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DownloadLink.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'url',
    'expires_at',
  };
}

