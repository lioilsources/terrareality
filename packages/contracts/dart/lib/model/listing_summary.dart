//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ListingSummary {
  /// Returns a new [ListingSummary] instance.
  ListingSummary({
    required this.id,
    required this.status,
    required this.title,
    required this.unitKind,
    required this.unitLabel,
    required this.addressLabel,
    this.rentAmount,
    required this.currency,
    this.coverUrl,
    required this.pendingReview,
    this.publishedVersion,
    required this.updatedAt,
    this.isDemo = false,
  });

  String id;

  ListingStatus status;

  I18nText title;

  UnitKind unitKind;

  String unitLabel;

  String addressLabel;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? rentAmount;

  String currency;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? coverUrl;

  bool pendingReview;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? publishedVersion;

  DateTime updatedAt;

  /// Demo listing of the closed beta (terractl demo seed): shown with a prominent label, cannot be contacted, applied for or booked (problem code demo_listing).
  bool isDemo;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ListingSummary &&
    other.id == id &&
    other.status == status &&
    other.title == title &&
    other.unitKind == unitKind &&
    other.unitLabel == unitLabel &&
    other.addressLabel == addressLabel &&
    other.rentAmount == rentAmount &&
    other.currency == currency &&
    other.coverUrl == coverUrl &&
    other.pendingReview == pendingReview &&
    other.publishedVersion == publishedVersion &&
    other.updatedAt == updatedAt &&
    other.isDemo == isDemo;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (status.hashCode) +
    (title.hashCode) +
    (unitKind.hashCode) +
    (unitLabel.hashCode) +
    (addressLabel.hashCode) +
    (rentAmount == null ? 0 : rentAmount!.hashCode) +
    (currency.hashCode) +
    (coverUrl == null ? 0 : coverUrl!.hashCode) +
    (pendingReview.hashCode) +
    (publishedVersion == null ? 0 : publishedVersion!.hashCode) +
    (updatedAt.hashCode) +
    (isDemo.hashCode);

  @override
  String toString() => 'ListingSummary[id=$id, status=$status, title=$title, unitKind=$unitKind, unitLabel=$unitLabel, addressLabel=$addressLabel, rentAmount=$rentAmount, currency=$currency, coverUrl=$coverUrl, pendingReview=$pendingReview, publishedVersion=$publishedVersion, updatedAt=$updatedAt, isDemo=$isDemo]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'status'] = this.status;
      json[r'title'] = this.title;
      json[r'unit_kind'] = this.unitKind;
      json[r'unit_label'] = this.unitLabel;
      json[r'address_label'] = this.addressLabel;
    if (this.rentAmount != null) {
      json[r'rent_amount'] = this.rentAmount;
    } else {
      json[r'rent_amount'] = null;
    }
      json[r'currency'] = this.currency;
    if (this.coverUrl != null) {
      json[r'cover_url'] = this.coverUrl;
    } else {
      json[r'cover_url'] = null;
    }
      json[r'pending_review'] = this.pendingReview;
    if (this.publishedVersion != null) {
      json[r'published_version'] = this.publishedVersion;
    } else {
      json[r'published_version'] = null;
    }
      json[r'updated_at'] = this.updatedAt.toUtc().toIso8601String();
      json[r'is_demo'] = this.isDemo;
    return json;
  }

  /// Returns a new [ListingSummary] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ListingSummary? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ListingSummary[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ListingSummary[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ListingSummary(
        id: mapValueOfType<String>(json, r'id')!,
        status: ListingStatus.fromJson(json[r'status'])!,
        title: I18nText.fromJson(json[r'title'])!,
        unitKind: UnitKind.fromJson(json[r'unit_kind'])!,
        unitLabel: mapValueOfType<String>(json, r'unit_label')!,
        addressLabel: mapValueOfType<String>(json, r'address_label')!,
        rentAmount: mapValueOfType<int>(json, r'rent_amount'),
        currency: mapValueOfType<String>(json, r'currency')!,
        coverUrl: mapValueOfType<String>(json, r'cover_url'),
        pendingReview: mapValueOfType<bool>(json, r'pending_review')!,
        publishedVersion: mapValueOfType<int>(json, r'published_version'),
        updatedAt: mapDateTime(json, r'updated_at', r'')!,
        isDemo: mapValueOfType<bool>(json, r'is_demo')!,
      );
    }
    return null;
  }

  static List<ListingSummary> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ListingSummary>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ListingSummary.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ListingSummary> mapFromJson(dynamic json) {
    final map = <String, ListingSummary>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ListingSummary.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ListingSummary-objects as value to a dart map
  static Map<String, List<ListingSummary>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ListingSummary>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ListingSummary.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'status',
    'title',
    'unit_kind',
    'unit_label',
    'address_label',
    'currency',
    'pending_review',
    'updated_at',
    'is_demo',
  };
}

