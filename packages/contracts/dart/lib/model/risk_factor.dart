//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class RiskFactor {
  /// Returns a new [RiskFactor] instance.
  RiskFactor({
    required this.key,
    required this.group,
    this.weight,
    required this.value,
    this.points,
    required this.known,
    this.detail = const {},
  });

  RiskFactorKeyEnum key;

  RiskFactorGroupEnum group;

  /// Absent for tenants.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? weight;

  /// Minimum value: 0
  /// Maximum value: 1
  num value;

  /// Contribution to the score; absent for tenants.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? points;

  /// false when there is no data (counted as 0).
  bool known;

  Map<String, Object> detail;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RiskFactor &&
    other.key == key &&
    other.group == group &&
    other.weight == weight &&
    other.value == value &&
    other.points == points &&
    other.known == known &&
    _deepEquality.equals(other.detail, detail);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (key.hashCode) +
    (group.hashCode) +
    (weight == null ? 0 : weight!.hashCode) +
    (value.hashCode) +
    (points == null ? 0 : points!.hashCode) +
    (known.hashCode) +
    (detail.hashCode);

  @override
  String toString() => 'RiskFactor[key=$key, group=$group, weight=$weight, value=$value, points=$points, known=$known, detail=$detail]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'key'] = this.key;
      json[r'group'] = this.group;
    if (this.weight != null) {
      json[r'weight'] = this.weight;
    } else {
      json[r'weight'] = null;
    }
      json[r'value'] = this.value;
    if (this.points != null) {
      json[r'points'] = this.points;
    } else {
      json[r'points'] = null;
    }
      json[r'known'] = this.known;
      json[r'detail'] = this.detail;
    return json;
  }

  /// Returns a new [RiskFactor] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RiskFactor? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "RiskFactor[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "RiskFactor[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return RiskFactor(
        key: RiskFactorKeyEnum.fromJson(json[r'key'])!,
        group: RiskFactorGroupEnum.fromJson(json[r'group'])!,
        weight: mapValueOfType<int>(json, r'weight'),
        value: num.parse('${json[r'value']}'),
        points: num.parse('${json[r'points']}'),
        known: mapValueOfType<bool>(json, r'known')!,
        detail: mapCastOfType<String, Object>(json, r'detail') ?? const {},
      );
    }
    return null;
  }

  static List<RiskFactor> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RiskFactor>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RiskFactor.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RiskFactor> mapFromJson(dynamic json) {
    final map = <String, RiskFactor>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RiskFactor.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RiskFactor-objects as value to a dart map
  static Map<String, List<RiskFactor>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RiskFactor>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RiskFactor.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'key',
    'group',
    'value',
    'known',
  };
}


class RiskFactorKeyEnum {
  /// Instantiate a new enum with the provided [value].
  const RiskFactorKeyEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const debt = RiskFactorKeyEnum._(r'debt');
  static const escalations = RiskFactorKeyEnum._(r'escalations');
  static const overdueDays = RiskFactorKeyEnum._(r'overdue_days');
  static const depositCoverage = RiskFactorKeyEnum._(r'deposit_coverage');
  static const passport = RiskFactorKeyEnum._(r'passport');
  static const termEnd = RiskFactorKeyEnum._(r'term_end');
  static const notice = RiskFactorKeyEnum._(r'notice');
  static const jointNonpayer = RiskFactorKeyEnum._(r'joint_nonpayer');
  static const marketRent = RiskFactorKeyEnum._(r'market_rent');
  static const marketSupply = RiskFactorKeyEnum._(r'market_supply');

  /// List of all possible values in this [enum][RiskFactorKeyEnum].
  static const values = <RiskFactorKeyEnum>[
    debt,
    escalations,
    overdueDays,
    depositCoverage,
    passport,
    termEnd,
    notice,
    jointNonpayer,
    marketRent,
    marketSupply,
  ];

  static RiskFactorKeyEnum? fromJson(dynamic value) => RiskFactorKeyEnumTypeTransformer().decode(value);

  static List<RiskFactorKeyEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RiskFactorKeyEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RiskFactorKeyEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [RiskFactorKeyEnum] to String,
/// and [decode] dynamic data back to [RiskFactorKeyEnum].
class RiskFactorKeyEnumTypeTransformer {
  factory RiskFactorKeyEnumTypeTransformer() => _instance ??= const RiskFactorKeyEnumTypeTransformer._();

  const RiskFactorKeyEnumTypeTransformer._();

  String encode(RiskFactorKeyEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a RiskFactorKeyEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  RiskFactorKeyEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'debt': return RiskFactorKeyEnum.debt;
        case r'escalations': return RiskFactorKeyEnum.escalations;
        case r'overdue_days': return RiskFactorKeyEnum.overdueDays;
        case r'deposit_coverage': return RiskFactorKeyEnum.depositCoverage;
        case r'passport': return RiskFactorKeyEnum.passport;
        case r'term_end': return RiskFactorKeyEnum.termEnd;
        case r'notice': return RiskFactorKeyEnum.notice;
        case r'joint_nonpayer': return RiskFactorKeyEnum.jointNonpayer;
        case r'market_rent': return RiskFactorKeyEnum.marketRent;
        case r'market_supply': return RiskFactorKeyEnum.marketSupply;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [RiskFactorKeyEnumTypeTransformer] instance.
  static RiskFactorKeyEnumTypeTransformer? _instance;
}



class RiskFactorGroupEnum {
  /// Instantiate a new enum with the provided [value].
  const RiskFactorGroupEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const payments = RiskFactorGroupEnum._(r'payments');
  static const deposit = RiskFactorGroupEnum._(r'deposit');
  static const passport = RiskFactorGroupEnum._(r'passport');
  static const contract = RiskFactorGroupEnum._(r'contract');
  static const location = RiskFactorGroupEnum._(r'location');

  /// List of all possible values in this [enum][RiskFactorGroupEnum].
  static const values = <RiskFactorGroupEnum>[
    payments,
    deposit,
    passport,
    contract,
    location,
  ];

  static RiskFactorGroupEnum? fromJson(dynamic value) => RiskFactorGroupEnumTypeTransformer().decode(value);

  static List<RiskFactorGroupEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RiskFactorGroupEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RiskFactorGroupEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [RiskFactorGroupEnum] to String,
/// and [decode] dynamic data back to [RiskFactorGroupEnum].
class RiskFactorGroupEnumTypeTransformer {
  factory RiskFactorGroupEnumTypeTransformer() => _instance ??= const RiskFactorGroupEnumTypeTransformer._();

  const RiskFactorGroupEnumTypeTransformer._();

  String encode(RiskFactorGroupEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a RiskFactorGroupEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  RiskFactorGroupEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'payments': return RiskFactorGroupEnum.payments;
        case r'deposit': return RiskFactorGroupEnum.deposit;
        case r'passport': return RiskFactorGroupEnum.passport;
        case r'contract': return RiskFactorGroupEnum.contract;
        case r'location': return RiskFactorGroupEnum.location;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [RiskFactorGroupEnumTypeTransformer] instance.
  static RiskFactorGroupEnumTypeTransformer? _instance;
}


