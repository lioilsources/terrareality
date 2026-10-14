//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class LeaseSummary {
  /// Returns a new [LeaseSummary] instance.
  LeaseSummary({
    required this.id,
    required this.orgId,
    this.orgName,
    required this.code,
    required this.state,
    required this.template,
    required this.propertyAddress,
    this.unitLabel,
    this.tenantNames,
    required this.startsOn,
    this.endsOn,
    required this.rentAmount,
    required this.currency,
    required this.createdAt,
  });

  String id;

  String orgId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? orgName;

  /// Variable symbol of payments.
  int code;

  LeaseState state;

  LeaseTemplate template;

  String propertyAddress;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? unitLabel;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? tenantNames;

  DateTime startsOn;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? endsOn;

  int rentAmount;

  String currency;

  DateTime createdAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is LeaseSummary &&
    other.id == id &&
    other.orgId == orgId &&
    other.orgName == orgName &&
    other.code == code &&
    other.state == state &&
    other.template == template &&
    other.propertyAddress == propertyAddress &&
    other.unitLabel == unitLabel &&
    other.tenantNames == tenantNames &&
    other.startsOn == startsOn &&
    other.endsOn == endsOn &&
    other.rentAmount == rentAmount &&
    other.currency == currency &&
    other.createdAt == createdAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (orgId.hashCode) +
    (orgName == null ? 0 : orgName!.hashCode) +
    (code.hashCode) +
    (state.hashCode) +
    (template.hashCode) +
    (propertyAddress.hashCode) +
    (unitLabel == null ? 0 : unitLabel!.hashCode) +
    (tenantNames == null ? 0 : tenantNames!.hashCode) +
    (startsOn.hashCode) +
    (endsOn == null ? 0 : endsOn!.hashCode) +
    (rentAmount.hashCode) +
    (currency.hashCode) +
    (createdAt.hashCode);

  @override
  String toString() => 'LeaseSummary[id=$id, orgId=$orgId, orgName=$orgName, code=$code, state=$state, template=$template, propertyAddress=$propertyAddress, unitLabel=$unitLabel, tenantNames=$tenantNames, startsOn=$startsOn, endsOn=$endsOn, rentAmount=$rentAmount, currency=$currency, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'org_id'] = this.orgId;
    if (this.orgName != null) {
      json[r'org_name'] = this.orgName;
    } else {
      json[r'org_name'] = null;
    }
      json[r'code'] = this.code;
      json[r'state'] = this.state;
      json[r'template'] = this.template;
      json[r'property_address'] = this.propertyAddress;
    if (this.unitLabel != null) {
      json[r'unit_label'] = this.unitLabel;
    } else {
      json[r'unit_label'] = null;
    }
    if (this.tenantNames != null) {
      json[r'tenant_names'] = this.tenantNames;
    } else {
      json[r'tenant_names'] = null;
    }
      json[r'starts_on'] = _dateFormatter.format(this.startsOn.toUtc());
    if (this.endsOn != null) {
      json[r'ends_on'] = _dateFormatter.format(this.endsOn!.toUtc());
    } else {
      json[r'ends_on'] = null;
    }
      json[r'rent_amount'] = this.rentAmount;
      json[r'currency'] = this.currency;
      json[r'created_at'] = this.createdAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [LeaseSummary] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LeaseSummary? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "LeaseSummary[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "LeaseSummary[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return LeaseSummary(
        id: mapValueOfType<String>(json, r'id')!,
        orgId: mapValueOfType<String>(json, r'org_id')!,
        orgName: mapValueOfType<String>(json, r'org_name'),
        code: mapValueOfType<int>(json, r'code')!,
        state: LeaseState.fromJson(json[r'state'])!,
        template: LeaseTemplate.fromJson(json[r'template'])!,
        propertyAddress: mapValueOfType<String>(json, r'property_address')!,
        unitLabel: mapValueOfType<String>(json, r'unit_label'),
        tenantNames: mapValueOfType<String>(json, r'tenant_names'),
        startsOn: mapDateTime(json, r'starts_on', r'')!,
        endsOn: mapDateTime(json, r'ends_on', r''),
        rentAmount: mapValueOfType<int>(json, r'rent_amount')!,
        currency: mapValueOfType<String>(json, r'currency')!,
        createdAt: mapDateTime(json, r'created_at', r'')!,
      );
    }
    return null;
  }

  static List<LeaseSummary> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LeaseSummary>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LeaseSummary.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LeaseSummary> mapFromJson(dynamic json) {
    final map = <String, LeaseSummary>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LeaseSummary.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LeaseSummary-objects as value to a dart map
  static Map<String, List<LeaseSummary>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<LeaseSummary>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LeaseSummary.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'org_id',
    'code',
    'state',
    'template',
    'property_address',
    'starts_on',
    'rent_amount',
    'currency',
    'created_at',
  };
}

