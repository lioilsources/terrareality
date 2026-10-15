//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PromoProduct {
  /// Returns a new [PromoProduct] instance.
  PromoProduct({
    required this.id,
    required this.code,
    required this.kind,
    required this.durationDays,
    required this.netAmount,
    required this.vatRateBp,
    required this.vatAmount,
    required this.grossAmount,
    required this.currency,
    required this.name,
    required this.active,
  });

  String id;

  String code;

  PromoProductKind kind;

  int durationDays;

  /// Net price in minor units.
  int netAmount;

  /// VAT rate in basis points (2100 = 21 %).
  int vatRateBp;

  int vatAmount;

  int grossAmount;

  String currency;

  I18nText name;

  bool active;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PromoProduct &&
    other.id == id &&
    other.code == code &&
    other.kind == kind &&
    other.durationDays == durationDays &&
    other.netAmount == netAmount &&
    other.vatRateBp == vatRateBp &&
    other.vatAmount == vatAmount &&
    other.grossAmount == grossAmount &&
    other.currency == currency &&
    other.name == name &&
    other.active == active;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (code.hashCode) +
    (kind.hashCode) +
    (durationDays.hashCode) +
    (netAmount.hashCode) +
    (vatRateBp.hashCode) +
    (vatAmount.hashCode) +
    (grossAmount.hashCode) +
    (currency.hashCode) +
    (name.hashCode) +
    (active.hashCode);

  @override
  String toString() => 'PromoProduct[id=$id, code=$code, kind=$kind, durationDays=$durationDays, netAmount=$netAmount, vatRateBp=$vatRateBp, vatAmount=$vatAmount, grossAmount=$grossAmount, currency=$currency, name=$name, active=$active]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'code'] = this.code;
      json[r'kind'] = this.kind;
      json[r'duration_days'] = this.durationDays;
      json[r'net_amount'] = this.netAmount;
      json[r'vat_rate_bp'] = this.vatRateBp;
      json[r'vat_amount'] = this.vatAmount;
      json[r'gross_amount'] = this.grossAmount;
      json[r'currency'] = this.currency;
      json[r'name'] = this.name;
      json[r'active'] = this.active;
    return json;
  }

  /// Returns a new [PromoProduct] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PromoProduct? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PromoProduct[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PromoProduct[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PromoProduct(
        id: mapValueOfType<String>(json, r'id')!,
        code: mapValueOfType<String>(json, r'code')!,
        kind: PromoProductKind.fromJson(json[r'kind'])!,
        durationDays: mapValueOfType<int>(json, r'duration_days')!,
        netAmount: mapValueOfType<int>(json, r'net_amount')!,
        vatRateBp: mapValueOfType<int>(json, r'vat_rate_bp')!,
        vatAmount: mapValueOfType<int>(json, r'vat_amount')!,
        grossAmount: mapValueOfType<int>(json, r'gross_amount')!,
        currency: mapValueOfType<String>(json, r'currency')!,
        name: I18nText.fromJson(json[r'name'])!,
        active: mapValueOfType<bool>(json, r'active')!,
      );
    }
    return null;
  }

  static List<PromoProduct> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PromoProduct>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PromoProduct.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PromoProduct> mapFromJson(dynamic json) {
    final map = <String, PromoProduct>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PromoProduct.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PromoProduct-objects as value to a dart map
  static Map<String, List<PromoProduct>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PromoProduct>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PromoProduct.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'code',
    'kind',
    'duration_days',
    'net_amount',
    'vat_rate_bp',
    'vat_amount',
    'gross_amount',
    'currency',
    'name',
    'active',
  };
}

