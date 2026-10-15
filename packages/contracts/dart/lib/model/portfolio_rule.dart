//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PortfolioRule {
  /// Returns a new [PortfolioRule] instance.
  PortfolioRule({
    required this.id,
    required this.scope,
    this.municipality,
    this.groupId,
    required this.scopeName,
    required this.rules,
    required this.updatedAt,
  });

  String id;

  PortfolioRuleScopeEnum scope;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? municipality;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? groupId;

  String scopeName;

  PortfolioRules rules;

  DateTime updatedAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PortfolioRule &&
    other.id == id &&
    other.scope == scope &&
    other.municipality == municipality &&
    other.groupId == groupId &&
    other.scopeName == scopeName &&
    other.rules == rules &&
    other.updatedAt == updatedAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (scope.hashCode) +
    (municipality == null ? 0 : municipality!.hashCode) +
    (groupId == null ? 0 : groupId!.hashCode) +
    (scopeName.hashCode) +
    (rules.hashCode) +
    (updatedAt.hashCode);

  @override
  String toString() => 'PortfolioRule[id=$id, scope=$scope, municipality=$municipality, groupId=$groupId, scopeName=$scopeName, rules=$rules, updatedAt=$updatedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'scope'] = this.scope;
    if (this.municipality != null) {
      json[r'municipality'] = this.municipality;
    } else {
      json[r'municipality'] = null;
    }
    if (this.groupId != null) {
      json[r'group_id'] = this.groupId;
    } else {
      json[r'group_id'] = null;
    }
      json[r'scope_name'] = this.scopeName;
      json[r'rules'] = this.rules;
      json[r'updated_at'] = this.updatedAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [PortfolioRule] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PortfolioRule? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PortfolioRule[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PortfolioRule[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PortfolioRule(
        id: mapValueOfType<String>(json, r'id')!,
        scope: PortfolioRuleScopeEnum.fromJson(json[r'scope'])!,
        municipality: mapValueOfType<String>(json, r'municipality'),
        groupId: mapValueOfType<String>(json, r'group_id'),
        scopeName: mapValueOfType<String>(json, r'scope_name')!,
        rules: PortfolioRules.fromJson(json[r'rules'])!,
        updatedAt: mapDateTime(json, r'updated_at', r'')!,
      );
    }
    return null;
  }

  static List<PortfolioRule> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PortfolioRule>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PortfolioRule.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PortfolioRule> mapFromJson(dynamic json) {
    final map = <String, PortfolioRule>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PortfolioRule.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PortfolioRule-objects as value to a dart map
  static Map<String, List<PortfolioRule>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PortfolioRule>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PortfolioRule.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'scope',
    'scope_name',
    'rules',
    'updated_at',
  };
}


class PortfolioRuleScopeEnum {
  /// Instantiate a new enum with the provided [value].
  const PortfolioRuleScopeEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const municipality = PortfolioRuleScopeEnum._(r'municipality');
  static const group = PortfolioRuleScopeEnum._(r'group');

  /// List of all possible values in this [enum][PortfolioRuleScopeEnum].
  static const values = <PortfolioRuleScopeEnum>[
    municipality,
    group,
  ];

  static PortfolioRuleScopeEnum? fromJson(dynamic value) => PortfolioRuleScopeEnumTypeTransformer().decode(value);

  static List<PortfolioRuleScopeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PortfolioRuleScopeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PortfolioRuleScopeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [PortfolioRuleScopeEnum] to String,
/// and [decode] dynamic data back to [PortfolioRuleScopeEnum].
class PortfolioRuleScopeEnumTypeTransformer {
  factory PortfolioRuleScopeEnumTypeTransformer() => _instance ??= const PortfolioRuleScopeEnumTypeTransformer._();

  const PortfolioRuleScopeEnumTypeTransformer._();

  String encode(PortfolioRuleScopeEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a PortfolioRuleScopeEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  PortfolioRuleScopeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'municipality': return PortfolioRuleScopeEnum.municipality;
        case r'group': return PortfolioRuleScopeEnum.group;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [PortfolioRuleScopeEnumTypeTransformer] instance.
  static PortfolioRuleScopeEnumTypeTransformer? _instance;
}


