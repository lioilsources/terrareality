//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class LeaseDetail {
  /// Returns a new [LeaseDetail] instance.
  LeaseDetail({
    required this.lease,
    required this.landlordView,
    required this.payeeIban,
    required this.payeeName,
    required this.dueDay,
    required this.noticeMonths,
    required this.depositAmount,
    required this.servicesAmount,
    required this.depositHeld,
    this.contractScanUrl,
    this.clauses = const [],
    this.changeRequest,
    this.parties = const [],
    this.documents = const [],
    required this.totalDebt,
    this.signProviders = const [],
  });

  LeaseSummary lease;

  bool landlordView;

  String payeeIban;

  String payeeName;

  int dueDay;

  int noticeMonths;

  int depositAmount;

  int servicesAmount;

  /// Imported lease: the landlord collected the deposit before the cutover (not scheduled).
  bool depositHeld;

  /// Imported lease: short-lived download link of the paper contract's scan.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? contractScanUrl;

  List<String> clauses;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? changeRequest;

  List<LeaseParty> parties;

  List<LeaseDocument> documents;

  int totalDebt;

  /// Signature methods enabled on this server, in order of preference.
  List<SignProvider> signProviders;

  @override
  bool operator ==(Object other) => identical(this, other) || other is LeaseDetail &&
    other.lease == lease &&
    other.landlordView == landlordView &&
    other.payeeIban == payeeIban &&
    other.payeeName == payeeName &&
    other.dueDay == dueDay &&
    other.noticeMonths == noticeMonths &&
    other.depositAmount == depositAmount &&
    other.servicesAmount == servicesAmount &&
    other.depositHeld == depositHeld &&
    other.contractScanUrl == contractScanUrl &&
    _deepEquality.equals(other.clauses, clauses) &&
    other.changeRequest == changeRequest &&
    _deepEquality.equals(other.parties, parties) &&
    _deepEquality.equals(other.documents, documents) &&
    other.totalDebt == totalDebt &&
    _deepEquality.equals(other.signProviders, signProviders);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (lease.hashCode) +
    (landlordView.hashCode) +
    (payeeIban.hashCode) +
    (payeeName.hashCode) +
    (dueDay.hashCode) +
    (noticeMonths.hashCode) +
    (depositAmount.hashCode) +
    (servicesAmount.hashCode) +
    (depositHeld.hashCode) +
    (contractScanUrl == null ? 0 : contractScanUrl!.hashCode) +
    (clauses.hashCode) +
    (changeRequest == null ? 0 : changeRequest!.hashCode) +
    (parties.hashCode) +
    (documents.hashCode) +
    (totalDebt.hashCode) +
    (signProviders.hashCode);

  @override
  String toString() => 'LeaseDetail[lease=$lease, landlordView=$landlordView, payeeIban=$payeeIban, payeeName=$payeeName, dueDay=$dueDay, noticeMonths=$noticeMonths, depositAmount=$depositAmount, servicesAmount=$servicesAmount, depositHeld=$depositHeld, contractScanUrl=$contractScanUrl, clauses=$clauses, changeRequest=$changeRequest, parties=$parties, documents=$documents, totalDebt=$totalDebt, signProviders=$signProviders]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'lease'] = this.lease;
      json[r'landlord_view'] = this.landlordView;
      json[r'payee_iban'] = this.payeeIban;
      json[r'payee_name'] = this.payeeName;
      json[r'due_day'] = this.dueDay;
      json[r'notice_months'] = this.noticeMonths;
      json[r'deposit_amount'] = this.depositAmount;
      json[r'services_amount'] = this.servicesAmount;
      json[r'deposit_held'] = this.depositHeld;
    if (this.contractScanUrl != null) {
      json[r'contract_scan_url'] = this.contractScanUrl;
    } else {
      json[r'contract_scan_url'] = null;
    }
      json[r'clauses'] = this.clauses;
    if (this.changeRequest != null) {
      json[r'change_request'] = this.changeRequest;
    } else {
      json[r'change_request'] = null;
    }
      json[r'parties'] = this.parties;
      json[r'documents'] = this.documents;
      json[r'total_debt'] = this.totalDebt;
      json[r'sign_providers'] = this.signProviders;
    return json;
  }

  /// Returns a new [LeaseDetail] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LeaseDetail? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "LeaseDetail[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "LeaseDetail[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return LeaseDetail(
        lease: LeaseSummary.fromJson(json[r'lease'])!,
        landlordView: mapValueOfType<bool>(json, r'landlord_view')!,
        payeeIban: mapValueOfType<String>(json, r'payee_iban')!,
        payeeName: mapValueOfType<String>(json, r'payee_name')!,
        dueDay: mapValueOfType<int>(json, r'due_day')!,
        noticeMonths: mapValueOfType<int>(json, r'notice_months')!,
        depositAmount: mapValueOfType<int>(json, r'deposit_amount')!,
        servicesAmount: mapValueOfType<int>(json, r'services_amount')!,
        depositHeld: mapValueOfType<bool>(json, r'deposit_held')!,
        contractScanUrl: mapValueOfType<String>(json, r'contract_scan_url'),
        clauses: json[r'clauses'] is Iterable
            ? (json[r'clauses'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        changeRequest: mapValueOfType<String>(json, r'change_request'),
        parties: LeaseParty.listFromJson(json[r'parties']),
        documents: LeaseDocument.listFromJson(json[r'documents']),
        totalDebt: mapValueOfType<int>(json, r'total_debt')!,
        signProviders: SignProvider.listFromJson(json[r'sign_providers']),
      );
    }
    return null;
  }

  static List<LeaseDetail> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LeaseDetail>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LeaseDetail.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LeaseDetail> mapFromJson(dynamic json) {
    final map = <String, LeaseDetail>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LeaseDetail.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LeaseDetail-objects as value to a dart map
  static Map<String, List<LeaseDetail>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<LeaseDetail>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LeaseDetail.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'lease',
    'landlord_view',
    'payee_iban',
    'payee_name',
    'due_day',
    'notice_months',
    'deposit_amount',
    'services_amount',
    'deposit_held',
    'clauses',
    'parties',
    'documents',
    'total_debt',
    'sign_providers',
  };
}

