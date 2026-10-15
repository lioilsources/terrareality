//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ObligationShare {
  /// Returns a new [ObligationShare] instance.
  ObligationShare({
    required this.id,
    required this.obligationId,
    required this.kind,
    required this.period,
    required this.dueOn,
    required this.amount,
    required this.paidAmount,
    required this.currency,
    required this.partyId,
    required this.partyName,
    required this.mine,
    required this.status,
    this.spayd,
  });

  /// Share id.
  String id;

  String obligationId;

  ObligationShareKindEnum kind;

  String period;

  DateTime dueOn;

  int amount;

  int paidAmount;

  String currency;

  String partyId;

  String partyName;

  bool mine;

  ObligationShareStatusEnum status;

  /// QR Platba payload for the open amount.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? spayd;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ObligationShare &&
    other.id == id &&
    other.obligationId == obligationId &&
    other.kind == kind &&
    other.period == period &&
    other.dueOn == dueOn &&
    other.amount == amount &&
    other.paidAmount == paidAmount &&
    other.currency == currency &&
    other.partyId == partyId &&
    other.partyName == partyName &&
    other.mine == mine &&
    other.status == status &&
    other.spayd == spayd;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (obligationId.hashCode) +
    (kind.hashCode) +
    (period.hashCode) +
    (dueOn.hashCode) +
    (amount.hashCode) +
    (paidAmount.hashCode) +
    (currency.hashCode) +
    (partyId.hashCode) +
    (partyName.hashCode) +
    (mine.hashCode) +
    (status.hashCode) +
    (spayd == null ? 0 : spayd!.hashCode);

  @override
  String toString() => 'ObligationShare[id=$id, obligationId=$obligationId, kind=$kind, period=$period, dueOn=$dueOn, amount=$amount, paidAmount=$paidAmount, currency=$currency, partyId=$partyId, partyName=$partyName, mine=$mine, status=$status, spayd=$spayd]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'obligation_id'] = this.obligationId;
      json[r'kind'] = this.kind;
      json[r'period'] = this.period;
      json[r'due_on'] = _dateFormatter.format(this.dueOn.toUtc());
      json[r'amount'] = this.amount;
      json[r'paid_amount'] = this.paidAmount;
      json[r'currency'] = this.currency;
      json[r'party_id'] = this.partyId;
      json[r'party_name'] = this.partyName;
      json[r'mine'] = this.mine;
      json[r'status'] = this.status;
    if (this.spayd != null) {
      json[r'spayd'] = this.spayd;
    } else {
      json[r'spayd'] = null;
    }
    return json;
  }

  /// Returns a new [ObligationShare] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ObligationShare? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ObligationShare[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ObligationShare[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ObligationShare(
        id: mapValueOfType<String>(json, r'id')!,
        obligationId: mapValueOfType<String>(json, r'obligation_id')!,
        kind: ObligationShareKindEnum.fromJson(json[r'kind'])!,
        period: mapValueOfType<String>(json, r'period')!,
        dueOn: mapDateTime(json, r'due_on', r'')!,
        amount: mapValueOfType<int>(json, r'amount')!,
        paidAmount: mapValueOfType<int>(json, r'paid_amount')!,
        currency: mapValueOfType<String>(json, r'currency')!,
        partyId: mapValueOfType<String>(json, r'party_id')!,
        partyName: mapValueOfType<String>(json, r'party_name')!,
        mine: mapValueOfType<bool>(json, r'mine')!,
        status: ObligationShareStatusEnum.fromJson(json[r'status'])!,
        spayd: mapValueOfType<String>(json, r'spayd'),
      );
    }
    return null;
  }

  static List<ObligationShare> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ObligationShare>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ObligationShare.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ObligationShare> mapFromJson(dynamic json) {
    final map = <String, ObligationShare>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ObligationShare.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ObligationShare-objects as value to a dart map
  static Map<String, List<ObligationShare>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ObligationShare>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ObligationShare.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'obligation_id',
    'kind',
    'period',
    'due_on',
    'amount',
    'paid_amount',
    'currency',
    'party_id',
    'party_name',
    'mine',
    'status',
  };
}


class ObligationShareKindEnum {
  /// Instantiate a new enum with the provided [value].
  const ObligationShareKindEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const rent = ObligationShareKindEnum._(r'rent');
  static const services = ObligationShareKindEnum._(r'services');
  static const deposit = ObligationShareKindEnum._(r'deposit');
  static const oneoff = ObligationShareKindEnum._(r'oneoff');

  /// List of all possible values in this [enum][ObligationShareKindEnum].
  static const values = <ObligationShareKindEnum>[
    rent,
    services,
    deposit,
    oneoff,
  ];

  static ObligationShareKindEnum? fromJson(dynamic value) => ObligationShareKindEnumTypeTransformer().decode(value);

  static List<ObligationShareKindEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ObligationShareKindEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ObligationShareKindEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ObligationShareKindEnum] to String,
/// and [decode] dynamic data back to [ObligationShareKindEnum].
class ObligationShareKindEnumTypeTransformer {
  factory ObligationShareKindEnumTypeTransformer() => _instance ??= const ObligationShareKindEnumTypeTransformer._();

  const ObligationShareKindEnumTypeTransformer._();

  String encode(ObligationShareKindEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a ObligationShareKindEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ObligationShareKindEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'rent': return ObligationShareKindEnum.rent;
        case r'services': return ObligationShareKindEnum.services;
        case r'deposit': return ObligationShareKindEnum.deposit;
        case r'oneoff': return ObligationShareKindEnum.oneoff;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ObligationShareKindEnumTypeTransformer] instance.
  static ObligationShareKindEnumTypeTransformer? _instance;
}



class ObligationShareStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const ObligationShareStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const open = ObligationShareStatusEnum._(r'open');
  static const paid = ObligationShareStatusEnum._(r'paid');
  static const cancelled = ObligationShareStatusEnum._(r'cancelled');

  /// List of all possible values in this [enum][ObligationShareStatusEnum].
  static const values = <ObligationShareStatusEnum>[
    open,
    paid,
    cancelled,
  ];

  static ObligationShareStatusEnum? fromJson(dynamic value) => ObligationShareStatusEnumTypeTransformer().decode(value);

  static List<ObligationShareStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ObligationShareStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ObligationShareStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ObligationShareStatusEnum] to String,
/// and [decode] dynamic data back to [ObligationShareStatusEnum].
class ObligationShareStatusEnumTypeTransformer {
  factory ObligationShareStatusEnumTypeTransformer() => _instance ??= const ObligationShareStatusEnumTypeTransformer._();

  const ObligationShareStatusEnumTypeTransformer._();

  String encode(ObligationShareStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a ObligationShareStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ObligationShareStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'open': return ObligationShareStatusEnum.open;
        case r'paid': return ObligationShareStatusEnum.paid;
        case r'cancelled': return ObligationShareStatusEnum.cancelled;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ObligationShareStatusEnumTypeTransformer] instance.
  static ObligationShareStatusEnumTypeTransformer? _instance;
}


