//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class RentRollTotals {
  /// Returns a new [RentRollTotals] instance.
  RentRollTotals({
    required this.leases,
    required this.vacant,
    required this.monthly,
    required this.billed,
    required this.paid,
    required this.debt,
  });

  int leases;

  int vacant;

  int monthly;

  int billed;

  int paid;

  int debt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RentRollTotals &&
    other.leases == leases &&
    other.vacant == vacant &&
    other.monthly == monthly &&
    other.billed == billed &&
    other.paid == paid &&
    other.debt == debt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (leases.hashCode) +
    (vacant.hashCode) +
    (monthly.hashCode) +
    (billed.hashCode) +
    (paid.hashCode) +
    (debt.hashCode);

  @override
  String toString() => 'RentRollTotals[leases=$leases, vacant=$vacant, monthly=$monthly, billed=$billed, paid=$paid, debt=$debt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'leases'] = this.leases;
      json[r'vacant'] = this.vacant;
      json[r'monthly'] = this.monthly;
      json[r'billed'] = this.billed;
      json[r'paid'] = this.paid;
      json[r'debt'] = this.debt;
    return json;
  }

  /// Returns a new [RentRollTotals] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RentRollTotals? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "RentRollTotals[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "RentRollTotals[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return RentRollTotals(
        leases: mapValueOfType<int>(json, r'leases')!,
        vacant: mapValueOfType<int>(json, r'vacant')!,
        monthly: mapValueOfType<int>(json, r'monthly')!,
        billed: mapValueOfType<int>(json, r'billed')!,
        paid: mapValueOfType<int>(json, r'paid')!,
        debt: mapValueOfType<int>(json, r'debt')!,
      );
    }
    return null;
  }

  static List<RentRollTotals> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RentRollTotals>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RentRollTotals.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RentRollTotals> mapFromJson(dynamic json) {
    final map = <String, RentRollTotals>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RentRollTotals.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RentRollTotals-objects as value to a dart map
  static Map<String, List<RentRollTotals>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RentRollTotals>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RentRollTotals.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'leases',
    'vacant',
    'monthly',
    'billed',
    'paid',
    'debt',
  };
}

