//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AttributeSuggestionDecision {
  /// Returns a new [AttributeSuggestionDecision] instance.
  AttributeSuggestionDecision({
    required this.decision,
    this.note,
  });

  AttributeSuggestionDecisionDecisionEnum decision;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? note;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AttributeSuggestionDecision &&
    other.decision == decision &&
    other.note == note;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (decision.hashCode) +
    (note == null ? 0 : note!.hashCode);

  @override
  String toString() => 'AttributeSuggestionDecision[decision=$decision, note=$note]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'decision'] = this.decision;
    if (this.note != null) {
      json[r'note'] = this.note;
    } else {
      json[r'note'] = null;
    }
    return json;
  }

  /// Returns a new [AttributeSuggestionDecision] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AttributeSuggestionDecision? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "AttributeSuggestionDecision[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "AttributeSuggestionDecision[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return AttributeSuggestionDecision(
        decision: AttributeSuggestionDecisionDecisionEnum.fromJson(json[r'decision'])!,
        note: mapValueOfType<String>(json, r'note'),
      );
    }
    return null;
  }

  static List<AttributeSuggestionDecision> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AttributeSuggestionDecision>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AttributeSuggestionDecision.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AttributeSuggestionDecision> mapFromJson(dynamic json) {
    final map = <String, AttributeSuggestionDecision>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AttributeSuggestionDecision.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AttributeSuggestionDecision-objects as value to a dart map
  static Map<String, List<AttributeSuggestionDecision>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AttributeSuggestionDecision>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AttributeSuggestionDecision.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'decision',
  };
}


class AttributeSuggestionDecisionDecisionEnum {
  /// Instantiate a new enum with the provided [value].
  const AttributeSuggestionDecisionDecisionEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const approve = AttributeSuggestionDecisionDecisionEnum._(r'approve');
  static const reject = AttributeSuggestionDecisionDecisionEnum._(r'reject');

  /// List of all possible values in this [enum][AttributeSuggestionDecisionDecisionEnum].
  static const values = <AttributeSuggestionDecisionDecisionEnum>[
    approve,
    reject,
  ];

  static AttributeSuggestionDecisionDecisionEnum? fromJson(dynamic value) => AttributeSuggestionDecisionDecisionEnumTypeTransformer().decode(value);

  static List<AttributeSuggestionDecisionDecisionEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AttributeSuggestionDecisionDecisionEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AttributeSuggestionDecisionDecisionEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [AttributeSuggestionDecisionDecisionEnum] to String,
/// and [decode] dynamic data back to [AttributeSuggestionDecisionDecisionEnum].
class AttributeSuggestionDecisionDecisionEnumTypeTransformer {
  factory AttributeSuggestionDecisionDecisionEnumTypeTransformer() => _instance ??= const AttributeSuggestionDecisionDecisionEnumTypeTransformer._();

  const AttributeSuggestionDecisionDecisionEnumTypeTransformer._();

  String encode(AttributeSuggestionDecisionDecisionEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a AttributeSuggestionDecisionDecisionEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  AttributeSuggestionDecisionDecisionEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'approve': return AttributeSuggestionDecisionDecisionEnum.approve;
        case r'reject': return AttributeSuggestionDecisionDecisionEnum.reject;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [AttributeSuggestionDecisionDecisionEnumTypeTransformer] instance.
  static AttributeSuggestionDecisionDecisionEnumTypeTransformer? _instance;
}


