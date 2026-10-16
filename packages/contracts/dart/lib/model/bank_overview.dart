//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class BankOverview {
  /// Returns a new [BankOverview] instance.
  BankOverview({
    this.connections = const [],
    this.transactions = const [],
    this.transactionsNextBefore,
  });

  List<BankConnection> connections;

  List<BankTransaction> transactions;

  /// Cursor of the next page of transactions (absent on the last page).
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? transactionsNextBefore;

  @override
  bool operator ==(Object other) => identical(this, other) || other is BankOverview &&
    _deepEquality.equals(other.connections, connections) &&
    _deepEquality.equals(other.transactions, transactions) &&
    other.transactionsNextBefore == transactionsNextBefore;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (connections.hashCode) +
    (transactions.hashCode) +
    (transactionsNextBefore == null ? 0 : transactionsNextBefore!.hashCode);

  @override
  String toString() => 'BankOverview[connections=$connections, transactions=$transactions, transactionsNextBefore=$transactionsNextBefore]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'connections'] = this.connections;
      json[r'transactions'] = this.transactions;
    if (this.transactionsNextBefore != null) {
      json[r'transactions_next_before'] = this.transactionsNextBefore;
    } else {
      json[r'transactions_next_before'] = null;
    }
    return json;
  }

  /// Returns a new [BankOverview] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static BankOverview? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "BankOverview[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "BankOverview[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return BankOverview(
        connections: BankConnection.listFromJson(json[r'connections']),
        transactions: BankTransaction.listFromJson(json[r'transactions']),
        transactionsNextBefore: mapValueOfType<String>(json, r'transactions_next_before'),
      );
    }
    return null;
  }

  static List<BankOverview> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <BankOverview>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = BankOverview.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, BankOverview> mapFromJson(dynamic json) {
    final map = <String, BankOverview>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = BankOverview.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of BankOverview-objects as value to a dart map
  static Map<String, List<BankOverview>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<BankOverview>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = BankOverview.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'connections',
    'transactions',
  };
}

