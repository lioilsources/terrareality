//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PromoProductPatch {
  /// Returns a new [PromoProductPatch] instance.
  PromoProductPatch({
    this.netAmount,
    this.active,
    this.name,
    this.durationDays,
  });

  /// Minimum value: 0
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? netAmount;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? active;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  I18nText? name;

  /// Minimum value: 1
  /// Maximum value: 365
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? durationDays;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PromoProductPatch &&
    other.netAmount == netAmount &&
    other.active == active &&
    other.name == name &&
    other.durationDays == durationDays;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (netAmount == null ? 0 : netAmount!.hashCode) +
    (active == null ? 0 : active!.hashCode) +
    (name == null ? 0 : name!.hashCode) +
    (durationDays == null ? 0 : durationDays!.hashCode);

  @override
  String toString() => 'PromoProductPatch[netAmount=$netAmount, active=$active, name=$name, durationDays=$durationDays]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.netAmount != null) {
      json[r'net_amount'] = this.netAmount;
    } else {
      json[r'net_amount'] = null;
    }
    if (this.active != null) {
      json[r'active'] = this.active;
    } else {
      json[r'active'] = null;
    }
    if (this.name != null) {
      json[r'name'] = this.name;
    } else {
      json[r'name'] = null;
    }
    if (this.durationDays != null) {
      json[r'duration_days'] = this.durationDays;
    } else {
      json[r'duration_days'] = null;
    }
    return json;
  }

  /// Returns a new [PromoProductPatch] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PromoProductPatch? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PromoProductPatch[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PromoProductPatch[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PromoProductPatch(
        netAmount: mapValueOfType<int>(json, r'net_amount'),
        active: mapValueOfType<bool>(json, r'active'),
        name: I18nText.fromJson(json[r'name']),
        durationDays: mapValueOfType<int>(json, r'duration_days'),
      );
    }
    return null;
  }

  static List<PromoProductPatch> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PromoProductPatch>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PromoProductPatch.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PromoProductPatch> mapFromJson(dynamic json) {
    final map = <String, PromoProductPatch>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PromoProductPatch.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PromoProductPatch-objects as value to a dart map
  static Map<String, List<PromoProductPatch>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PromoProductPatch>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PromoProductPatch.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

