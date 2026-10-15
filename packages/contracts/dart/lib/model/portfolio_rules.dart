//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PortfolioRules {
  /// Returns a new [PortfolioRules] instance.
  PortfolioRules({
    this.reminderBeforeDays,
    this.overdueDays,
    this.escalationDays,
    this.depositMonths,
    this.noticeMonths,
  });

  /// Minimum value: 0
  /// Maximum value: 14
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? reminderBeforeDays;

  /// Minimum value: 1
  /// Maximum value: 14
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? overdueDays;

  /// Minimum value: 2
  /// Maximum value: 30
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? escalationDays;

  /// Minimum value: 0
  /// Maximum value: 12
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? depositMonths;

  /// Minimum value: 1
  /// Maximum value: 12
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? noticeMonths;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PortfolioRules &&
    other.reminderBeforeDays == reminderBeforeDays &&
    other.overdueDays == overdueDays &&
    other.escalationDays == escalationDays &&
    other.depositMonths == depositMonths &&
    other.noticeMonths == noticeMonths;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (reminderBeforeDays == null ? 0 : reminderBeforeDays!.hashCode) +
    (overdueDays == null ? 0 : overdueDays!.hashCode) +
    (escalationDays == null ? 0 : escalationDays!.hashCode) +
    (depositMonths == null ? 0 : depositMonths!.hashCode) +
    (noticeMonths == null ? 0 : noticeMonths!.hashCode);

  @override
  String toString() => 'PortfolioRules[reminderBeforeDays=$reminderBeforeDays, overdueDays=$overdueDays, escalationDays=$escalationDays, depositMonths=$depositMonths, noticeMonths=$noticeMonths]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.reminderBeforeDays != null) {
      json[r'reminder_before_days'] = this.reminderBeforeDays;
    } else {
      json[r'reminder_before_days'] = null;
    }
    if (this.overdueDays != null) {
      json[r'overdue_days'] = this.overdueDays;
    } else {
      json[r'overdue_days'] = null;
    }
    if (this.escalationDays != null) {
      json[r'escalation_days'] = this.escalationDays;
    } else {
      json[r'escalation_days'] = null;
    }
    if (this.depositMonths != null) {
      json[r'deposit_months'] = this.depositMonths;
    } else {
      json[r'deposit_months'] = null;
    }
    if (this.noticeMonths != null) {
      json[r'notice_months'] = this.noticeMonths;
    } else {
      json[r'notice_months'] = null;
    }
    return json;
  }

  /// Returns a new [PortfolioRules] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PortfolioRules? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PortfolioRules[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PortfolioRules[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PortfolioRules(
        reminderBeforeDays: mapValueOfType<int>(json, r'reminder_before_days'),
        overdueDays: mapValueOfType<int>(json, r'overdue_days'),
        escalationDays: mapValueOfType<int>(json, r'escalation_days'),
        depositMonths: mapValueOfType<int>(json, r'deposit_months'),
        noticeMonths: mapValueOfType<int>(json, r'notice_months'),
      );
    }
    return null;
  }

  static List<PortfolioRules> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PortfolioRules>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PortfolioRules.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PortfolioRules> mapFromJson(dynamic json) {
    final map = <String, PortfolioRules>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PortfolioRules.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PortfolioRules-objects as value to a dart map
  static Map<String, List<PortfolioRules>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PortfolioRules>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PortfolioRules.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

