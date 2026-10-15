//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class LedgerEntry {
  /// Returns a new [LedgerEntry] instance.
  LedgerEntry({
    required this.postingId,
    required this.account,
    this.partyName,
    required this.amount,
    required this.memo,
    required this.bookedOn,
  });

  String postingId;

  LedgerEntryAccountEnum account;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? partyName;

  /// Debit positive, credit negative.
  int amount;

  String memo;

  DateTime bookedOn;

  @override
  bool operator ==(Object other) => identical(this, other) || other is LedgerEntry &&
    other.postingId == postingId &&
    other.account == account &&
    other.partyName == partyName &&
    other.amount == amount &&
    other.memo == memo &&
    other.bookedOn == bookedOn;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (postingId.hashCode) +
    (account.hashCode) +
    (partyName == null ? 0 : partyName!.hashCode) +
    (amount.hashCode) +
    (memo.hashCode) +
    (bookedOn.hashCode);

  @override
  String toString() => 'LedgerEntry[postingId=$postingId, account=$account, partyName=$partyName, amount=$amount, memo=$memo, bookedOn=$bookedOn]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'posting_id'] = this.postingId;
      json[r'account'] = this.account;
    if (this.partyName != null) {
      json[r'party_name'] = this.partyName;
    } else {
      json[r'party_name'] = null;
    }
      json[r'amount'] = this.amount;
      json[r'memo'] = this.memo;
      json[r'booked_on'] = _dateFormatter.format(this.bookedOn.toUtc());
    return json;
  }

  /// Returns a new [LedgerEntry] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LedgerEntry? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "LedgerEntry[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "LedgerEntry[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return LedgerEntry(
        postingId: mapValueOfType<String>(json, r'posting_id')!,
        account: LedgerEntryAccountEnum.fromJson(json[r'account'])!,
        partyName: mapValueOfType<String>(json, r'party_name'),
        amount: mapValueOfType<int>(json, r'amount')!,
        memo: mapValueOfType<String>(json, r'memo')!,
        bookedOn: mapDateTime(json, r'booked_on', r'')!,
      );
    }
    return null;
  }

  static List<LedgerEntry> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LedgerEntry>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LedgerEntry.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LedgerEntry> mapFromJson(dynamic json) {
    final map = <String, LedgerEntry>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LedgerEntry.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LedgerEntry-objects as value to a dart map
  static Map<String, List<LedgerEntry>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<LedgerEntry>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LedgerEntry.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'posting_id',
    'account',
    'amount',
    'memo',
    'booked_on',
  };
}


class LedgerEntryAccountEnum {
  /// Instantiate a new enum with the provided [value].
  const LedgerEntryAccountEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const receivable = LedgerEntryAccountEnum._(r'receivable');
  static const income = LedgerEntryAccountEnum._(r'income');
  static const depositHeld = LedgerEntryAccountEnum._(r'deposit_held');
  static const cash = LedgerEntryAccountEnum._(r'cash');

  /// List of all possible values in this [enum][LedgerEntryAccountEnum].
  static const values = <LedgerEntryAccountEnum>[
    receivable,
    income,
    depositHeld,
    cash,
  ];

  static LedgerEntryAccountEnum? fromJson(dynamic value) => LedgerEntryAccountEnumTypeTransformer().decode(value);

  static List<LedgerEntryAccountEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LedgerEntryAccountEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LedgerEntryAccountEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [LedgerEntryAccountEnum] to String,
/// and [decode] dynamic data back to [LedgerEntryAccountEnum].
class LedgerEntryAccountEnumTypeTransformer {
  factory LedgerEntryAccountEnumTypeTransformer() => _instance ??= const LedgerEntryAccountEnumTypeTransformer._();

  const LedgerEntryAccountEnumTypeTransformer._();

  String encode(LedgerEntryAccountEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a LedgerEntryAccountEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  LedgerEntryAccountEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'receivable': return LedgerEntryAccountEnum.receivable;
        case r'income': return LedgerEntryAccountEnum.income;
        case r'deposit_held': return LedgerEntryAccountEnum.depositHeld;
        case r'cash': return LedgerEntryAccountEnum.cash;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [LedgerEntryAccountEnumTypeTransformer] instance.
  static LedgerEntryAccountEnumTypeTransformer? _instance;
}


