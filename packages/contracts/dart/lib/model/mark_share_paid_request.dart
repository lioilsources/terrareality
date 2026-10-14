//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class MarkSharePaidRequest {
  /// Returns a new [MarkSharePaidRequest] instance.
  MarkSharePaidRequest({
    this.amount,
    this.paidOn,
  });

  /// Default is the open amount.
  ///
  /// Minimum value: 1
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? amount;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? paidOn;

  @override
  bool operator ==(Object other) => identical(this, other) || other is MarkSharePaidRequest &&
    other.amount == amount &&
    other.paidOn == paidOn;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (amount == null ? 0 : amount!.hashCode) +
    (paidOn == null ? 0 : paidOn!.hashCode);

  @override
  String toString() => 'MarkSharePaidRequest[amount=$amount, paidOn=$paidOn]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.amount != null) {
      json[r'amount'] = this.amount;
    } else {
      json[r'amount'] = null;
    }
    if (this.paidOn != null) {
      json[r'paid_on'] = _dateFormatter.format(this.paidOn!.toUtc());
    } else {
      json[r'paid_on'] = null;
    }
    return json;
  }

  /// Returns a new [MarkSharePaidRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MarkSharePaidRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "MarkSharePaidRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "MarkSharePaidRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return MarkSharePaidRequest(
        amount: mapValueOfType<int>(json, r'amount'),
        paidOn: mapDateTime(json, r'paid_on', r''),
      );
    }
    return null;
  }

  static List<MarkSharePaidRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MarkSharePaidRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MarkSharePaidRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MarkSharePaidRequest> mapFromJson(dynamic json) {
    final map = <String, MarkSharePaidRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MarkSharePaidRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MarkSharePaidRequest-objects as value to a dart map
  static Map<String, List<MarkSharePaidRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<MarkSharePaidRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MarkSharePaidRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

