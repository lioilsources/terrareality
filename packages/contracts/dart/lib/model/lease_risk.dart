//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class LeaseRisk {
  /// Returns a new [LeaseRisk] instance.
  LeaseRisk({
    this.score,
    this.band,
    this.factors = const [],
    required this.modelVersion,
    required this.computedAt,
    required this.landlord,
  });

  /// Absent for tenants.
  ///
  /// Minimum value: 0
  /// Maximum value: 100
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? score;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  RiskBand? band;

  List<RiskFactor> factors;

  String modelVersion;

  DateTime computedAt;

  bool landlord;

  @override
  bool operator ==(Object other) => identical(this, other) || other is LeaseRisk &&
    other.score == score &&
    other.band == band &&
    _deepEquality.equals(other.factors, factors) &&
    other.modelVersion == modelVersion &&
    other.computedAt == computedAt &&
    other.landlord == landlord;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (score == null ? 0 : score!.hashCode) +
    (band == null ? 0 : band!.hashCode) +
    (factors.hashCode) +
    (modelVersion.hashCode) +
    (computedAt.hashCode) +
    (landlord.hashCode);

  @override
  String toString() => 'LeaseRisk[score=$score, band=$band, factors=$factors, modelVersion=$modelVersion, computedAt=$computedAt, landlord=$landlord]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.score != null) {
      json[r'score'] = this.score;
    } else {
      json[r'score'] = null;
    }
    if (this.band != null) {
      json[r'band'] = this.band;
    } else {
      json[r'band'] = null;
    }
      json[r'factors'] = this.factors;
      json[r'model_version'] = this.modelVersion;
      json[r'computed_at'] = this.computedAt.toUtc().toIso8601String();
      json[r'landlord'] = this.landlord;
    return json;
  }

  /// Returns a new [LeaseRisk] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LeaseRisk? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "LeaseRisk[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "LeaseRisk[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return LeaseRisk(
        score: mapValueOfType<int>(json, r'score'),
        band: RiskBand.fromJson(json[r'band']),
        factors: RiskFactor.listFromJson(json[r'factors']),
        modelVersion: mapValueOfType<String>(json, r'model_version')!,
        computedAt: mapDateTime(json, r'computed_at', r'')!,
        landlord: mapValueOfType<bool>(json, r'landlord')!,
      );
    }
    return null;
  }

  static List<LeaseRisk> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LeaseRisk>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LeaseRisk.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LeaseRisk> mapFromJson(dynamic json) {
    final map = <String, LeaseRisk>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LeaseRisk.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LeaseRisk-objects as value to a dart map
  static Map<String, List<LeaseRisk>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<LeaseRisk>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LeaseRisk.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'factors',
    'model_version',
    'computed_at',
    'landlord',
  };
}

