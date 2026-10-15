//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Invoice {
  /// Returns a new [Invoice] instance.
  Invoice({
    required this.id,
    required this.number,
    required this.orderId,
    required this.issuedOn,
    required this.taxableSupplyOn,
    required this.netAmount,
    required this.vatAmount,
    required this.grossAmount,
    required this.currency,
    required this.vatRateBp,
    this.sentAt,
  });

  String id;

  /// TR-YYYY-000001
  String number;

  String orderId;

  DateTime issuedOn;

  /// Datum uskutečnění zdanitelného plnění.
  DateTime taxableSupplyOn;

  int netAmount;

  int vatAmount;

  int grossAmount;

  String currency;

  int vatRateBp;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? sentAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Invoice &&
    other.id == id &&
    other.number == number &&
    other.orderId == orderId &&
    other.issuedOn == issuedOn &&
    other.taxableSupplyOn == taxableSupplyOn &&
    other.netAmount == netAmount &&
    other.vatAmount == vatAmount &&
    other.grossAmount == grossAmount &&
    other.currency == currency &&
    other.vatRateBp == vatRateBp &&
    other.sentAt == sentAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (number.hashCode) +
    (orderId.hashCode) +
    (issuedOn.hashCode) +
    (taxableSupplyOn.hashCode) +
    (netAmount.hashCode) +
    (vatAmount.hashCode) +
    (grossAmount.hashCode) +
    (currency.hashCode) +
    (vatRateBp.hashCode) +
    (sentAt == null ? 0 : sentAt!.hashCode);

  @override
  String toString() => 'Invoice[id=$id, number=$number, orderId=$orderId, issuedOn=$issuedOn, taxableSupplyOn=$taxableSupplyOn, netAmount=$netAmount, vatAmount=$vatAmount, grossAmount=$grossAmount, currency=$currency, vatRateBp=$vatRateBp, sentAt=$sentAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'number'] = this.number;
      json[r'order_id'] = this.orderId;
      json[r'issued_on'] = _dateFormatter.format(this.issuedOn.toUtc());
      json[r'taxable_supply_on'] = _dateFormatter.format(this.taxableSupplyOn.toUtc());
      json[r'net_amount'] = this.netAmount;
      json[r'vat_amount'] = this.vatAmount;
      json[r'gross_amount'] = this.grossAmount;
      json[r'currency'] = this.currency;
      json[r'vat_rate_bp'] = this.vatRateBp;
    if (this.sentAt != null) {
      json[r'sent_at'] = this.sentAt!.toUtc().toIso8601String();
    } else {
      json[r'sent_at'] = null;
    }
    return json;
  }

  /// Returns a new [Invoice] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Invoice? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "Invoice[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "Invoice[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Invoice(
        id: mapValueOfType<String>(json, r'id')!,
        number: mapValueOfType<String>(json, r'number')!,
        orderId: mapValueOfType<String>(json, r'order_id')!,
        issuedOn: mapDateTime(json, r'issued_on', r'')!,
        taxableSupplyOn: mapDateTime(json, r'taxable_supply_on', r'')!,
        netAmount: mapValueOfType<int>(json, r'net_amount')!,
        vatAmount: mapValueOfType<int>(json, r'vat_amount')!,
        grossAmount: mapValueOfType<int>(json, r'gross_amount')!,
        currency: mapValueOfType<String>(json, r'currency')!,
        vatRateBp: mapValueOfType<int>(json, r'vat_rate_bp')!,
        sentAt: mapDateTime(json, r'sent_at', r''),
      );
    }
    return null;
  }

  static List<Invoice> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Invoice>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Invoice.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Invoice> mapFromJson(dynamic json) {
    final map = <String, Invoice>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Invoice.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Invoice-objects as value to a dart map
  static Map<String, List<Invoice>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Invoice>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Invoice.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'number',
    'order_id',
    'issued_on',
    'taxable_supply_on',
    'net_amount',
    'vat_amount',
    'gross_amount',
    'currency',
    'vat_rate_bp',
  };
}

