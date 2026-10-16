//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class GiveLeaseNoticeRequest {
  /// Returns a new [GiveLeaseNoticeRequest] instance.
  GiveLeaseNoticeRequest({
    required this.deliveredOn,
    this.reason,
    this.explanation,
  });

  DateTime deliveredOn;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  LandlordNoticeReason? reason;

  /// Facts behind the reason; required for other_serious_reason.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? explanation;

  @override
  bool operator ==(Object other) => identical(this, other) || other is GiveLeaseNoticeRequest &&
    other.deliveredOn == deliveredOn &&
    other.reason == reason &&
    other.explanation == explanation;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (deliveredOn.hashCode) +
    (reason == null ? 0 : reason!.hashCode) +
    (explanation == null ? 0 : explanation!.hashCode);

  @override
  String toString() => 'GiveLeaseNoticeRequest[deliveredOn=$deliveredOn, reason=$reason, explanation=$explanation]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'delivered_on'] = _dateFormatter.format(this.deliveredOn.toUtc());
    if (this.reason != null) {
      json[r'reason'] = this.reason;
    } else {
      json[r'reason'] = null;
    }
    if (this.explanation != null) {
      json[r'explanation'] = this.explanation;
    } else {
      json[r'explanation'] = null;
    }
    return json;
  }

  /// Returns a new [GiveLeaseNoticeRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GiveLeaseNoticeRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "GiveLeaseNoticeRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "GiveLeaseNoticeRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return GiveLeaseNoticeRequest(
        deliveredOn: mapDateTime(json, r'delivered_on', r'')!,
        reason: LandlordNoticeReason.fromJson(json[r'reason']),
        explanation: mapValueOfType<String>(json, r'explanation'),
      );
    }
    return null;
  }

  static List<GiveLeaseNoticeRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <GiveLeaseNoticeRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GiveLeaseNoticeRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GiveLeaseNoticeRequest> mapFromJson(dynamic json) {
    final map = <String, GiveLeaseNoticeRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GiveLeaseNoticeRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GiveLeaseNoticeRequest-objects as value to a dart map
  static Map<String, List<GiveLeaseNoticeRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<GiveLeaseNoticeRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GiveLeaseNoticeRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'delivered_on',
  };
}

