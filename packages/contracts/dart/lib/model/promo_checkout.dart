//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PromoCheckout {
  /// Returns a new [PromoCheckout] instance.
  PromoCheckout({
    required this.orderId,
    required this.checkoutUrl,
  });

  String orderId;

  String checkoutUrl;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PromoCheckout &&
    other.orderId == orderId &&
    other.checkoutUrl == checkoutUrl;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (orderId.hashCode) +
    (checkoutUrl.hashCode);

  @override
  String toString() => 'PromoCheckout[orderId=$orderId, checkoutUrl=$checkoutUrl]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'order_id'] = this.orderId;
      json[r'checkout_url'] = this.checkoutUrl;
    return json;
  }

  /// Returns a new [PromoCheckout] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PromoCheckout? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PromoCheckout[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PromoCheckout[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PromoCheckout(
        orderId: mapValueOfType<String>(json, r'order_id')!,
        checkoutUrl: mapValueOfType<String>(json, r'checkout_url')!,
      );
    }
    return null;
  }

  static List<PromoCheckout> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PromoCheckout>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PromoCheckout.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PromoCheckout> mapFromJson(dynamic json) {
    final map = <String, PromoCheckout>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PromoCheckout.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PromoCheckout-objects as value to a dart map
  static Map<String, List<PromoCheckout>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PromoCheckout>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PromoCheckout.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'order_id',
    'checkout_url',
  };
}

