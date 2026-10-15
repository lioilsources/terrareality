//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class RentRollRow {
  /// Returns a new [RentRollRow] instance.
  RentRollRow({
    required this.kind,
    this.leaseId,
    this.unitId,
    this.code,
    required this.state,
    required this.municipality,
    required this.municipalityPath,
    required this.region,
    this.regionPath,
    required this.address,
    required this.unit,
    this.tenants,
    this.rent,
    this.services,
    required this.currency,
    this.dueDay,
    this.startsOn,
    this.endsOn,
    this.noticeOn,
    this.deposit,
    this.depositPaid,
    this.billed,
    this.paid,
    this.debt,
    this.riskScore,
    this.riskBand,
    this.groupIds = const [],
    this.lat,
    this.lng,
    this.askingRent,
    this.listingStatus,
  });

  RentRollRowKindEnum kind;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? leaseId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? unitId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? code;

  String state;

  String municipality;

  String municipalityPath;

  String region;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? regionPath;

  String address;

  String unit;

  /// Initials only for the investor role.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? tenants;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? rent;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? services;

  String currency;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? dueDay;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? startsOn;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? endsOn;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? noticeOn;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? deposit;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? depositPaid;

  /// Receivables due by today (ledger).
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? billed;

  /// Payments booked by today (ledger).
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? paid;

  /// Receivable balance by today.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? debt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? riskScore;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  RiskBand? riskBand;

  List<String> groupIds;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? lat;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? lng;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? askingRent;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? listingStatus;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RentRollRow &&
    other.kind == kind &&
    other.leaseId == leaseId &&
    other.unitId == unitId &&
    other.code == code &&
    other.state == state &&
    other.municipality == municipality &&
    other.municipalityPath == municipalityPath &&
    other.region == region &&
    other.regionPath == regionPath &&
    other.address == address &&
    other.unit == unit &&
    other.tenants == tenants &&
    other.rent == rent &&
    other.services == services &&
    other.currency == currency &&
    other.dueDay == dueDay &&
    other.startsOn == startsOn &&
    other.endsOn == endsOn &&
    other.noticeOn == noticeOn &&
    other.deposit == deposit &&
    other.depositPaid == depositPaid &&
    other.billed == billed &&
    other.paid == paid &&
    other.debt == debt &&
    other.riskScore == riskScore &&
    other.riskBand == riskBand &&
    _deepEquality.equals(other.groupIds, groupIds) &&
    other.lat == lat &&
    other.lng == lng &&
    other.askingRent == askingRent &&
    other.listingStatus == listingStatus;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (kind.hashCode) +
    (leaseId == null ? 0 : leaseId!.hashCode) +
    (unitId == null ? 0 : unitId!.hashCode) +
    (code == null ? 0 : code!.hashCode) +
    (state.hashCode) +
    (municipality.hashCode) +
    (municipalityPath.hashCode) +
    (region.hashCode) +
    (regionPath == null ? 0 : regionPath!.hashCode) +
    (address.hashCode) +
    (unit.hashCode) +
    (tenants == null ? 0 : tenants!.hashCode) +
    (rent == null ? 0 : rent!.hashCode) +
    (services == null ? 0 : services!.hashCode) +
    (currency.hashCode) +
    (dueDay == null ? 0 : dueDay!.hashCode) +
    (startsOn == null ? 0 : startsOn!.hashCode) +
    (endsOn == null ? 0 : endsOn!.hashCode) +
    (noticeOn == null ? 0 : noticeOn!.hashCode) +
    (deposit == null ? 0 : deposit!.hashCode) +
    (depositPaid == null ? 0 : depositPaid!.hashCode) +
    (billed == null ? 0 : billed!.hashCode) +
    (paid == null ? 0 : paid!.hashCode) +
    (debt == null ? 0 : debt!.hashCode) +
    (riskScore == null ? 0 : riskScore!.hashCode) +
    (riskBand == null ? 0 : riskBand!.hashCode) +
    (groupIds.hashCode) +
    (lat == null ? 0 : lat!.hashCode) +
    (lng == null ? 0 : lng!.hashCode) +
    (askingRent == null ? 0 : askingRent!.hashCode) +
    (listingStatus == null ? 0 : listingStatus!.hashCode);

  @override
  String toString() => 'RentRollRow[kind=$kind, leaseId=$leaseId, unitId=$unitId, code=$code, state=$state, municipality=$municipality, municipalityPath=$municipalityPath, region=$region, regionPath=$regionPath, address=$address, unit=$unit, tenants=$tenants, rent=$rent, services=$services, currency=$currency, dueDay=$dueDay, startsOn=$startsOn, endsOn=$endsOn, noticeOn=$noticeOn, deposit=$deposit, depositPaid=$depositPaid, billed=$billed, paid=$paid, debt=$debt, riskScore=$riskScore, riskBand=$riskBand, groupIds=$groupIds, lat=$lat, lng=$lng, askingRent=$askingRent, listingStatus=$listingStatus]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'kind'] = this.kind;
    if (this.leaseId != null) {
      json[r'lease_id'] = this.leaseId;
    } else {
      json[r'lease_id'] = null;
    }
    if (this.unitId != null) {
      json[r'unit_id'] = this.unitId;
    } else {
      json[r'unit_id'] = null;
    }
    if (this.code != null) {
      json[r'code'] = this.code;
    } else {
      json[r'code'] = null;
    }
      json[r'state'] = this.state;
      json[r'municipality'] = this.municipality;
      json[r'municipality_path'] = this.municipalityPath;
      json[r'region'] = this.region;
    if (this.regionPath != null) {
      json[r'region_path'] = this.regionPath;
    } else {
      json[r'region_path'] = null;
    }
      json[r'address'] = this.address;
      json[r'unit'] = this.unit;
    if (this.tenants != null) {
      json[r'tenants'] = this.tenants;
    } else {
      json[r'tenants'] = null;
    }
    if (this.rent != null) {
      json[r'rent'] = this.rent;
    } else {
      json[r'rent'] = null;
    }
    if (this.services != null) {
      json[r'services'] = this.services;
    } else {
      json[r'services'] = null;
    }
      json[r'currency'] = this.currency;
    if (this.dueDay != null) {
      json[r'due_day'] = this.dueDay;
    } else {
      json[r'due_day'] = null;
    }
    if (this.startsOn != null) {
      json[r'starts_on'] = _dateFormatter.format(this.startsOn!.toUtc());
    } else {
      json[r'starts_on'] = null;
    }
    if (this.endsOn != null) {
      json[r'ends_on'] = _dateFormatter.format(this.endsOn!.toUtc());
    } else {
      json[r'ends_on'] = null;
    }
    if (this.noticeOn != null) {
      json[r'notice_on'] = _dateFormatter.format(this.noticeOn!.toUtc());
    } else {
      json[r'notice_on'] = null;
    }
    if (this.deposit != null) {
      json[r'deposit'] = this.deposit;
    } else {
      json[r'deposit'] = null;
    }
    if (this.depositPaid != null) {
      json[r'deposit_paid'] = this.depositPaid;
    } else {
      json[r'deposit_paid'] = null;
    }
    if (this.billed != null) {
      json[r'billed'] = this.billed;
    } else {
      json[r'billed'] = null;
    }
    if (this.paid != null) {
      json[r'paid'] = this.paid;
    } else {
      json[r'paid'] = null;
    }
    if (this.debt != null) {
      json[r'debt'] = this.debt;
    } else {
      json[r'debt'] = null;
    }
    if (this.riskScore != null) {
      json[r'risk_score'] = this.riskScore;
    } else {
      json[r'risk_score'] = null;
    }
    if (this.riskBand != null) {
      json[r'risk_band'] = this.riskBand;
    } else {
      json[r'risk_band'] = null;
    }
      json[r'group_ids'] = this.groupIds;
    if (this.lat != null) {
      json[r'lat'] = this.lat;
    } else {
      json[r'lat'] = null;
    }
    if (this.lng != null) {
      json[r'lng'] = this.lng;
    } else {
      json[r'lng'] = null;
    }
    if (this.askingRent != null) {
      json[r'asking_rent'] = this.askingRent;
    } else {
      json[r'asking_rent'] = null;
    }
    if (this.listingStatus != null) {
      json[r'listing_status'] = this.listingStatus;
    } else {
      json[r'listing_status'] = null;
    }
    return json;
  }

  /// Returns a new [RentRollRow] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RentRollRow? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "RentRollRow[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "RentRollRow[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return RentRollRow(
        kind: RentRollRowKindEnum.fromJson(json[r'kind'])!,
        leaseId: mapValueOfType<String>(json, r'lease_id'),
        unitId: mapValueOfType<String>(json, r'unit_id'),
        code: mapValueOfType<int>(json, r'code'),
        state: mapValueOfType<String>(json, r'state')!,
        municipality: mapValueOfType<String>(json, r'municipality')!,
        municipalityPath: mapValueOfType<String>(json, r'municipality_path')!,
        region: mapValueOfType<String>(json, r'region')!,
        regionPath: mapValueOfType<String>(json, r'region_path'),
        address: mapValueOfType<String>(json, r'address')!,
        unit: mapValueOfType<String>(json, r'unit')!,
        tenants: mapValueOfType<String>(json, r'tenants'),
        rent: mapValueOfType<int>(json, r'rent'),
        services: mapValueOfType<int>(json, r'services'),
        currency: mapValueOfType<String>(json, r'currency')!,
        dueDay: mapValueOfType<int>(json, r'due_day'),
        startsOn: mapDateTime(json, r'starts_on', r''),
        endsOn: mapDateTime(json, r'ends_on', r''),
        noticeOn: mapDateTime(json, r'notice_on', r''),
        deposit: mapValueOfType<int>(json, r'deposit'),
        depositPaid: mapValueOfType<int>(json, r'deposit_paid'),
        billed: mapValueOfType<int>(json, r'billed'),
        paid: mapValueOfType<int>(json, r'paid'),
        debt: mapValueOfType<int>(json, r'debt'),
        riskScore: mapValueOfType<int>(json, r'risk_score'),
        riskBand: RiskBand.fromJson(json[r'risk_band']),
        groupIds: json[r'group_ids'] is Iterable
            ? (json[r'group_ids'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        lat: num.parse('${json[r'lat']}'),
        lng: num.parse('${json[r'lng']}'),
        askingRent: mapValueOfType<int>(json, r'asking_rent'),
        listingStatus: mapValueOfType<String>(json, r'listing_status'),
      );
    }
    return null;
  }

  static List<RentRollRow> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RentRollRow>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RentRollRow.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RentRollRow> mapFromJson(dynamic json) {
    final map = <String, RentRollRow>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RentRollRow.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RentRollRow-objects as value to a dart map
  static Map<String, List<RentRollRow>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RentRollRow>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RentRollRow.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'kind',
    'state',
    'municipality',
    'municipality_path',
    'region',
    'address',
    'unit',
    'currency',
    'group_ids',
  };
}


class RentRollRowKindEnum {
  /// Instantiate a new enum with the provided [value].
  const RentRollRowKindEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const lease = RentRollRowKindEnum._(r'lease');
  static const vacant = RentRollRowKindEnum._(r'vacant');

  /// List of all possible values in this [enum][RentRollRowKindEnum].
  static const values = <RentRollRowKindEnum>[
    lease,
    vacant,
  ];

  static RentRollRowKindEnum? fromJson(dynamic value) => RentRollRowKindEnumTypeTransformer().decode(value);

  static List<RentRollRowKindEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RentRollRowKindEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RentRollRowKindEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [RentRollRowKindEnum] to String,
/// and [decode] dynamic data back to [RentRollRowKindEnum].
class RentRollRowKindEnumTypeTransformer {
  factory RentRollRowKindEnumTypeTransformer() => _instance ??= const RentRollRowKindEnumTypeTransformer._();

  const RentRollRowKindEnumTypeTransformer._();

  String encode(RentRollRowKindEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a RentRollRowKindEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  RentRollRowKindEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'lease': return RentRollRowKindEnum.lease;
        case r'vacant': return RentRollRowKindEnum.vacant;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [RentRollRowKindEnumTypeTransformer] instance.
  static RentRollRowKindEnumTypeTransformer? _instance;
}


