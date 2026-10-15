//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PortfolioDashboard {
  /// Returns a new [PortfolioDashboard] instance.
  PortfolioDashboard({
    required this.role,
    required this.currency,
    required this.leases,
    required this.vacant,
    required this.monthly,
    required this.debt,
    this.weightedRisk,
    this.band,
    required this.period,
    required this.expected,
    required this.received,
    this.cities = const [],
    required this.concentration,
    this.attention = const [],
    this.trend = const [],
  });

  Role role;

  String currency;

  int leases;

  int vacant;

  int monthly;

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

  /// YYYY-MM of the current month.
  String period;

  int expected;

  int received;

  List<PortfolioCity> cities;

  PortfolioDashboardConcentration concentration;

  List<PortfolioAttention> attention;

  List<PortfolioDashboardTrendInner> trend;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PortfolioDashboard &&
    other.role == role &&
    other.currency == currency &&
    other.leases == leases &&
    other.vacant == vacant &&
    other.monthly == monthly &&
    other.debt == debt &&
    other.weightedRisk == weightedRisk &&
    other.band == band &&
    other.period == period &&
    other.expected == expected &&
    other.received == received &&
    _deepEquality.equals(other.cities, cities) &&
    other.concentration == concentration &&
    _deepEquality.equals(other.attention, attention) &&
    _deepEquality.equals(other.trend, trend);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (role.hashCode) +
    (currency.hashCode) +
    (leases.hashCode) +
    (vacant.hashCode) +
    (monthly.hashCode) +
    (debt.hashCode) +
    (weightedRisk == null ? 0 : weightedRisk!.hashCode) +
    (band == null ? 0 : band!.hashCode) +
    (period.hashCode) +
    (expected.hashCode) +
    (received.hashCode) +
    (cities.hashCode) +
    (concentration.hashCode) +
    (attention.hashCode) +
    (trend.hashCode);

  @override
  String toString() => 'PortfolioDashboard[role=$role, currency=$currency, leases=$leases, vacant=$vacant, monthly=$monthly, debt=$debt, weightedRisk=$weightedRisk, band=$band, period=$period, expected=$expected, received=$received, cities=$cities, concentration=$concentration, attention=$attention, trend=$trend]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'role'] = this.role;
      json[r'currency'] = this.currency;
      json[r'leases'] = this.leases;
      json[r'vacant'] = this.vacant;
      json[r'monthly'] = this.monthly;
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
      json[r'period'] = this.period;
      json[r'expected'] = this.expected;
      json[r'received'] = this.received;
      json[r'cities'] = this.cities;
      json[r'concentration'] = this.concentration;
      json[r'attention'] = this.attention;
      json[r'trend'] = this.trend;
    return json;
  }

  /// Returns a new [PortfolioDashboard] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PortfolioDashboard? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PortfolioDashboard[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PortfolioDashboard[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PortfolioDashboard(
        role: Role.fromJson(json[r'role'])!,
        currency: mapValueOfType<String>(json, r'currency')!,
        leases: mapValueOfType<int>(json, r'leases')!,
        vacant: mapValueOfType<int>(json, r'vacant')!,
        monthly: mapValueOfType<int>(json, r'monthly')!,
        debt: mapValueOfType<int>(json, r'debt')!,
        weightedRisk: mapValueOfType<int>(json, r'weighted_risk'),
        band: RiskBand.fromJson(json[r'band']),
        period: mapValueOfType<String>(json, r'period')!,
        expected: mapValueOfType<int>(json, r'expected')!,
        received: mapValueOfType<int>(json, r'received')!,
        cities: PortfolioCity.listFromJson(json[r'cities']),
        concentration: PortfolioDashboardConcentration.fromJson(json[r'concentration'])!,
        attention: PortfolioAttention.listFromJson(json[r'attention']),
        trend: PortfolioDashboardTrendInner.listFromJson(json[r'trend']),
      );
    }
    return null;
  }

  static List<PortfolioDashboard> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PortfolioDashboard>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PortfolioDashboard.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PortfolioDashboard> mapFromJson(dynamic json) {
    final map = <String, PortfolioDashboard>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PortfolioDashboard.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PortfolioDashboard-objects as value to a dart map
  static Map<String, List<PortfolioDashboard>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PortfolioDashboard>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PortfolioDashboard.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'role',
    'currency',
    'leases',
    'vacant',
    'monthly',
    'debt',
    'period',
    'expected',
    'received',
    'cities',
    'concentration',
    'attention',
    'trend',
  };
}

