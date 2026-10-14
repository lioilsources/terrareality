//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class RoommateMatch {
  /// Returns a new [RoommateMatch] instance.
  RoommateMatch({
    required this.userId,
    required this.displayName,
    required this.verificationLevel,
    required this.profile,
    required this.score,
  });

  String userId;

  String displayName;

  VerificationLevel verificationLevel;

  RoommateProfile profile;

  /// Minimum value: 0
  /// Maximum value: 100
  int score;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RoommateMatch &&
    other.userId == userId &&
    other.displayName == displayName &&
    other.verificationLevel == verificationLevel &&
    other.profile == profile &&
    other.score == score;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (userId.hashCode) +
    (displayName.hashCode) +
    (verificationLevel.hashCode) +
    (profile.hashCode) +
    (score.hashCode);

  @override
  String toString() => 'RoommateMatch[userId=$userId, displayName=$displayName, verificationLevel=$verificationLevel, profile=$profile, score=$score]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'user_id'] = this.userId;
      json[r'display_name'] = this.displayName;
      json[r'verification_level'] = this.verificationLevel;
      json[r'profile'] = this.profile;
      json[r'score'] = this.score;
    return json;
  }

  /// Returns a new [RoommateMatch] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RoommateMatch? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "RoommateMatch[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "RoommateMatch[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return RoommateMatch(
        userId: mapValueOfType<String>(json, r'user_id')!,
        displayName: mapValueOfType<String>(json, r'display_name')!,
        verificationLevel: VerificationLevel.fromJson(json[r'verification_level'])!,
        profile: RoommateProfile.fromJson(json[r'profile'])!,
        score: mapValueOfType<int>(json, r'score')!,
      );
    }
    return null;
  }

  static List<RoommateMatch> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RoommateMatch>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RoommateMatch.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RoommateMatch> mapFromJson(dynamic json) {
    final map = <String, RoommateMatch>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RoommateMatch.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RoommateMatch-objects as value to a dart map
  static Map<String, List<RoommateMatch>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RoommateMatch>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RoommateMatch.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'user_id',
    'display_name',
    'verification_level',
    'profile',
    'score',
  };
}

