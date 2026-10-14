//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class RoommateProfile {
  /// Returns a new [RoommateProfile] instance.
  RoommateProfile({
    required this.active,
    this.adminPath,
    this.areaLabel,
    required this.budgetMax,
    this.moveIn,
    this.about,
    this.lifestyle = const [],
    required this.hasRoom,
  });

  bool active;

  /// Admin unit path (from /v1/areas); empty = anywhere.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? adminPath;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? areaLabel;

  /// Monthly budget in minor units (CZK).
  ///
  /// Minimum value: 1
  int budgetMax;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? moveIn;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? about;

  List<RoommateProfileLifestyleEnum> lifestyle;

  /// Offers a room in their own flat.
  bool hasRoom;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RoommateProfile &&
    other.active == active &&
    other.adminPath == adminPath &&
    other.areaLabel == areaLabel &&
    other.budgetMax == budgetMax &&
    other.moveIn == moveIn &&
    other.about == about &&
    _deepEquality.equals(other.lifestyle, lifestyle) &&
    other.hasRoom == hasRoom;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (active.hashCode) +
    (adminPath == null ? 0 : adminPath!.hashCode) +
    (areaLabel == null ? 0 : areaLabel!.hashCode) +
    (budgetMax.hashCode) +
    (moveIn == null ? 0 : moveIn!.hashCode) +
    (about == null ? 0 : about!.hashCode) +
    (lifestyle.hashCode) +
    (hasRoom.hashCode);

  @override
  String toString() => 'RoommateProfile[active=$active, adminPath=$adminPath, areaLabel=$areaLabel, budgetMax=$budgetMax, moveIn=$moveIn, about=$about, lifestyle=$lifestyle, hasRoom=$hasRoom]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'active'] = this.active;
    if (this.adminPath != null) {
      json[r'admin_path'] = this.adminPath;
    } else {
      json[r'admin_path'] = null;
    }
    if (this.areaLabel != null) {
      json[r'area_label'] = this.areaLabel;
    } else {
      json[r'area_label'] = null;
    }
      json[r'budget_max'] = this.budgetMax;
    if (this.moveIn != null) {
      json[r'move_in'] = _dateFormatter.format(this.moveIn!.toUtc());
    } else {
      json[r'move_in'] = null;
    }
    if (this.about != null) {
      json[r'about'] = this.about;
    } else {
      json[r'about'] = null;
    }
      json[r'lifestyle'] = this.lifestyle;
      json[r'has_room'] = this.hasRoom;
    return json;
  }

  /// Returns a new [RoommateProfile] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RoommateProfile? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "RoommateProfile[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "RoommateProfile[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return RoommateProfile(
        active: mapValueOfType<bool>(json, r'active')!,
        adminPath: mapValueOfType<String>(json, r'admin_path'),
        areaLabel: mapValueOfType<String>(json, r'area_label'),
        budgetMax: mapValueOfType<int>(json, r'budget_max')!,
        moveIn: mapDateTime(json, r'move_in', r''),
        about: mapValueOfType<String>(json, r'about'),
        lifestyle: RoommateProfileLifestyleEnum.listFromJson(json[r'lifestyle']),
        hasRoom: mapValueOfType<bool>(json, r'has_room')!,
      );
    }
    return null;
  }

  static List<RoommateProfile> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RoommateProfile>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RoommateProfile.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RoommateProfile> mapFromJson(dynamic json) {
    final map = <String, RoommateProfile>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RoommateProfile.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RoommateProfile-objects as value to a dart map
  static Map<String, List<RoommateProfile>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RoommateProfile>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RoommateProfile.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'active',
    'budget_max',
    'lifestyle',
    'has_room',
  };
}


class RoommateProfileLifestyleEnum {
  /// Instantiate a new enum with the provided [value].
  const RoommateProfileLifestyleEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const nonSmoker = RoommateProfileLifestyleEnum._(r'non_smoker');
  static const smoker = RoommateProfileLifestyleEnum._(r'smoker');
  static const pets = RoommateProfileLifestyleEnum._(r'pets');
  static const noPets = RoommateProfileLifestyleEnum._(r'no_pets');
  static const quiet = RoommateProfileLifestyleEnum._(r'quiet');
  static const social = RoommateProfileLifestyleEnum._(r'social');
  static const earlyBird = RoommateProfileLifestyleEnum._(r'early_bird');
  static const nightOwl = RoommateProfileLifestyleEnum._(r'night_owl');
  static const worksFromHome = RoommateProfileLifestyleEnum._(r'works_from_home');
  static const student = RoommateProfileLifestyleEnum._(r'student');
  static const tidy = RoommateProfileLifestyleEnum._(r'tidy');
  static const vegetarian = RoommateProfileLifestyleEnum._(r'vegetarian');

  /// List of all possible values in this [enum][RoommateProfileLifestyleEnum].
  static const values = <RoommateProfileLifestyleEnum>[
    nonSmoker,
    smoker,
    pets,
    noPets,
    quiet,
    social,
    earlyBird,
    nightOwl,
    worksFromHome,
    student,
    tidy,
    vegetarian,
  ];

  static RoommateProfileLifestyleEnum? fromJson(dynamic value) => RoommateProfileLifestyleEnumTypeTransformer().decode(value);

  static List<RoommateProfileLifestyleEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RoommateProfileLifestyleEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RoommateProfileLifestyleEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [RoommateProfileLifestyleEnum] to String,
/// and [decode] dynamic data back to [RoommateProfileLifestyleEnum].
class RoommateProfileLifestyleEnumTypeTransformer {
  factory RoommateProfileLifestyleEnumTypeTransformer() => _instance ??= const RoommateProfileLifestyleEnumTypeTransformer._();

  const RoommateProfileLifestyleEnumTypeTransformer._();

  String encode(RoommateProfileLifestyleEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a RoommateProfileLifestyleEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  RoommateProfileLifestyleEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'non_smoker': return RoommateProfileLifestyleEnum.nonSmoker;
        case r'smoker': return RoommateProfileLifestyleEnum.smoker;
        case r'pets': return RoommateProfileLifestyleEnum.pets;
        case r'no_pets': return RoommateProfileLifestyleEnum.noPets;
        case r'quiet': return RoommateProfileLifestyleEnum.quiet;
        case r'social': return RoommateProfileLifestyleEnum.social;
        case r'early_bird': return RoommateProfileLifestyleEnum.earlyBird;
        case r'night_owl': return RoommateProfileLifestyleEnum.nightOwl;
        case r'works_from_home': return RoommateProfileLifestyleEnum.worksFromHome;
        case r'student': return RoommateProfileLifestyleEnum.student;
        case r'tidy': return RoommateProfileLifestyleEnum.tidy;
        case r'vegetarian': return RoommateProfileLifestyleEnum.vegetarian;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [RoommateProfileLifestyleEnumTypeTransformer] instance.
  static RoommateProfileLifestyleEnumTypeTransformer? _instance;
}


