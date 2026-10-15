//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class LeaseInput {
  /// Returns a new [LeaseInput] instance.
  LeaseInput({
    this.applicationId,
    this.listingId,
    required this.template,
    required this.startsOn,
    this.endsOn,
    required this.rentAmount,
    this.servicesAmount,
    this.depositAmount,
    this.dueDay = 15,
    this.noticeMonths,
    required this.payeeIban,
    required this.payeeName,
    this.clauses = const [],
    this.propertyAddress,
    this.ruianId,
    this.unitLabel,
    this.parties = const [],
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? applicationId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? listingId;

  LeaseTemplate template;

  DateTime startsOn;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? endsOn;

  /// Minimum value: 1
  int rentAmount;

  /// Minimum value: 0
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? servicesAmount;

  /// Minimum value: 0
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? depositAmount;

  /// Minimum value: 1
  /// Maximum value: 28
  int dueDay;

  /// Default: the portfolio rules of the place, else 3.
  ///
  /// Minimum value: 1
  /// Maximum value: 12
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? noticeMonths;

  String payeeIban;

  String payeeName;

  List<LeaseInputClausesEnum> clauses;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? propertyAddress;

  /// RÚIAN address of a lease without a listing (where the lease is in the portfolio).
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? ruianId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? unitLabel;

  List<LeasePartyInput> parties;

  @override
  bool operator ==(Object other) => identical(this, other) || other is LeaseInput &&
    other.applicationId == applicationId &&
    other.listingId == listingId &&
    other.template == template &&
    other.startsOn == startsOn &&
    other.endsOn == endsOn &&
    other.rentAmount == rentAmount &&
    other.servicesAmount == servicesAmount &&
    other.depositAmount == depositAmount &&
    other.dueDay == dueDay &&
    other.noticeMonths == noticeMonths &&
    other.payeeIban == payeeIban &&
    other.payeeName == payeeName &&
    _deepEquality.equals(other.clauses, clauses) &&
    other.propertyAddress == propertyAddress &&
    other.ruianId == ruianId &&
    other.unitLabel == unitLabel &&
    _deepEquality.equals(other.parties, parties);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (applicationId == null ? 0 : applicationId!.hashCode) +
    (listingId == null ? 0 : listingId!.hashCode) +
    (template.hashCode) +
    (startsOn.hashCode) +
    (endsOn == null ? 0 : endsOn!.hashCode) +
    (rentAmount.hashCode) +
    (servicesAmount == null ? 0 : servicesAmount!.hashCode) +
    (depositAmount == null ? 0 : depositAmount!.hashCode) +
    (dueDay.hashCode) +
    (noticeMonths == null ? 0 : noticeMonths!.hashCode) +
    (payeeIban.hashCode) +
    (payeeName.hashCode) +
    (clauses.hashCode) +
    (propertyAddress == null ? 0 : propertyAddress!.hashCode) +
    (ruianId == null ? 0 : ruianId!.hashCode) +
    (unitLabel == null ? 0 : unitLabel!.hashCode) +
    (parties.hashCode);

  @override
  String toString() => 'LeaseInput[applicationId=$applicationId, listingId=$listingId, template=$template, startsOn=$startsOn, endsOn=$endsOn, rentAmount=$rentAmount, servicesAmount=$servicesAmount, depositAmount=$depositAmount, dueDay=$dueDay, noticeMonths=$noticeMonths, payeeIban=$payeeIban, payeeName=$payeeName, clauses=$clauses, propertyAddress=$propertyAddress, ruianId=$ruianId, unitLabel=$unitLabel, parties=$parties]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.applicationId != null) {
      json[r'application_id'] = this.applicationId;
    } else {
      json[r'application_id'] = null;
    }
    if (this.listingId != null) {
      json[r'listing_id'] = this.listingId;
    } else {
      json[r'listing_id'] = null;
    }
      json[r'template'] = this.template;
      json[r'starts_on'] = _dateFormatter.format(this.startsOn.toUtc());
    if (this.endsOn != null) {
      json[r'ends_on'] = _dateFormatter.format(this.endsOn!.toUtc());
    } else {
      json[r'ends_on'] = null;
    }
      json[r'rent_amount'] = this.rentAmount;
    if (this.servicesAmount != null) {
      json[r'services_amount'] = this.servicesAmount;
    } else {
      json[r'services_amount'] = null;
    }
    if (this.depositAmount != null) {
      json[r'deposit_amount'] = this.depositAmount;
    } else {
      json[r'deposit_amount'] = null;
    }
      json[r'due_day'] = this.dueDay;
    if (this.noticeMonths != null) {
      json[r'notice_months'] = this.noticeMonths;
    } else {
      json[r'notice_months'] = null;
    }
      json[r'payee_iban'] = this.payeeIban;
      json[r'payee_name'] = this.payeeName;
      json[r'clauses'] = this.clauses;
    if (this.propertyAddress != null) {
      json[r'property_address'] = this.propertyAddress;
    } else {
      json[r'property_address'] = null;
    }
    if (this.ruianId != null) {
      json[r'ruian_id'] = this.ruianId;
    } else {
      json[r'ruian_id'] = null;
    }
    if (this.unitLabel != null) {
      json[r'unit_label'] = this.unitLabel;
    } else {
      json[r'unit_label'] = null;
    }
      json[r'parties'] = this.parties;
    return json;
  }

  /// Returns a new [LeaseInput] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LeaseInput? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "LeaseInput[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "LeaseInput[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return LeaseInput(
        applicationId: mapValueOfType<String>(json, r'application_id'),
        listingId: mapValueOfType<String>(json, r'listing_id'),
        template: LeaseTemplate.fromJson(json[r'template'])!,
        startsOn: mapDateTime(json, r'starts_on', r'')!,
        endsOn: mapDateTime(json, r'ends_on', r''),
        rentAmount: mapValueOfType<int>(json, r'rent_amount')!,
        servicesAmount: mapValueOfType<int>(json, r'services_amount'),
        depositAmount: mapValueOfType<int>(json, r'deposit_amount'),
        dueDay: mapValueOfType<int>(json, r'due_day') ?? 15,
        noticeMonths: mapValueOfType<int>(json, r'notice_months'),
        payeeIban: mapValueOfType<String>(json, r'payee_iban')!,
        payeeName: mapValueOfType<String>(json, r'payee_name')!,
        clauses: LeaseInputClausesEnum.listFromJson(json[r'clauses']),
        propertyAddress: mapValueOfType<String>(json, r'property_address'),
        ruianId: mapValueOfType<int>(json, r'ruian_id'),
        unitLabel: mapValueOfType<String>(json, r'unit_label'),
        parties: LeasePartyInput.listFromJson(json[r'parties']),
      );
    }
    return null;
  }

  static List<LeaseInput> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LeaseInput>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LeaseInput.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LeaseInput> mapFromJson(dynamic json) {
    final map = <String, LeaseInput>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LeaseInput.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LeaseInput-objects as value to a dart map
  static Map<String, List<LeaseInput>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<LeaseInput>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LeaseInput.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'template',
    'starts_on',
    'rent_amount',
    'payee_iban',
    'payee_name',
  };
}


class LeaseInputClausesEnum {
  /// Instantiate a new enum with the provided [value].
  const LeaseInputClausesEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const petsAllowed = LeaseInputClausesEnum._(r'pets_allowed');
  static const noSmoking = LeaseInputClausesEnum._(r'no_smoking');
  static const inventory = LeaseInputClausesEnum._(r'inventory');
  static const indexation = LeaseInputClausesEnum._(r'indexation');
  static const subletForbidden = LeaseInputClausesEnum._(r'sublet_forbidden');
  static const earlyTermination = LeaseInputClausesEnum._(r'early_termination');

  /// List of all possible values in this [enum][LeaseInputClausesEnum].
  static const values = <LeaseInputClausesEnum>[
    petsAllowed,
    noSmoking,
    inventory,
    indexation,
    subletForbidden,
    earlyTermination,
  ];

  static LeaseInputClausesEnum? fromJson(dynamic value) => LeaseInputClausesEnumTypeTransformer().decode(value);

  static List<LeaseInputClausesEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LeaseInputClausesEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LeaseInputClausesEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [LeaseInputClausesEnum] to String,
/// and [decode] dynamic data back to [LeaseInputClausesEnum].
class LeaseInputClausesEnumTypeTransformer {
  factory LeaseInputClausesEnumTypeTransformer() => _instance ??= const LeaseInputClausesEnumTypeTransformer._();

  const LeaseInputClausesEnumTypeTransformer._();

  String encode(LeaseInputClausesEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a LeaseInputClausesEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  LeaseInputClausesEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'pets_allowed': return LeaseInputClausesEnum.petsAllowed;
        case r'no_smoking': return LeaseInputClausesEnum.noSmoking;
        case r'inventory': return LeaseInputClausesEnum.inventory;
        case r'indexation': return LeaseInputClausesEnum.indexation;
        case r'sublet_forbidden': return LeaseInputClausesEnum.subletForbidden;
        case r'early_termination': return LeaseInputClausesEnum.earlyTermination;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [LeaseInputClausesEnumTypeTransformer] instance.
  static LeaseInputClausesEnumTypeTransformer? _instance;
}


