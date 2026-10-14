//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Viewing {
  /// Returns a new [Viewing] instance.
  Viewing({
    required this.id,
    required this.applicationId,
    required this.listingId,
    required this.listingTitle,
    this.city,
    required this.startsAt,
    required this.durationMin,
    required this.note,
  });

  String id;

  String applicationId;

  String listingId;

  I18nText listingTitle;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? city;

  DateTime startsAt;

  int durationMin;

  String note;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Viewing &&
    other.id == id &&
    other.applicationId == applicationId &&
    other.listingId == listingId &&
    other.listingTitle == listingTitle &&
    other.city == city &&
    other.startsAt == startsAt &&
    other.durationMin == durationMin &&
    other.note == note;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (applicationId.hashCode) +
    (listingId.hashCode) +
    (listingTitle.hashCode) +
    (city == null ? 0 : city!.hashCode) +
    (startsAt.hashCode) +
    (durationMin.hashCode) +
    (note.hashCode);

  @override
  String toString() => 'Viewing[id=$id, applicationId=$applicationId, listingId=$listingId, listingTitle=$listingTitle, city=$city, startsAt=$startsAt, durationMin=$durationMin, note=$note]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'application_id'] = this.applicationId;
      json[r'listing_id'] = this.listingId;
      json[r'listing_title'] = this.listingTitle;
    if (this.city != null) {
      json[r'city'] = this.city;
    } else {
      json[r'city'] = null;
    }
      json[r'starts_at'] = this.startsAt.toUtc().toIso8601String();
      json[r'duration_min'] = this.durationMin;
      json[r'note'] = this.note;
    return json;
  }

  /// Returns a new [Viewing] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Viewing? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "Viewing[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "Viewing[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Viewing(
        id: mapValueOfType<String>(json, r'id')!,
        applicationId: mapValueOfType<String>(json, r'application_id')!,
        listingId: mapValueOfType<String>(json, r'listing_id')!,
        listingTitle: I18nText.fromJson(json[r'listing_title'])!,
        city: mapValueOfType<String>(json, r'city'),
        startsAt: mapDateTime(json, r'starts_at', r'')!,
        durationMin: mapValueOfType<int>(json, r'duration_min')!,
        note: mapValueOfType<String>(json, r'note')!,
      );
    }
    return null;
  }

  static List<Viewing> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Viewing>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Viewing.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Viewing> mapFromJson(dynamic json) {
    final map = <String, Viewing>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Viewing.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Viewing-objects as value to a dart map
  static Map<String, List<Viewing>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Viewing>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Viewing.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'application_id',
    'listing_id',
    'listing_title',
    'starts_at',
    'duration_min',
    'note',
  };
}

