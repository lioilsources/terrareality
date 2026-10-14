//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Jurisdiction {
  /// Returns a new [Jurisdiction] instance.
  Jurisdiction({
    required this.code,
    this.name = const {},
    required this.currency,
    required this.defaultLocale,
    required this.depositMaxMonths,
    required this.noticePeriodMonths,
    required this.signatureProvider,
    required this.identityProvider,
    this.addressFormat = const {},
    this.rules = const {},
  });

  String code;

  Map<String, String> name;

  String currency;

  String defaultLocale;

  int depositMaxMonths;

  int noticePeriodMonths;

  String signatureProvider;

  String identityProvider;

  Map<String, Object> addressFormat;

  Map<String, Object> rules;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Jurisdiction &&
    other.code == code &&
    _deepEquality.equals(other.name, name) &&
    other.currency == currency &&
    other.defaultLocale == defaultLocale &&
    other.depositMaxMonths == depositMaxMonths &&
    other.noticePeriodMonths == noticePeriodMonths &&
    other.signatureProvider == signatureProvider &&
    other.identityProvider == identityProvider &&
    _deepEquality.equals(other.addressFormat, addressFormat) &&
    _deepEquality.equals(other.rules, rules);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (code.hashCode) +
    (name.hashCode) +
    (currency.hashCode) +
    (defaultLocale.hashCode) +
    (depositMaxMonths.hashCode) +
    (noticePeriodMonths.hashCode) +
    (signatureProvider.hashCode) +
    (identityProvider.hashCode) +
    (addressFormat.hashCode) +
    (rules.hashCode);

  @override
  String toString() => 'Jurisdiction[code=$code, name=$name, currency=$currency, defaultLocale=$defaultLocale, depositMaxMonths=$depositMaxMonths, noticePeriodMonths=$noticePeriodMonths, signatureProvider=$signatureProvider, identityProvider=$identityProvider, addressFormat=$addressFormat, rules=$rules]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'code'] = this.code;
      json[r'name'] = this.name;
      json[r'currency'] = this.currency;
      json[r'default_locale'] = this.defaultLocale;
      json[r'deposit_max_months'] = this.depositMaxMonths;
      json[r'notice_period_months'] = this.noticePeriodMonths;
      json[r'signature_provider'] = this.signatureProvider;
      json[r'identity_provider'] = this.identityProvider;
      json[r'address_format'] = this.addressFormat;
      json[r'rules'] = this.rules;
    return json;
  }

  /// Returns a new [Jurisdiction] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Jurisdiction? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "Jurisdiction[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "Jurisdiction[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Jurisdiction(
        code: mapValueOfType<String>(json, r'code')!,
        name: mapCastOfType<String, String>(json, r'name')!,
        currency: mapValueOfType<String>(json, r'currency')!,
        defaultLocale: mapValueOfType<String>(json, r'default_locale')!,
        depositMaxMonths: mapValueOfType<int>(json, r'deposit_max_months')!,
        noticePeriodMonths: mapValueOfType<int>(json, r'notice_period_months')!,
        signatureProvider: mapValueOfType<String>(json, r'signature_provider')!,
        identityProvider: mapValueOfType<String>(json, r'identity_provider')!,
        addressFormat: mapCastOfType<String, Object>(json, r'address_format')!,
        rules: mapCastOfType<String, Object>(json, r'rules')!,
      );
    }
    return null;
  }

  static List<Jurisdiction> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Jurisdiction>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Jurisdiction.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Jurisdiction> mapFromJson(dynamic json) {
    final map = <String, Jurisdiction>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Jurisdiction.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Jurisdiction-objects as value to a dart map
  static Map<String, List<Jurisdiction>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Jurisdiction>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Jurisdiction.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'code',
    'name',
    'currency',
    'default_locale',
    'deposit_max_months',
    'notice_period_months',
    'signature_provider',
    'identity_provider',
    'address_format',
    'rules',
  };
}

