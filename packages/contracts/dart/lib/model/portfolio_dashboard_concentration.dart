//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PortfolioDashboardConcentration {
  /// Returns a new [PortfolioDashboardConcentration] instance.
  PortfolioDashboardConcentration({
    this.topCity,
    this.topTenant,
    this.endingPeak,
    required this.hhi,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  PortfolioShare? topCity;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  PortfolioShare? topTenant;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  PortfolioShare? endingPeak;

  /// Herfindahl index of income over municipalities (0..1).
  num hhi;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PortfolioDashboardConcentration &&
    other.topCity == topCity &&
    other.topTenant == topTenant &&
    other.endingPeak == endingPeak &&
    other.hhi == hhi;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (topCity == null ? 0 : topCity!.hashCode) +
    (topTenant == null ? 0 : topTenant!.hashCode) +
    (endingPeak == null ? 0 : endingPeak!.hashCode) +
    (hhi.hashCode);

  @override
  String toString() => 'PortfolioDashboardConcentration[topCity=$topCity, topTenant=$topTenant, endingPeak=$endingPeak, hhi=$hhi]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.topCity != null) {
      json[r'top_city'] = this.topCity;
    } else {
      json[r'top_city'] = null;
    }
    if (this.topTenant != null) {
      json[r'top_tenant'] = this.topTenant;
    } else {
      json[r'top_tenant'] = null;
    }
    if (this.endingPeak != null) {
      json[r'ending_peak'] = this.endingPeak;
    } else {
      json[r'ending_peak'] = null;
    }
      json[r'hhi'] = this.hhi;
    return json;
  }

  /// Returns a new [PortfolioDashboardConcentration] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PortfolioDashboardConcentration? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PortfolioDashboardConcentration[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PortfolioDashboardConcentration[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PortfolioDashboardConcentration(
        topCity: PortfolioShare.fromJson(json[r'top_city']),
        topTenant: PortfolioShare.fromJson(json[r'top_tenant']),
        endingPeak: PortfolioShare.fromJson(json[r'ending_peak']),
        hhi: num.parse('${json[r'hhi']}'),
      );
    }
    return null;
  }

  static List<PortfolioDashboardConcentration> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PortfolioDashboardConcentration>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PortfolioDashboardConcentration.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PortfolioDashboardConcentration> mapFromJson(dynamic json) {
    final map = <String, PortfolioDashboardConcentration>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PortfolioDashboardConcentration.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PortfolioDashboardConcentration-objects as value to a dart map
  static Map<String, List<PortfolioDashboardConcentration>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PortfolioDashboardConcentration>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PortfolioDashboardConcentration.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'hhi',
  };
}

