//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PortfolioCity {
  /// Returns a new [PortfolioCity] instance.
  PortfolioCity({
    required this.path,
    required this.name,
    required this.region,
    required this.leases,
    required this.vacant,
    required this.monthly,
    required this.expected,
    required this.received,
    required this.debt,
    this.weightedRisk,
    this.band,
    required this.share,
    this.lat,
    this.lng,
  });

  String path;

  String name;

  String region;

  int leases;

  int vacant;

  int monthly;

  int expected;

  int received;

  int debt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? weightedRisk;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  RiskBand? band;

  num share;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? lat;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? lng;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PortfolioCity &&
    other.path == path &&
    other.name == name &&
    other.region == region &&
    other.leases == leases &&
    other.vacant == vacant &&
    other.monthly == monthly &&
    other.expected == expected &&
    other.received == received &&
    other.debt == debt &&
    other.weightedRisk == weightedRisk &&
    other.band == band &&
    other.share == share &&
    other.lat == lat &&
    other.lng == lng;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (path.hashCode) +
    (name.hashCode) +
    (region.hashCode) +
    (leases.hashCode) +
    (vacant.hashCode) +
    (monthly.hashCode) +
    (expected.hashCode) +
    (received.hashCode) +
    (debt.hashCode) +
    (weightedRisk == null ? 0 : weightedRisk!.hashCode) +
    (band == null ? 0 : band!.hashCode) +
    (share.hashCode) +
    (lat == null ? 0 : lat!.hashCode) +
    (lng == null ? 0 : lng!.hashCode);

  @override
  String toString() => 'PortfolioCity[path=$path, name=$name, region=$region, leases=$leases, vacant=$vacant, monthly=$monthly, expected=$expected, received=$received, debt=$debt, weightedRisk=$weightedRisk, band=$band, share=$share, lat=$lat, lng=$lng]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'path'] = this.path;
      json[r'name'] = this.name;
      json[r'region'] = this.region;
      json[r'leases'] = this.leases;
      json[r'vacant'] = this.vacant;
      json[r'monthly'] = this.monthly;
      json[r'expected'] = this.expected;
      json[r'received'] = this.received;
      json[r'debt'] = this.debt;
    if (this.weightedRisk != null) {
      json[r'weighted_risk'] = this.weightedRisk;
    } else {
      json[r'weighted_risk'] = null;
    }
    if (this.band != null) {
      json[r'band'] = this.band;
    } else {
      json[r'band'] = null;
    }
      json[r'share'] = this.share;
    if (this.lat != null) {
      json[r'lat'] = this.lat;
    } else {
      json[r'lat'] = null;
    }
    if (this.lng != null) {
      json[r'lng'] = this.lng;
    } else {
      json[r'lng'] = null;
    }
    return json;
  }

  /// Returns a new [PortfolioCity] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PortfolioCity? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PortfolioCity[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PortfolioCity[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PortfolioCity(
        path: mapValueOfType<String>(json, r'path')!,
        name: mapValueOfType<String>(json, r'name')!,
        region: mapValueOfType<String>(json, r'region')!,
        leases: mapValueOfType<int>(json, r'leases')!,
        vacant: mapValueOfType<int>(json, r'vacant')!,
        monthly: mapValueOfType<int>(json, r'monthly')!,
        expected: mapValueOfType<int>(json, r'expected')!,
        received: mapValueOfType<int>(json, r'received')!,
        debt: mapValueOfType<int>(json, r'debt')!,
        weightedRisk: mapValueOfType<int>(json, r'weighted_risk'),
        band: RiskBand.fromJson(json[r'band']),
        share: num.parse('${json[r'share']}'),
        lat: num.parse('${json[r'lat']}'),
        lng: num.parse('${json[r'lng']}'),
      );
    }
    return null;
  }

  static List<PortfolioCity> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PortfolioCity>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PortfolioCity.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PortfolioCity> mapFromJson(dynamic json) {
    final map = <String, PortfolioCity>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PortfolioCity.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PortfolioCity-objects as value to a dart map
  static Map<String, List<PortfolioCity>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PortfolioCity>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PortfolioCity.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'path',
    'name',
    'region',
    'leases',
    'vacant',
    'monthly',
    'expected',
    'received',
    'debt',
    'share',
  };
}

