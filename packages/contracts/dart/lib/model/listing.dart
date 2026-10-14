//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Listing {
  /// Returns a new [Listing] instance.
  Listing({
    required this.id,
    required this.orgId,
    this.prescreen = const [],
    required this.status,
    required this.title,
    required this.description,
    this.rentAmount,
    this.depositAmount,
    this.utilitiesAmount,
    required this.currency,
    this.availableFrom,
    this.minTermMonths,
    this.attributes = const {},
    required this.locationPrecision,
    this.publishedVersion,
    this.publishedAt,
    required this.pendingReview,
    required this.unit,
    required this.propertyId,
    required this.address,
    this.media = const [],
    this.suggestions = const [],
    this.versions = const [],
    required this.depositMaxMonths,
    required this.createdAt,
    required this.updatedAt,
  });

  String id;

  String orgId;

  List<PrescreenQuestion> prescreen;

  ListingStatus status;

  I18nText title;

  I18nText description;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? rentAmount;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? depositAmount;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? utilitiesAmount;

  String currency;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? availableFrom;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? minTermMonths;

  Map<String, Object> attributes;

  ListingLocationPrecisionEnum locationPrecision;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? publishedVersion;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? publishedAt;

  bool pendingReview;

  ListingUnit unit;

  String propertyId;

  ListingAddress address;

  List<Media> media;

  List<Suggestion> suggestions;

  List<ListingVersionInfo> versions;

  /// Jurisdiction cap for the deposit in monthly rents.
  int depositMaxMonths;

  DateTime createdAt;

  DateTime updatedAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Listing &&
    other.id == id &&
    other.orgId == orgId &&
    _deepEquality.equals(other.prescreen, prescreen) &&
    other.status == status &&
    other.title == title &&
    other.description == description &&
    other.rentAmount == rentAmount &&
    other.depositAmount == depositAmount &&
    other.utilitiesAmount == utilitiesAmount &&
    other.currency == currency &&
    other.availableFrom == availableFrom &&
    other.minTermMonths == minTermMonths &&
    _deepEquality.equals(other.attributes, attributes) &&
    other.locationPrecision == locationPrecision &&
    other.publishedVersion == publishedVersion &&
    other.publishedAt == publishedAt &&
    other.pendingReview == pendingReview &&
    other.unit == unit &&
    other.propertyId == propertyId &&
    other.address == address &&
    _deepEquality.equals(other.media, media) &&
    _deepEquality.equals(other.suggestions, suggestions) &&
    _deepEquality.equals(other.versions, versions) &&
    other.depositMaxMonths == depositMaxMonths &&
    other.createdAt == createdAt &&
    other.updatedAt == updatedAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (orgId.hashCode) +
    (prescreen.hashCode) +
    (status.hashCode) +
    (title.hashCode) +
    (description.hashCode) +
    (rentAmount == null ? 0 : rentAmount!.hashCode) +
    (depositAmount == null ? 0 : depositAmount!.hashCode) +
    (utilitiesAmount == null ? 0 : utilitiesAmount!.hashCode) +
    (currency.hashCode) +
    (availableFrom == null ? 0 : availableFrom!.hashCode) +
    (minTermMonths == null ? 0 : minTermMonths!.hashCode) +
    (attributes.hashCode) +
    (locationPrecision.hashCode) +
    (publishedVersion == null ? 0 : publishedVersion!.hashCode) +
    (publishedAt == null ? 0 : publishedAt!.hashCode) +
    (pendingReview.hashCode) +
    (unit.hashCode) +
    (propertyId.hashCode) +
    (address.hashCode) +
    (media.hashCode) +
    (suggestions.hashCode) +
    (versions.hashCode) +
    (depositMaxMonths.hashCode) +
    (createdAt.hashCode) +
    (updatedAt.hashCode);

  @override
  String toString() => 'Listing[id=$id, orgId=$orgId, prescreen=$prescreen, status=$status, title=$title, description=$description, rentAmount=$rentAmount, depositAmount=$depositAmount, utilitiesAmount=$utilitiesAmount, currency=$currency, availableFrom=$availableFrom, minTermMonths=$minTermMonths, attributes=$attributes, locationPrecision=$locationPrecision, publishedVersion=$publishedVersion, publishedAt=$publishedAt, pendingReview=$pendingReview, unit=$unit, propertyId=$propertyId, address=$address, media=$media, suggestions=$suggestions, versions=$versions, depositMaxMonths=$depositMaxMonths, createdAt=$createdAt, updatedAt=$updatedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'org_id'] = this.orgId;
      json[r'prescreen'] = this.prescreen;
      json[r'status'] = this.status;
      json[r'title'] = this.title;
      json[r'description'] = this.description;
    if (this.rentAmount != null) {
      json[r'rent_amount'] = this.rentAmount;
    } else {
      json[r'rent_amount'] = null;
    }
    if (this.depositAmount != null) {
      json[r'deposit_amount'] = this.depositAmount;
    } else {
      json[r'deposit_amount'] = null;
    }
    if (this.utilitiesAmount != null) {
      json[r'utilities_amount'] = this.utilitiesAmount;
    } else {
      json[r'utilities_amount'] = null;
    }
      json[r'currency'] = this.currency;
    if (this.availableFrom != null) {
      json[r'available_from'] = _dateFormatter.format(this.availableFrom!.toUtc());
    } else {
      json[r'available_from'] = null;
    }
    if (this.minTermMonths != null) {
      json[r'min_term_months'] = this.minTermMonths;
    } else {
      json[r'min_term_months'] = null;
    }
      json[r'attributes'] = this.attributes;
      json[r'location_precision'] = this.locationPrecision;
    if (this.publishedVersion != null) {
      json[r'published_version'] = this.publishedVersion;
    } else {
      json[r'published_version'] = null;
    }
    if (this.publishedAt != null) {
      json[r'published_at'] = this.publishedAt!.toUtc().toIso8601String();
    } else {
      json[r'published_at'] = null;
    }
      json[r'pending_review'] = this.pendingReview;
      json[r'unit'] = this.unit;
      json[r'property_id'] = this.propertyId;
      json[r'address'] = this.address;
      json[r'media'] = this.media;
      json[r'suggestions'] = this.suggestions;
      json[r'versions'] = this.versions;
      json[r'deposit_max_months'] = this.depositMaxMonths;
      json[r'created_at'] = this.createdAt.toUtc().toIso8601String();
      json[r'updated_at'] = this.updatedAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [Listing] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Listing? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "Listing[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "Listing[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Listing(
        id: mapValueOfType<String>(json, r'id')!,
        orgId: mapValueOfType<String>(json, r'org_id')!,
        prescreen: PrescreenQuestion.listFromJson(json[r'prescreen']),
        status: ListingStatus.fromJson(json[r'status'])!,
        title: I18nText.fromJson(json[r'title'])!,
        description: I18nText.fromJson(json[r'description'])!,
        rentAmount: mapValueOfType<int>(json, r'rent_amount'),
        depositAmount: mapValueOfType<int>(json, r'deposit_amount'),
        utilitiesAmount: mapValueOfType<int>(json, r'utilities_amount'),
        currency: mapValueOfType<String>(json, r'currency')!,
        availableFrom: mapDateTime(json, r'available_from', r''),
        minTermMonths: mapValueOfType<int>(json, r'min_term_months'),
        attributes: mapCastOfType<String, Object>(json, r'attributes')!,
        locationPrecision: ListingLocationPrecisionEnum.fromJson(json[r'location_precision'])!,
        publishedVersion: mapValueOfType<int>(json, r'published_version'),
        publishedAt: mapDateTime(json, r'published_at', r''),
        pendingReview: mapValueOfType<bool>(json, r'pending_review')!,
        unit: ListingUnit.fromJson(json[r'unit'])!,
        propertyId: mapValueOfType<String>(json, r'property_id')!,
        address: ListingAddress.fromJson(json[r'address'])!,
        media: Media.listFromJson(json[r'media']),
        suggestions: Suggestion.listFromJson(json[r'suggestions']),
        versions: ListingVersionInfo.listFromJson(json[r'versions']),
        depositMaxMonths: mapValueOfType<int>(json, r'deposit_max_months')!,
        createdAt: mapDateTime(json, r'created_at', r'')!,
        updatedAt: mapDateTime(json, r'updated_at', r'')!,
      );
    }
    return null;
  }

  static List<Listing> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Listing>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Listing.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Listing> mapFromJson(dynamic json) {
    final map = <String, Listing>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Listing.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Listing-objects as value to a dart map
  static Map<String, List<Listing>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Listing>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Listing.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'org_id',
    'prescreen',
    'status',
    'title',
    'description',
    'currency',
    'attributes',
    'location_precision',
    'pending_review',
    'unit',
    'property_id',
    'address',
    'media',
    'suggestions',
    'versions',
    'deposit_max_months',
    'created_at',
    'updated_at',
  };
}


class ListingLocationPrecisionEnum {
  /// Instantiate a new enum with the provided [value].
  const ListingLocationPrecisionEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const exact = ListingLocationPrecisionEnum._(r'exact');
  static const approximate = ListingLocationPrecisionEnum._(r'approximate');

  /// List of all possible values in this [enum][ListingLocationPrecisionEnum].
  static const values = <ListingLocationPrecisionEnum>[
    exact,
    approximate,
  ];

  static ListingLocationPrecisionEnum? fromJson(dynamic value) => ListingLocationPrecisionEnumTypeTransformer().decode(value);

  static List<ListingLocationPrecisionEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ListingLocationPrecisionEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ListingLocationPrecisionEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ListingLocationPrecisionEnum] to String,
/// and [decode] dynamic data back to [ListingLocationPrecisionEnum].
class ListingLocationPrecisionEnumTypeTransformer {
  factory ListingLocationPrecisionEnumTypeTransformer() => _instance ??= const ListingLocationPrecisionEnumTypeTransformer._();

  const ListingLocationPrecisionEnumTypeTransformer._();

  String encode(ListingLocationPrecisionEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a ListingLocationPrecisionEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ListingLocationPrecisionEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'exact': return ListingLocationPrecisionEnum.exact;
        case r'approximate': return ListingLocationPrecisionEnum.approximate;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ListingLocationPrecisionEnumTypeTransformer] instance.
  static ListingLocationPrecisionEnumTypeTransformer? _instance;
}


