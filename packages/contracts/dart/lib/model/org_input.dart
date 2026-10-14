//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class OrgInput {
  /// Returns a new [OrgInput] instance.
  OrgInput({
    required this.name,
    this.registrationNo,
    this.vatNo,
    this.jurisdictionCode,
  });

  String name;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? registrationNo;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? vatNo;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? jurisdictionCode;

  @override
  bool operator ==(Object other) => identical(this, other) || other is OrgInput &&
    other.name == name &&
    other.registrationNo == registrationNo &&
    other.vatNo == vatNo &&
    other.jurisdictionCode == jurisdictionCode;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name.hashCode) +
    (registrationNo == null ? 0 : registrationNo!.hashCode) +
    (vatNo == null ? 0 : vatNo!.hashCode) +
    (jurisdictionCode == null ? 0 : jurisdictionCode!.hashCode);

  @override
  String toString() => 'OrgInput[name=$name, registrationNo=$registrationNo, vatNo=$vatNo, jurisdictionCode=$jurisdictionCode]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'name'] = this.name;
    if (this.registrationNo != null) {
      json[r'registration_no'] = this.registrationNo;
    } else {
      json[r'registration_no'] = null;
    }
    if (this.vatNo != null) {
      json[r'vat_no'] = this.vatNo;
    } else {
      json[r'vat_no'] = null;
    }
    if (this.jurisdictionCode != null) {
      json[r'jurisdiction_code'] = this.jurisdictionCode;
    } else {
      json[r'jurisdiction_code'] = null;
    }
    return json;
  }

  /// Returns a new [OrgInput] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static OrgInput? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "OrgInput[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "OrgInput[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return OrgInput(
        name: mapValueOfType<String>(json, r'name')!,
        registrationNo: mapValueOfType<String>(json, r'registration_no'),
        vatNo: mapValueOfType<String>(json, r'vat_no'),
        jurisdictionCode: mapValueOfType<String>(json, r'jurisdiction_code'),
      );
    }
    return null;
  }

  static List<OrgInput> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <OrgInput>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = OrgInput.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, OrgInput> mapFromJson(dynamic json) {
    final map = <String, OrgInput>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = OrgInput.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of OrgInput-objects as value to a dart map
  static Map<String, List<OrgInput>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<OrgInput>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = OrgInput.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'name',
  };
}

