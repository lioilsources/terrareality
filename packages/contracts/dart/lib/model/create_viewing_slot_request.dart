//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CreateViewingSlotRequest {
  /// Returns a new [CreateViewingSlotRequest] instance.
  CreateViewingSlotRequest({
    required this.startsAt,
    this.durationMin = 20,
    this.capacity = 1,
    this.note,
  });

  DateTime startsAt;

  /// Minimum value: 5
  /// Maximum value: 240
  int durationMin;

  /// Minimum value: 1
  /// Maximum value: 50
  int capacity;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? note;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CreateViewingSlotRequest &&
    other.startsAt == startsAt &&
    other.durationMin == durationMin &&
    other.capacity == capacity &&
    other.note == note;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (startsAt.hashCode) +
    (durationMin.hashCode) +
    (capacity.hashCode) +
    (note == null ? 0 : note!.hashCode);

  @override
  String toString() => 'CreateViewingSlotRequest[startsAt=$startsAt, durationMin=$durationMin, capacity=$capacity, note=$note]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'starts_at'] = this.startsAt.toUtc().toIso8601String();
      json[r'duration_min'] = this.durationMin;
      json[r'capacity'] = this.capacity;
    if (this.note != null) {
      json[r'note'] = this.note;
    } else {
      json[r'note'] = null;
    }
    return json;
  }

  /// Returns a new [CreateViewingSlotRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CreateViewingSlotRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "CreateViewingSlotRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "CreateViewingSlotRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return CreateViewingSlotRequest(
        startsAt: mapDateTime(json, r'starts_at', r'')!,
        durationMin: mapValueOfType<int>(json, r'duration_min') ?? 20,
        capacity: mapValueOfType<int>(json, r'capacity') ?? 1,
        note: mapValueOfType<String>(json, r'note'),
      );
    }
    return null;
  }

  static List<CreateViewingSlotRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CreateViewingSlotRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreateViewingSlotRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CreateViewingSlotRequest> mapFromJson(dynamic json) {
    final map = <String, CreateViewingSlotRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CreateViewingSlotRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CreateViewingSlotRequest-objects as value to a dart map
  static Map<String, List<CreateViewingSlotRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CreateViewingSlotRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CreateViewingSlotRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'starts_at',
  };
}

