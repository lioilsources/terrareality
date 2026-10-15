//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Order {
  /// Returns a new [Order] instance.
  Order({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.productCode,
    required this.status,
    required this.netAmount,
    required this.vatAmount,
    required this.grossAmount,
    required this.currency,
    required this.startsAt,
    required this.createdAt,
    this.paidAt,
    this.invoiceId,
  });

  String id;

  String listingId;

  /// In the caller's locale.
  String listingTitle;

  String productCode;

  OrderStatus status;

  int netAmount;

  int vatAmount;

  int grossAmount;

  String currency;

  DateTime startsAt;

  DateTime createdAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? paidAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? invoiceId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Order &&
    other.id == id &&
    other.listingId == listingId &&
    other.listingTitle == listingTitle &&
    other.productCode == productCode &&
    other.status == status &&
    other.netAmount == netAmount &&
    other.vatAmount == vatAmount &&
    other.grossAmount == grossAmount &&
    other.currency == currency &&
    other.startsAt == startsAt &&
    other.createdAt == createdAt &&
    other.paidAt == paidAt &&
    other.invoiceId == invoiceId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (listingId.hashCode) +
    (listingTitle.hashCode) +
    (productCode.hashCode) +
    (status.hashCode) +
    (netAmount.hashCode) +
    (vatAmount.hashCode) +
    (grossAmount.hashCode) +
    (currency.hashCode) +
    (startsAt.hashCode) +
    (createdAt.hashCode) +
    (paidAt == null ? 0 : paidAt!.hashCode) +
    (invoiceId == null ? 0 : invoiceId!.hashCode);

  @override
  String toString() => 'Order[id=$id, listingId=$listingId, listingTitle=$listingTitle, productCode=$productCode, status=$status, netAmount=$netAmount, vatAmount=$vatAmount, grossAmount=$grossAmount, currency=$currency, startsAt=$startsAt, createdAt=$createdAt, paidAt=$paidAt, invoiceId=$invoiceId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'listing_id'] = this.listingId;
      json[r'listing_title'] = this.listingTitle;
      json[r'product_code'] = this.productCode;
      json[r'status'] = this.status;
      json[r'net_amount'] = this.netAmount;
      json[r'vat_amount'] = this.vatAmount;
      json[r'gross_amount'] = this.grossAmount;
      json[r'currency'] = this.currency;
      json[r'starts_at'] = this.startsAt.toUtc().toIso8601String();
      json[r'created_at'] = this.createdAt.toUtc().toIso8601String();
    if (this.paidAt != null) {
      json[r'paid_at'] = this.paidAt!.toUtc().toIso8601String();
    } else {
      json[r'paid_at'] = null;
    }
    if (this.invoiceId != null) {
      json[r'invoice_id'] = this.invoiceId;
    } else {
      json[r'invoice_id'] = null;
    }
    return json;
  }

  /// Returns a new [Order] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Order? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "Order[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "Order[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Order(
        id: mapValueOfType<String>(json, r'id')!,
        listingId: mapValueOfType<String>(json, r'listing_id')!,
        listingTitle: mapValueOfType<String>(json, r'listing_title')!,
        productCode: mapValueOfType<String>(json, r'product_code')!,
        status: OrderStatus.fromJson(json[r'status'])!,
        netAmount: mapValueOfType<int>(json, r'net_amount')!,
        vatAmount: mapValueOfType<int>(json, r'vat_amount')!,
        grossAmount: mapValueOfType<int>(json, r'gross_amount')!,
        currency: mapValueOfType<String>(json, r'currency')!,
        startsAt: mapDateTime(json, r'starts_at', r'')!,
        createdAt: mapDateTime(json, r'created_at', r'')!,
        paidAt: mapDateTime(json, r'paid_at', r''),
        invoiceId: mapValueOfType<String>(json, r'invoice_id'),
      );
    }
    return null;
  }

  static List<Order> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Order>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Order.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Order> mapFromJson(dynamic json) {
    final map = <String, Order>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Order.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Order-objects as value to a dart map
  static Map<String, List<Order>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Order>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Order.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'listing_id',
    'listing_title',
    'product_code',
    'status',
    'net_amount',
    'vat_amount',
    'gross_amount',
    'currency',
    'starts_at',
    'created_at',
  };
}

