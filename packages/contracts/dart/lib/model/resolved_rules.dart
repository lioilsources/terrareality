//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ResolvedRules {
  /// Returns a new [ResolvedRules] instance.
  ResolvedRules({
    required this.rules,
    this.sources = const [],
    required this.place,
  });

  PortfolioRules rules;

  List<ResolvedRulesSourcesEnum> sources;

  /// Municipality name; empty when unknown.
  String place;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ResolvedRules &&
    other.rules == rules &&
    _deepEquality.equals(other.sources, sources) &&
    other.place == place;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (rules.hashCode) +
    (sources.hashCode) +
    (place.hashCode);

  @override
  String toString() => 'ResolvedRules[rules=$rules, sources=$sources, place=$place]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'rules'] = this.rules;
      json[r'sources'] = this.sources;
      json[r'place'] = this.place;
    return json;
  }

  /// Returns a new [ResolvedRules] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ResolvedRules? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ResolvedRules[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ResolvedRules[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ResolvedRules(
        rules: PortfolioRules.fromJson(json[r'rules'])!,
        sources: ResolvedRulesSourcesEnum.listFromJson(json[r'sources']),
        place: mapValueOfType<String>(json, r'place')!,
      );
    }
    return null;
  }

  static List<ResolvedRules> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ResolvedRules>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ResolvedRules.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ResolvedRules> mapFromJson(dynamic json) {
    final map = <String, ResolvedRules>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ResolvedRules.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ResolvedRules-objects as value to a dart map
  static Map<String, List<ResolvedRules>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ResolvedRules>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ResolvedRules.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'rules',
    'sources',
    'place',
  };
}


class ResolvedRulesSourcesEnum {
  /// Instantiate a new enum with the provided [value].
  const ResolvedRulesSourcesEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const jurisdiction = ResolvedRulesSourcesEnum._(r'jurisdiction');
  static const municipality = ResolvedRulesSourcesEnum._(r'municipality');
  static const group = ResolvedRulesSourcesEnum._(r'group');

  /// List of all possible values in this [enum][ResolvedRulesSourcesEnum].
  static const values = <ResolvedRulesSourcesEnum>[
    jurisdiction,
    municipality,
    group,
  ];

  static ResolvedRulesSourcesEnum? fromJson(dynamic value) => ResolvedRulesSourcesEnumTypeTransformer().decode(value);

  static List<ResolvedRulesSourcesEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ResolvedRulesSourcesEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ResolvedRulesSourcesEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ResolvedRulesSourcesEnum] to String,
/// and [decode] dynamic data back to [ResolvedRulesSourcesEnum].
class ResolvedRulesSourcesEnumTypeTransformer {
  factory ResolvedRulesSourcesEnumTypeTransformer() => _instance ??= const ResolvedRulesSourcesEnumTypeTransformer._();

  const ResolvedRulesSourcesEnumTypeTransformer._();

  String encode(ResolvedRulesSourcesEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a ResolvedRulesSourcesEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ResolvedRulesSourcesEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'jurisdiction': return ResolvedRulesSourcesEnum.jurisdiction;
        case r'municipality': return ResolvedRulesSourcesEnum.municipality;
        case r'group': return ResolvedRulesSourcesEnum.group;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ResolvedRulesSourcesEnumTypeTransformer] instance.
  static ResolvedRulesSourcesEnumTypeTransformer? _instance;
}


