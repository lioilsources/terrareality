//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ReviewItem {
  /// Returns a new [ReviewItem] instance.
  ReviewItem({
    required this.versionId,
    required this.listingId,
    required this.orgId,
    required this.orgName,
    required this.version,
    required this.submittedAt,
    required this.submittedByEmail,
    required this.title,
    required this.firstPublication,
    this.coverUrl,
  });

  String versionId;

  String listingId;

  String orgId;

  String orgName;

  int version;

  DateTime submittedAt;

  String submittedByEmail;

  I18nText title;

  bool firstPublication;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? coverUrl;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ReviewItem &&
    other.versionId == versionId &&
    other.listingId == listingId &&
    other.orgId == orgId &&
    other.orgName == orgName &&
    other.version == version &&
    other.submittedAt == submittedAt &&
    other.submittedByEmail == submittedByEmail &&
    other.title == title &&
    other.firstPublication == firstPublication &&
    other.coverUrl == coverUrl;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (versionId.hashCode) +
    (listingId.hashCode) +
    (orgId.hashCode) +
    (orgName.hashCode) +
    (version.hashCode) +
    (submittedAt.hashCode) +
    (submittedByEmail.hashCode) +
    (title.hashCode) +
    (firstPublication.hashCode) +
    (coverUrl == null ? 0 : coverUrl!.hashCode);

  @override
  String toString() => 'ReviewItem[versionId=$versionId, listingId=$listingId, orgId=$orgId, orgName=$orgName, version=$version, submittedAt=$submittedAt, submittedByEmail=$submittedByEmail, title=$title, firstPublication=$firstPublication, coverUrl=$coverUrl]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'version_id'] = this.versionId;
      json[r'listing_id'] = this.listingId;
      json[r'org_id'] = this.orgId;
      json[r'org_name'] = this.orgName;
      json[r'version'] = this.version;
      json[r'submitted_at'] = this.submittedAt.toUtc().toIso8601String();
      json[r'submitted_by_email'] = this.submittedByEmail;
      json[r'title'] = this.title;
      json[r'first_publication'] = this.firstPublication;
    if (this.coverUrl != null) {
      json[r'cover_url'] = this.coverUrl;
    } else {
      json[r'cover_url'] = null;
    }
    return json;
  }

  /// Returns a new [ReviewItem] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ReviewItem? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ReviewItem[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ReviewItem[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ReviewItem(
        versionId: mapValueOfType<String>(json, r'version_id')!,
        listingId: mapValueOfType<String>(json, r'listing_id')!,
        orgId: mapValueOfType<String>(json, r'org_id')!,
        orgName: mapValueOfType<String>(json, r'org_name')!,
        version: mapValueOfType<int>(json, r'version')!,
        submittedAt: mapDateTime(json, r'submitted_at', r'')!,
        submittedByEmail: mapValueOfType<String>(json, r'submitted_by_email')!,
        title: I18nText.fromJson(json[r'title'])!,
        firstPublication: mapValueOfType<bool>(json, r'first_publication')!,
        coverUrl: mapValueOfType<String>(json, r'cover_url'),
      );
    }
    return null;
  }

  static List<ReviewItem> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ReviewItem>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ReviewItem.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ReviewItem> mapFromJson(dynamic json) {
    final map = <String, ReviewItem>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ReviewItem.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ReviewItem-objects as value to a dart map
  static Map<String, List<ReviewItem>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ReviewItem>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ReviewItem.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'version_id',
    'listing_id',
    'org_id',
    'org_name',
    'version',
    'submitted_at',
    'submitted_by_email',
    'title',
    'first_publication',
  };
}

