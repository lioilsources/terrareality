//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class InvoiceList {
  /// Returns a new [InvoiceList] instance.
  InvoiceList({
    this.items = const [],
    this.nextBefore,
  });

  List<Invoice> items;

  /// Cursor of the next page (absent on the last page).
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? nextBefore;

  @override
  bool operator ==(Object other) => identical(this, other) || other is InvoiceList &&
    _deepEquality.equals(other.items, items) &&
    other.nextBefore == nextBefore;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (items.hashCode) +
    (nextBefore == null ? 0 : nextBefore!.hashCode);

  @override
  String toString() => 'InvoiceList[items=$items, nextBefore=$nextBefore]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'items'] = this.items;
    if (this.nextBefore != null) {
      json[r'next_before'] = this.nextBefore;
    } else {
      json[r'next_before'] = null;
    }
    return json;
  }

  /// Returns a new [InvoiceList] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static InvoiceList? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "InvoiceList[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "InvoiceList[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return InvoiceList(
        items: Invoice.listFromJson(json[r'items']),
        nextBefore: mapValueOfType<String>(json, r'next_before'),
      );
    }
    return null;
  }

  static List<InvoiceList> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <InvoiceList>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = InvoiceList.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, InvoiceList> mapFromJson(dynamic json) {
    final map = <String, InvoiceList>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = InvoiceList.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of InvoiceList-objects as value to a dart map
  static Map<String, List<InvoiceList>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<InvoiceList>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = InvoiceList.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'items',
  };
}

