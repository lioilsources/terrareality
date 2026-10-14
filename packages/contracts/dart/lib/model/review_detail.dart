//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ReviewDetail {
  /// Returns a new [ReviewDetail] instance.
  ReviewDetail({
    required this.item,
    this.snapshot = const {},
    this.photos = const [],
  });

  ReviewItem item;

  Map<String, Object> snapshot;

  List<PhotoVariants> photos;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ReviewDetail &&
    other.item == item &&
    _deepEquality.equals(other.snapshot, snapshot) &&
    _deepEquality.equals(other.photos, photos);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (item.hashCode) +
    (snapshot.hashCode) +
    (photos.hashCode);

  @override
  String toString() => 'ReviewDetail[item=$item, snapshot=$snapshot, photos=$photos]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'item'] = this.item;
      json[r'snapshot'] = this.snapshot;
      json[r'photos'] = this.photos;
    return json;
  }

  /// Returns a new [ReviewDetail] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ReviewDetail? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ReviewDetail[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ReviewDetail[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ReviewDetail(
        item: ReviewItem.fromJson(json[r'item'])!,
        snapshot: mapCastOfType<String, Object>(json, r'snapshot')!,
        photos: PhotoVariants.listFromJson(json[r'photos']),
      );
    }
    return null;
  }

  static List<ReviewDetail> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ReviewDetail>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ReviewDetail.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ReviewDetail> mapFromJson(dynamic json) {
    final map = <String, ReviewDetail>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ReviewDetail.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ReviewDetail-objects as value to a dart map
  static Map<String, List<ReviewDetail>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ReviewDetail>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ReviewDetail.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'item',
    'snapshot',
    'photos',
  };
}

