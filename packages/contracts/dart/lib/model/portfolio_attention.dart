//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PortfolioAttention {
  /// Returns a new [PortfolioAttention] instance.
  PortfolioAttention({
    required this.kind,
    required this.severity,
    this.leaseId,
    this.unitId,
    required this.label,
    required this.city,
    this.amount,
    this.date,
    this.score,
  });

  PortfolioAttentionKindEnum kind;

  /// Minimum value: 1
  /// Maximum value: 3
  int severity;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? leaseId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? unitId;

  String label;

  String city;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? amount;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? date;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? score;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PortfolioAttention &&
    other.kind == kind &&
    other.severity == severity &&
    other.leaseId == leaseId &&
    other.unitId == unitId &&
    other.label == label &&
    other.city == city &&
    other.amount == amount &&
    other.date == date &&
    other.score == score;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (kind.hashCode) +
    (severity.hashCode) +
    (leaseId == null ? 0 : leaseId!.hashCode) +
    (unitId == null ? 0 : unitId!.hashCode) +
    (label.hashCode) +
    (city.hashCode) +
    (amount == null ? 0 : amount!.hashCode) +
    (date == null ? 0 : date!.hashCode) +
    (score == null ? 0 : score!.hashCode);

  @override
  String toString() => 'PortfolioAttention[kind=$kind, severity=$severity, leaseId=$leaseId, unitId=$unitId, label=$label, city=$city, amount=$amount, date=$date, score=$score]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'kind'] = this.kind;
      json[r'severity'] = this.severity;
    if (this.leaseId != null) {
      json[r'lease_id'] = this.leaseId;
    } else {
      json[r'lease_id'] = null;
    }
    if (this.unitId != null) {
      json[r'unit_id'] = this.unitId;
    } else {
      json[r'unit_id'] = null;
    }
      json[r'label'] = this.label;
      json[r'city'] = this.city;
    if (this.amount != null) {
      json[r'amount'] = this.amount;
    } else {
      json[r'amount'] = null;
    }
    if (this.date != null) {
      json[r'date'] = _dateFormatter.format(this.date!.toUtc());
    } else {
      json[r'date'] = null;
    }
    if (this.score != null) {
      json[r'score'] = this.score;
    } else {
      json[r'score'] = null;
    }
    return json;
  }

  /// Returns a new [PortfolioAttention] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PortfolioAttention? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PortfolioAttention[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PortfolioAttention[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PortfolioAttention(
        kind: PortfolioAttentionKindEnum.fromJson(json[r'kind'])!,
        severity: mapValueOfType<int>(json, r'severity')!,
        leaseId: mapValueOfType<String>(json, r'lease_id'),
        unitId: mapValueOfType<String>(json, r'unit_id'),
        label: mapValueOfType<String>(json, r'label')!,
        city: mapValueOfType<String>(json, r'city')!,
        amount: mapValueOfType<int>(json, r'amount'),
        date: mapDateTime(json, r'date', r''),
        score: mapValueOfType<int>(json, r'score'),
      );
    }
    return null;
  }

  static List<PortfolioAttention> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PortfolioAttention>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PortfolioAttention.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PortfolioAttention> mapFromJson(dynamic json) {
    final map = <String, PortfolioAttention>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PortfolioAttention.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PortfolioAttention-objects as value to a dart map
  static Map<String, List<PortfolioAttention>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PortfolioAttention>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PortfolioAttention.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'kind',
    'severity',
    'label',
    'city',
  };
}


class PortfolioAttentionKindEnum {
  /// Instantiate a new enum with the provided [value].
  const PortfolioAttentionKindEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const escalation = PortfolioAttentionKindEnum._(r'escalation');
  static const debt = PortfolioAttentionKindEnum._(r'debt');
  static const ending = PortfolioAttentionKindEnum._(r'ending');
  static const notice = PortfolioAttentionKindEnum._(r'notice');
  static const vacant = PortfolioAttentionKindEnum._(r'vacant');
  static const highRisk = PortfolioAttentionKindEnum._(r'high_risk');

  /// List of all possible values in this [enum][PortfolioAttentionKindEnum].
  static const values = <PortfolioAttentionKindEnum>[
    escalation,
    debt,
    ending,
    notice,
    vacant,
    highRisk,
  ];

  static PortfolioAttentionKindEnum? fromJson(dynamic value) => PortfolioAttentionKindEnumTypeTransformer().decode(value);

  static List<PortfolioAttentionKindEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PortfolioAttentionKindEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PortfolioAttentionKindEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [PortfolioAttentionKindEnum] to String,
/// and [decode] dynamic data back to [PortfolioAttentionKindEnum].
class PortfolioAttentionKindEnumTypeTransformer {
  factory PortfolioAttentionKindEnumTypeTransformer() => _instance ??= const PortfolioAttentionKindEnumTypeTransformer._();

  const PortfolioAttentionKindEnumTypeTransformer._();

  String encode(PortfolioAttentionKindEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a PortfolioAttentionKindEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  PortfolioAttentionKindEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'escalation': return PortfolioAttentionKindEnum.escalation;
        case r'debt': return PortfolioAttentionKindEnum.debt;
        case r'ending': return PortfolioAttentionKindEnum.ending;
        case r'notice': return PortfolioAttentionKindEnum.notice;
        case r'vacant': return PortfolioAttentionKindEnum.vacant;
        case r'high_risk': return PortfolioAttentionKindEnum.highRisk;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [PortfolioAttentionKindEnumTypeTransformer] instance.
  static PortfolioAttentionKindEnumTypeTransformer? _instance;
}


