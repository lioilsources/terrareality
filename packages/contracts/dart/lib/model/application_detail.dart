//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ApplicationDetail {
  /// Returns a new [ApplicationDetail] instance.
  ApplicationDetail({
    required this.application,
    this.consents = const [],
    this.slots = const [],
    this.booking,
  });

  Application application;

  List<ApplicationConsent> consents;

  List<ViewingSlot> slots;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  Viewing? booking;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ApplicationDetail &&
    other.application == application &&
    _deepEquality.equals(other.consents, consents) &&
    _deepEquality.equals(other.slots, slots) &&
    other.booking == booking;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (application.hashCode) +
    (consents.hashCode) +
    (slots.hashCode) +
    (booking == null ? 0 : booking!.hashCode);

  @override
  String toString() => 'ApplicationDetail[application=$application, consents=$consents, slots=$slots, booking=$booking]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'application'] = this.application;
      json[r'consents'] = this.consents;
      json[r'slots'] = this.slots;
    if (this.booking != null) {
      json[r'booking'] = this.booking;
    } else {
      json[r'booking'] = null;
    }
    return json;
  }

  /// Returns a new [ApplicationDetail] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ApplicationDetail? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ApplicationDetail[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ApplicationDetail[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ApplicationDetail(
        application: Application.fromJson(json[r'application'])!,
        consents: ApplicationConsent.listFromJson(json[r'consents']),
        slots: ViewingSlot.listFromJson(json[r'slots']),
        booking: Viewing.fromJson(json[r'booking']),
      );
    }
    return null;
  }

  static List<ApplicationDetail> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ApplicationDetail>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ApplicationDetail.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ApplicationDetail> mapFromJson(dynamic json) {
    final map = <String, ApplicationDetail>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ApplicationDetail.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ApplicationDetail-objects as value to a dart map
  static Map<String, List<ApplicationDetail>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ApplicationDetail>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ApplicationDetail.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'application',
    'consents',
    'slots',
  };
}

