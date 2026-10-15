//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PromoProductInput {
  /// Returns a new [PromoProductInput] instance.
  PromoProductInput({
    required this.code,
    required this.kind,
    required this.durationDays,
    required this.netAmount,
    this.currency = 'CZK',
    this.vatRateBp = 2100,
    required this.name,
    this.active = true,
  });

  String code;

  PromoProductKind kind;

  /// Minimum value: 1
  /// Maximum value: 365
  int durationDays;

  /// Minimum value: 0
  int netAmount;

  String currency;

  /// Minimum value: 0
  /// Maximum value: 10000
  int vatRateBp;

  I18nText name;

  bool active;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PromoProductInput &&
    other.code == code &&
    other.kind == kind &&
    other.durationDays == durationDays &&
    other.netAmount == netAmount &&
    other.currency == currency &&
    other.vatRateBp == vatRateBp &&
    other.name == name &&
    other.active == active;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (code.hashCode) +
    (kind.hashCode) +
    (durationDays.hashCode) +
    (netAmount.hashCode) +
    (currency.hashCode) +
    (vatRateBp.hashCode) +
    (name.hashCode) +
    (active.hashCode);

  @override
  String toString() => 'PromoProductInput[code=$code, kind=$kind, durationDays=$durationDays, netAmount=$netAmount, currency=$currency, vatRateBp=$vatRateBp, name=$name, active=$active]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'code'] = this.code;
      json[r'kind'] = this.kind;
      json[r'duration_days'] = this.durationDays;
      json[r'net_amount'] = this.netAmount;
      json[r'currency'] = this.currency;
      json[r'vat_rate_bp'] = this.vatRateBp;
      json[r'name'] = this.name;
      json[r'active'] = this.active;
    return json;
  }

  /// Returns a new [PromoProductInput] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PromoProductInput? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PromoProductInput[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PromoProductInput[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PromoProductInput(
        code: mapValueOfType<String>(json, r'code')!,
        kind: PromoProductKind.fromJson(json[r'kind'])!,
        durationDays: mapValueOfType<int>(json, r'duration_days')!,
        netAmount: mapValueOfType<int>(json, r'net_amount')!,
        currency: mapValueOfType<String>(json, r'currency') ?? 'CZK',
        vatRateBp: mapValueOfType<int>(json, r'vat_rate_bp') ?? 2100,
        name: I18nText.fromJson(json[r'name'])!,
        active: mapValueOfType<bool>(json, r'active') ?? true,
      );
    }
    return null;
  }

  static List<PromoProductInput> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PromoProductInput>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PromoProductInput.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PromoProductInput> mapFromJson(dynamic json) {
    final map = <String, PromoProductInput>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PromoProductInput.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PromoProductInput-objects as value to a dart map
  static Map<String, List<PromoProductInput>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PromoProductInput>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PromoProductInput.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'code',
    'kind',
    'duration_days',
    'net_amount',
    'name',
  };
}

