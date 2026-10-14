//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PublicListingLocation {
  /// Returns a new [PublicListingLocation] instance.
  PublicListingLocation({
    required this.lat,
    required this.lng,
    required this.precision,
    this.address,
  });

  double lat;

  double lng;

  PublicListingLocationPrecisionEnum precision;

  /// Only when the owner chose the exact location.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? address;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PublicListingLocation &&
    other.lat == lat &&
    other.lng == lng &&
    other.precision == precision &&
    other.address == address;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (lat.hashCode) +
    (lng.hashCode) +
    (precision.hashCode) +
    (address == null ? 0 : address!.hashCode);

  @override
  String toString() => 'PublicListingLocation[lat=$lat, lng=$lng, precision=$precision, address=$address]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'lat'] = this.lat;
      json[r'lng'] = this.lng;
      json[r'precision'] = this.precision;
    if (this.address != null) {
      json[r'address'] = this.address;
    } else {
      json[r'address'] = null;
    }
    return json;
  }

  /// Returns a new [PublicListingLocation] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PublicListingLocation? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PublicListingLocation[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PublicListingLocation[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PublicListingLocation(
        lat: mapValueOfType<double>(json, r'lat')!,
        lng: mapValueOfType<double>(json, r'lng')!,
        precision: PublicListingLocationPrecisionEnum.fromJson(json[r'precision'])!,
        address: mapValueOfType<String>(json, r'address'),
      );
    }
    return null;
  }

  static List<PublicListingLocation> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PublicListingLocation>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PublicListingLocation.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PublicListingLocation> mapFromJson(dynamic json) {
    final map = <String, PublicListingLocation>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PublicListingLocation.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PublicListingLocation-objects as value to a dart map
  static Map<String, List<PublicListingLocation>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PublicListingLocation>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PublicListingLocation.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'lat',
    'lng',
    'precision',
  };
}


class PublicListingLocationPrecisionEnum {
  /// Instantiate a new enum with the provided [value].
  const PublicListingLocationPrecisionEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const exact = PublicListingLocationPrecisionEnum._(r'exact');
  static const approximate = PublicListingLocationPrecisionEnum._(r'approximate');

  /// List of all possible values in this [enum][PublicListingLocationPrecisionEnum].
  static const values = <PublicListingLocationPrecisionEnum>[
    exact,
    approximate,
  ];

  static PublicListingLocationPrecisionEnum? fromJson(dynamic value) => PublicListingLocationPrecisionEnumTypeTransformer().decode(value);

  static List<PublicListingLocationPrecisionEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PublicListingLocationPrecisionEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PublicListingLocationPrecisionEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [PublicListingLocationPrecisionEnum] to String,
/// and [decode] dynamic data back to [PublicListingLocationPrecisionEnum].
class PublicListingLocationPrecisionEnumTypeTransformer {
  factory PublicListingLocationPrecisionEnumTypeTransformer() => _instance ??= const PublicListingLocationPrecisionEnumTypeTransformer._();

  const PublicListingLocationPrecisionEnumTypeTransformer._();

  String encode(PublicListingLocationPrecisionEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a PublicListingLocationPrecisionEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  PublicListingLocationPrecisionEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'exact': return PublicListingLocationPrecisionEnum.exact;
        case r'approximate': return PublicListingLocationPrecisionEnum.approximate;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [PublicListingLocationPrecisionEnumTypeTransformer] instance.
  static PublicListingLocationPrecisionEnumTypeTransformer? _instance;
}


