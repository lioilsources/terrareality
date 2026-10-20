//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class LeaseImportInput {
  /// Returns a new [LeaseImportInput] instance.
  LeaseImportInput({
    this.listingId,
    required this.template,
    required this.startsOn,
    this.endsOn,
    required this.rentAmount,
    this.servicesAmount,
    this.depositAmount,
    this.depositHeld = false,
    this.dueDay = 15,
    this.noticeMonths,
    required this.payeeIban,
    required this.payeeName,
    required this.propertyAddress,
    this.ruianId,
    this.unitLabel,
    this.cutoverOn,
    this.variableSymbol,
    this.parties = const [],
  });

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

  /// The landlord already holds the deposit (no deposit obligation).
  bool depositHeld;

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

  String propertyAddress;

  /// RÚIAN address of the flat (where the lease is in the portfolio).
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

  /// Payments are tracked from this day (default: the first day of next month).
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? cutoverOn;

  /// The tenants' existing variable symbol (leading zeros are dropped).
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? variableSymbol;

  List<LeaseImportPartyInput> parties;

  @override
  bool operator ==(Object other) => identical(this, other) || other is LeaseImportInput &&
    other.listingId == listingId &&
    other.template == template &&
    other.startsOn == startsOn &&
    other.endsOn == endsOn &&
    other.rentAmount == rentAmount &&
    other.servicesAmount == servicesAmount &&
    other.depositAmount == depositAmount &&
    other.depositHeld == depositHeld &&
    other.dueDay == dueDay &&
    other.noticeMonths == noticeMonths &&
    other.payeeIban == payeeIban &&
    other.payeeName == payeeName &&
    other.propertyAddress == propertyAddress &&
    other.ruianId == ruianId &&
    other.unitLabel == unitLabel &&
    other.cutoverOn == cutoverOn &&
    other.variableSymbol == variableSymbol &&
    _deepEquality.equals(other.parties, parties);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (listingId == null ? 0 : listingId!.hashCode) +
    (template.hashCode) +
    (startsOn.hashCode) +
    (endsOn == null ? 0 : endsOn!.hashCode) +
    (rentAmount.hashCode) +
    (servicesAmount == null ? 0 : servicesAmount!.hashCode) +
    (depositAmount == null ? 0 : depositAmount!.hashCode) +
    (depositHeld.hashCode) +
    (dueDay.hashCode) +
    (noticeMonths == null ? 0 : noticeMonths!.hashCode) +
    (payeeIban.hashCode) +
    (payeeName.hashCode) +
    (propertyAddress.hashCode) +
    (ruianId == null ? 0 : ruianId!.hashCode) +
    (unitLabel == null ? 0 : unitLabel!.hashCode) +
    (cutoverOn == null ? 0 : cutoverOn!.hashCode) +
    (variableSymbol == null ? 0 : variableSymbol!.hashCode) +
    (parties.hashCode);

  @override
  String toString() => 'LeaseImportInput[listingId=$listingId, template=$template, startsOn=$startsOn, endsOn=$endsOn, rentAmount=$rentAmount, servicesAmount=$servicesAmount, depositAmount=$depositAmount, depositHeld=$depositHeld, dueDay=$dueDay, noticeMonths=$noticeMonths, payeeIban=$payeeIban, payeeName=$payeeName, propertyAddress=$propertyAddress, ruianId=$ruianId, unitLabel=$unitLabel, cutoverOn=$cutoverOn, variableSymbol=$variableSymbol, parties=$parties]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
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
      json[r'deposit_held'] = this.depositHeld;
      json[r'due_day'] = this.dueDay;
    if (this.noticeMonths != null) {
      json[r'notice_months'] = this.noticeMonths;
    } else {
      json[r'notice_months'] = null;
    }
      json[r'payee_iban'] = this.payeeIban;
      json[r'payee_name'] = this.payeeName;
      json[r'property_address'] = this.propertyAddress;
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
    if (this.cutoverOn != null) {
      json[r'cutover_on'] = _dateFormatter.format(this.cutoverOn!.toUtc());
    } else {
      json[r'cutover_on'] = null;
    }
    if (this.variableSymbol != null) {
      json[r'variable_symbol'] = this.variableSymbol;
    } else {
      json[r'variable_symbol'] = null;
    }
      json[r'parties'] = this.parties;
    return json;
  }

  /// Returns a new [LeaseImportInput] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LeaseImportInput? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "LeaseImportInput[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "LeaseImportInput[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return LeaseImportInput(
        listingId: mapValueOfType<String>(json, r'listing_id'),
        template: LeaseTemplate.fromJson(json[r'template'])!,
        startsOn: mapDateTime(json, r'starts_on', r'')!,
        endsOn: mapDateTime(json, r'ends_on', r''),
        rentAmount: mapValueOfType<int>(json, r'rent_amount')!,
        servicesAmount: mapValueOfType<int>(json, r'services_amount'),
        depositAmount: mapValueOfType<int>(json, r'deposit_amount'),
        depositHeld: mapValueOfType<bool>(json, r'deposit_held') ?? false,
        dueDay: mapValueOfType<int>(json, r'due_day') ?? 15,
        noticeMonths: mapValueOfType<int>(json, r'notice_months'),
        payeeIban: mapValueOfType<String>(json, r'payee_iban')!,
        payeeName: mapValueOfType<String>(json, r'payee_name')!,
        propertyAddress: mapValueOfType<String>(json, r'property_address')!,
        ruianId: mapValueOfType<int>(json, r'ruian_id'),
        unitLabel: mapValueOfType<String>(json, r'unit_label'),
        cutoverOn: mapDateTime(json, r'cutover_on', r''),
        variableSymbol: mapValueOfType<String>(json, r'variable_symbol'),
        parties: LeaseImportPartyInput.listFromJson(json[r'parties']),
      );
    }
    return null;
  }

  static List<LeaseImportInput> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LeaseImportInput>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LeaseImportInput.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LeaseImportInput> mapFromJson(dynamic json) {
    final map = <String, LeaseImportInput>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LeaseImportInput.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LeaseImportInput-objects as value to a dart map
  static Map<String, List<LeaseImportInput>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<LeaseImportInput>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LeaseImportInput.listFromJson(entry.value, growable: growable,);
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
    'property_address',
    'parties',
  };
}

