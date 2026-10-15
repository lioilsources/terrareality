//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class BankTransaction {
  /// Returns a new [BankTransaction] instance.
  BankTransaction({
    required this.id,
    required this.bookedOn,
    required this.amount,
    required this.currency,
    required this.variableSymbol,
    required this.specificSymbol,
    required this.counterpartyName,
    required this.remittance,
    required this.matchStatus,
    this.shareId,
    required this.matchNote,
  });

  String id;

  DateTime bookedOn;

  int amount;

  String currency;

  String variableSymbol;

  String specificSymbol;

  String counterpartyName;

  String remittance;

  BankTransactionMatchStatusEnum matchStatus;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? shareId;

  String matchNote;

  @override
  bool operator ==(Object other) => identical(this, other) || other is BankTransaction &&
    other.id == id &&
    other.bookedOn == bookedOn &&
    other.amount == amount &&
    other.currency == currency &&
    other.variableSymbol == variableSymbol &&
    other.specificSymbol == specificSymbol &&
    other.counterpartyName == counterpartyName &&
    other.remittance == remittance &&
    other.matchStatus == matchStatus &&
    other.shareId == shareId &&
    other.matchNote == matchNote;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (bookedOn.hashCode) +
    (amount.hashCode) +
    (currency.hashCode) +
    (variableSymbol.hashCode) +
    (specificSymbol.hashCode) +
    (counterpartyName.hashCode) +
    (remittance.hashCode) +
    (matchStatus.hashCode) +
    (shareId == null ? 0 : shareId!.hashCode) +
    (matchNote.hashCode);

  @override
  String toString() => 'BankTransaction[id=$id, bookedOn=$bookedOn, amount=$amount, currency=$currency, variableSymbol=$variableSymbol, specificSymbol=$specificSymbol, counterpartyName=$counterpartyName, remittance=$remittance, matchStatus=$matchStatus, shareId=$shareId, matchNote=$matchNote]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'booked_on'] = _dateFormatter.format(this.bookedOn.toUtc());
      json[r'amount'] = this.amount;
      json[r'currency'] = this.currency;
      json[r'variable_symbol'] = this.variableSymbol;
      json[r'specific_symbol'] = this.specificSymbol;
      json[r'counterparty_name'] = this.counterpartyName;
      json[r'remittance'] = this.remittance;
      json[r'match_status'] = this.matchStatus;
    if (this.shareId != null) {
      json[r'share_id'] = this.shareId;
    } else {
      json[r'share_id'] = null;
    }
      json[r'match_note'] = this.matchNote;
    return json;
  }

  /// Returns a new [BankTransaction] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static BankTransaction? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "BankTransaction[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "BankTransaction[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return BankTransaction(
        id: mapValueOfType<String>(json, r'id')!,
        bookedOn: mapDateTime(json, r'booked_on', r'')!,
        amount: mapValueOfType<int>(json, r'amount')!,
        currency: mapValueOfType<String>(json, r'currency')!,
        variableSymbol: mapValueOfType<String>(json, r'variable_symbol')!,
        specificSymbol: mapValueOfType<String>(json, r'specific_symbol')!,
        counterpartyName: mapValueOfType<String>(json, r'counterparty_name')!,
        remittance: mapValueOfType<String>(json, r'remittance')!,
        matchStatus: BankTransactionMatchStatusEnum.fromJson(json[r'match_status'])!,
        shareId: mapValueOfType<String>(json, r'share_id'),
        matchNote: mapValueOfType<String>(json, r'match_note')!,
      );
    }
    return null;
  }

  static List<BankTransaction> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <BankTransaction>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = BankTransaction.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, BankTransaction> mapFromJson(dynamic json) {
    final map = <String, BankTransaction>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = BankTransaction.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of BankTransaction-objects as value to a dart map
  static Map<String, List<BankTransaction>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<BankTransaction>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = BankTransaction.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'booked_on',
    'amount',
    'currency',
    'variable_symbol',
    'specific_symbol',
    'counterparty_name',
    'remittance',
    'match_status',
    'match_note',
  };
}


class BankTransactionMatchStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const BankTransactionMatchStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const unmatched = BankTransactionMatchStatusEnum._(r'unmatched');
  static const matched = BankTransactionMatchStatusEnum._(r'matched');
  static const suggested = BankTransactionMatchStatusEnum._(r'suggested');
  static const ignored = BankTransactionMatchStatusEnum._(r'ignored');

  /// List of all possible values in this [enum][BankTransactionMatchStatusEnum].
  static const values = <BankTransactionMatchStatusEnum>[
    unmatched,
    matched,
    suggested,
    ignored,
  ];

  static BankTransactionMatchStatusEnum? fromJson(dynamic value) => BankTransactionMatchStatusEnumTypeTransformer().decode(value);

  static List<BankTransactionMatchStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <BankTransactionMatchStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = BankTransactionMatchStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [BankTransactionMatchStatusEnum] to String,
/// and [decode] dynamic data back to [BankTransactionMatchStatusEnum].
class BankTransactionMatchStatusEnumTypeTransformer {
  factory BankTransactionMatchStatusEnumTypeTransformer() => _instance ??= const BankTransactionMatchStatusEnumTypeTransformer._();

  const BankTransactionMatchStatusEnumTypeTransformer._();

  String encode(BankTransactionMatchStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a BankTransactionMatchStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  BankTransactionMatchStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'unmatched': return BankTransactionMatchStatusEnum.unmatched;
        case r'matched': return BankTransactionMatchStatusEnum.matched;
        case r'suggested': return BankTransactionMatchStatusEnum.suggested;
        case r'ignored': return BankTransactionMatchStatusEnum.ignored;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [BankTransactionMatchStatusEnumTypeTransformer] instance.
  static BankTransactionMatchStatusEnumTypeTransformer? _instance;
}


