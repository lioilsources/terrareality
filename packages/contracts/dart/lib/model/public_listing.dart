//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PublicListing {
  /// Returns a new [PublicListing] instance.
  PublicListing({
    required this.id,
    this.prescreen = const [],
    required this.title,
    required this.description,
    required this.rentAmount,
    this.depositAmount,
    this.utilitiesAmount,
    required this.currency,
    this.availableFrom,
    this.minTermMonths,
    this.attributes = const {},
    required this.unit,
    required this.location,
    this.areaNames = const [],
    this.photos = const [],
    required this.publishedAt,
  });

  String id;

  /// Questions to answer when contacting the landlord.
  List<PrescreenQuestion> prescreen;

  I18nText title;

  I18nText description;

  int rentAmount;

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

  PublicListingUnit unit;

  PublicListingLocation location;

  /// From region to neighbourhood.
  List<String> areaNames;

  List<PhotoVariants> photos;

  DateTime publishedAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PublicListing &&
    other.id == id &&
    _deepEquality.equals(other.prescreen, prescreen) &&
    other.title == title &&
    other.description == description &&
    other.rentAmount == rentAmount &&
    other.depositAmount == depositAmount &&
    other.utilitiesAmount == utilitiesAmount &&
    other.currency == currency &&
    other.availableFrom == availableFrom &&
    other.minTermMonths == minTermMonths &&
    _deepEquality.equals(other.attributes, attributes) &&
    other.unit == unit &&
    other.location == location &&
    _deepEquality.equals(other.areaNames, areaNames) &&
    _deepEquality.equals(other.photos, photos) &&
    other.publishedAt == publishedAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (prescreen.hashCode) +
    (title.hashCode) +
    (description.hashCode) +
    (rentAmount.hashCode) +
    (depositAmount == null ? 0 : depositAmount!.hashCode) +
    (utilitiesAmount == null ? 0 : utilitiesAmount!.hashCode) +
    (currency.hashCode) +
    (availableFrom == null ? 0 : availableFrom!.hashCode) +
    (minTermMonths == null ? 0 : minTermMonths!.hashCode) +
    (attributes.hashCode) +
    (unit.hashCode) +
    (location.hashCode) +
    (areaNames.hashCode) +
    (photos.hashCode) +
    (publishedAt.hashCode);

  @override
  String toString() => 'PublicListing[id=$id, prescreen=$prescreen, title=$title, description=$description, rentAmount=$rentAmount, depositAmount=$depositAmount, utilitiesAmount=$utilitiesAmount, currency=$currency, availableFrom=$availableFrom, minTermMonths=$minTermMonths, attributes=$attributes, unit=$unit, location=$location, areaNames=$areaNames, photos=$photos, publishedAt=$publishedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'prescreen'] = this.prescreen;
      json[r'title'] = this.title;
      json[r'description'] = this.description;
      json[r'rent_amount'] = this.rentAmount;
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
      json[r'unit'] = this.unit;
      json[r'location'] = this.location;
      json[r'area_names'] = this.areaNames;
      json[r'photos'] = this.photos;
      json[r'published_at'] = this.publishedAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [PublicListing] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PublicListing? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PublicListing[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PublicListing[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PublicListing(
        id: mapValueOfType<String>(json, r'id')!,
        prescreen: PrescreenQuestion.listFromJson(json[r'prescreen']),
        title: I18nText.fromJson(json[r'title'])!,
        description: I18nText.fromJson(json[r'description'])!,
        rentAmount: mapValueOfType<int>(json, r'rent_amount')!,
        depositAmount: mapValueOfType<int>(json, r'deposit_amount'),
        utilitiesAmount: mapValueOfType<int>(json, r'utilities_amount'),
        currency: mapValueOfType<String>(json, r'currency')!,
        availableFrom: mapDateTime(json, r'available_from', r''),
        minTermMonths: mapValueOfType<int>(json, r'min_term_months'),
        attributes: mapCastOfType<String, Object>(json, r'attributes')!,
        unit: PublicListingUnit.fromJson(json[r'unit'])!,
        location: PublicListingLocation.fromJson(json[r'location'])!,
        areaNames: json[r'area_names'] is Iterable
            ? (json[r'area_names'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        photos: PhotoVariants.listFromJson(json[r'photos']),
        publishedAt: mapDateTime(json, r'published_at', r'')!,
      );
    }
    return null;
  }

  static List<PublicListing> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PublicListing>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PublicListing.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PublicListing> mapFromJson(dynamic json) {
    final map = <String, PublicListing>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PublicListing.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PublicListing-objects as value to a dart map
  static Map<String, List<PublicListing>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PublicListing>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PublicListing.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'prescreen',
    'title',
    'description',
    'rent_amount',
    'currency',
    'attributes',
    'unit',
    'location',
    'area_names',
    'photos',
    'published_at',
  };
}

