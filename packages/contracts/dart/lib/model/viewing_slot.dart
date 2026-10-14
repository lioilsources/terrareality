//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ViewingSlot {
  /// Returns a new [ViewingSlot] instance.
  ViewingSlot({
    required this.id,
    required this.startsAt,
    required this.durationMin,
    required this.capacity,
    required this.booked,
    required this.note,
    this.bookings = const [],
  });

  String id;

  DateTime startsAt;

  int durationMin;

  int capacity;

  int booked;

  String note;

  /// Landlord view only.
  List<ViewingSlotBookingsInner> bookings;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ViewingSlot &&
    other.id == id &&
    other.startsAt == startsAt &&
    other.durationMin == durationMin &&
    other.capacity == capacity &&
    other.booked == booked &&
    other.note == note &&
    _deepEquality.equals(other.bookings, bookings);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (startsAt.hashCode) +
    (durationMin.hashCode) +
    (capacity.hashCode) +
    (booked.hashCode) +
    (note.hashCode) +
    (bookings.hashCode);

  @override
  String toString() => 'ViewingSlot[id=$id, startsAt=$startsAt, durationMin=$durationMin, capacity=$capacity, booked=$booked, note=$note, bookings=$bookings]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'starts_at'] = this.startsAt.toUtc().toIso8601String();
      json[r'duration_min'] = this.durationMin;
      json[r'capacity'] = this.capacity;
      json[r'booked'] = this.booked;
      json[r'note'] = this.note;
      json[r'bookings'] = this.bookings;
    return json;
  }

  /// Returns a new [ViewingSlot] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ViewingSlot? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ViewingSlot[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ViewingSlot[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ViewingSlot(
        id: mapValueOfType<String>(json, r'id')!,
        startsAt: mapDateTime(json, r'starts_at', r'')!,
        durationMin: mapValueOfType<int>(json, r'duration_min')!,
        capacity: mapValueOfType<int>(json, r'capacity')!,
        booked: mapValueOfType<int>(json, r'booked')!,
        note: mapValueOfType<String>(json, r'note')!,
        bookings: ViewingSlotBookingsInner.listFromJson(json[r'bookings']),
      );
    }
    return null;
  }

  static List<ViewingSlot> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ViewingSlot>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ViewingSlot.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ViewingSlot> mapFromJson(dynamic json) {
    final map = <String, ViewingSlot>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ViewingSlot.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ViewingSlot-objects as value to a dart map
  static Map<String, List<ViewingSlot>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ViewingSlot>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ViewingSlot.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'starts_at',
    'duration_min',
    'capacity',
    'booked',
    'note',
    'bookings',
  };
}

