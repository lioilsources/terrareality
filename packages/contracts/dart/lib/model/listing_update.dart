//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ListingUpdate {
  /// Returns a new [ListingUpdate] instance.
  ListingUpdate({
    required this.title,
    required this.description,
    this.rentAmount,
    this.depositAmount,
    this.utilitiesAmount,
    this.availableFrom,
    this.minTermMonths,
    this.attributes = const {},
    required this.locationPrecision,
    this.unitLabel,
    this.floor,
    this.floorArea,
    this.layout,
  });

  I18nText title;

  I18nText description;

  /// Minor units (haléře).
  ///
  /// Minimum value: 0
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? rentAmount;

  /// Minimum value: 0
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? depositAmount;

  /// Minimum value: 0
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? utilitiesAmount;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? availableFrom;

  /// Minimum value: 0
  /// Maximum value: 120
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? minTermMonths;

  Map<String, Object> attributes;

  ListingUpdateLocationPrecisionEnum locationPrecision;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? unitLabel;

  /// Minimum value: -5
  /// Maximum value: 100
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? floor;

  /// Minimum value: 1
  /// Maximum value: 100000
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? floorArea;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? layout;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ListingUpdate &&
    other.title == title &&
    other.description == description &&
    other.rentAmount == rentAmount &&
    other.depositAmount == depositAmount &&
    other.utilitiesAmount == utilitiesAmount &&
    other.availableFrom == availableFrom &&
    other.minTermMonths == minTermMonths &&
    _deepEquality.equals(other.attributes, attributes) &&
    other.locationPrecision == locationPrecision &&
    other.unitLabel == unitLabel &&
    other.floor == floor &&
    other.floorArea == floorArea &&
    other.layout == layout;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (title.hashCode) +
    (description.hashCode) +
    (rentAmount == null ? 0 : rentAmount!.hashCode) +
    (depositAmount == null ? 0 : depositAmount!.hashCode) +
    (utilitiesAmount == null ? 0 : utilitiesAmount!.hashCode) +
    (availableFrom == null ? 0 : availableFrom!.hashCode) +
    (minTermMonths == null ? 0 : minTermMonths!.hashCode) +
    (attributes.hashCode) +
    (locationPrecision.hashCode) +
    (unitLabel == null ? 0 : unitLabel!.hashCode) +
    (floor == null ? 0 : floor!.hashCode) +
    (floorArea == null ? 0 : floorArea!.hashCode) +
    (layout == null ? 0 : layout!.hashCode);

  @override
  String toString() => 'ListingUpdate[title=$title, description=$description, rentAmount=$rentAmount, depositAmount=$depositAmount, utilitiesAmount=$utilitiesAmount, availableFrom=$availableFrom, minTermMonths=$minTermMonths, attributes=$attributes, locationPrecision=$locationPrecision, unitLabel=$unitLabel, floor=$floor, floorArea=$floorArea, layout=$layout]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
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
    if (this.unitLabel != null) {
      json[r'unit_label'] = this.unitLabel;
    } else {
      json[r'unit_label'] = null;
    }
    if (this.floor != null) {
      json[r'floor'] = this.floor;
    } else {
      json[r'floor'] = null;
    }
    if (this.floorArea != null) {
      json[r'floor_area'] = this.floorArea;
    } else {
      json[r'floor_area'] = null;
    }
    if (this.layout != null) {
      json[r'layout'] = this.layout;
    } else {
      json[r'layout'] = null;
    }
    return json;
  }

  /// Returns a new [ListingUpdate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ListingUpdate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ListingUpdate[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ListingUpdate[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ListingUpdate(
        title: I18nText.fromJson(json[r'title'])!,
        description: I18nText.fromJson(json[r'description'])!,
        rentAmount: mapValueOfType<int>(json, r'rent_amount'),
        depositAmount: mapValueOfType<int>(json, r'deposit_amount'),
        utilitiesAmount: mapValueOfType<int>(json, r'utilities_amount'),
        availableFrom: mapDateTime(json, r'available_from', r''),
        minTermMonths: mapValueOfType<int>(json, r'min_term_months'),
        attributes: mapCastOfType<String, Object>(json, r'attributes')!,
        locationPrecision: ListingUpdateLocationPrecisionEnum.fromJson(json[r'location_precision'])!,
        unitLabel: mapValueOfType<String>(json, r'unit_label'),
        floor: mapValueOfType<int>(json, r'floor'),
        floorArea: mapValueOfType<double>(json, r'floor_area'),
        layout: mapValueOfType<String>(json, r'layout'),
      );
    }
    return null;
  }

  static List<ListingUpdate> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ListingUpdate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ListingUpdate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ListingUpdate> mapFromJson(dynamic json) {
    final map = <String, ListingUpdate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ListingUpdate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ListingUpdate-objects as value to a dart map
  static Map<String, List<ListingUpdate>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ListingUpdate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ListingUpdate.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'title',
    'description',
    'attributes',
    'location_precision',
  };
}


class ListingUpdateLocationPrecisionEnum {
  /// Instantiate a new enum with the provided [value].
  const ListingUpdateLocationPrecisionEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const exact = ListingUpdateLocationPrecisionEnum._(r'exact');
  static const approximate = ListingUpdateLocationPrecisionEnum._(r'approximate');

  /// List of all possible values in this [enum][ListingUpdateLocationPrecisionEnum].
  static const values = <ListingUpdateLocationPrecisionEnum>[
    exact,
    approximate,
  ];

  static ListingUpdateLocationPrecisionEnum? fromJson(dynamic value) => ListingUpdateLocationPrecisionEnumTypeTransformer().decode(value);

  static List<ListingUpdateLocationPrecisionEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ListingUpdateLocationPrecisionEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ListingUpdateLocationPrecisionEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ListingUpdateLocationPrecisionEnum] to String,
/// and [decode] dynamic data back to [ListingUpdateLocationPrecisionEnum].
class ListingUpdateLocationPrecisionEnumTypeTransformer {
  factory ListingUpdateLocationPrecisionEnumTypeTransformer() => _instance ??= const ListingUpdateLocationPrecisionEnumTypeTransformer._();

  const ListingUpdateLocationPrecisionEnumTypeTransformer._();

  String encode(ListingUpdateLocationPrecisionEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a ListingUpdateLocationPrecisionEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ListingUpdateLocationPrecisionEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'exact': return ListingUpdateLocationPrecisionEnum.exact;
        case r'approximate': return ListingUpdateLocationPrecisionEnum.approximate;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ListingUpdateLocationPrecisionEnumTypeTransformer] instance.
  static ListingUpdateLocationPrecisionEnumTypeTransformer? _instance;
}


