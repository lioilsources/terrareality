//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PrescreenAnswer {
  /// Returns a new [PrescreenAnswer] instance.
  PrescreenAnswer({
    required this.id,
    required this.question,
    required this.kind,
    required this.answer,
  });

  String id;

  PrescreenAnswerQuestion question;

  PrescreenAnswerKindEnum kind;

  String answer;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PrescreenAnswer &&
    other.id == id &&
    other.question == question &&
    other.kind == kind &&
    other.answer == answer;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (question.hashCode) +
    (kind.hashCode) +
    (answer.hashCode);

  @override
  String toString() => 'PrescreenAnswer[id=$id, question=$question, kind=$kind, answer=$answer]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'question'] = this.question;
      json[r'kind'] = this.kind;
      json[r'answer'] = this.answer;
    return json;
  }

  /// Returns a new [PrescreenAnswer] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PrescreenAnswer? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PrescreenAnswer[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PrescreenAnswer[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PrescreenAnswer(
        id: mapValueOfType<String>(json, r'id')!,
        question: PrescreenAnswerQuestion.fromJson(json[r'question'])!,
        kind: PrescreenAnswerKindEnum.fromJson(json[r'kind'])!,
        answer: mapValueOfType<String>(json, r'answer')!,
      );
    }
    return null;
  }

  static List<PrescreenAnswer> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PrescreenAnswer>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PrescreenAnswer.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PrescreenAnswer> mapFromJson(dynamic json) {
    final map = <String, PrescreenAnswer>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PrescreenAnswer.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PrescreenAnswer-objects as value to a dart map
  static Map<String, List<PrescreenAnswer>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PrescreenAnswer>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PrescreenAnswer.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'question',
    'kind',
    'answer',
  };
}


class PrescreenAnswerKindEnum {
  /// Instantiate a new enum with the provided [value].
  const PrescreenAnswerKindEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const text = PrescreenAnswerKindEnum._(r'text');
  static const yesNo = PrescreenAnswerKindEnum._(r'yes_no');
  static const number = PrescreenAnswerKindEnum._(r'number');

  /// List of all possible values in this [enum][PrescreenAnswerKindEnum].
  static const values = <PrescreenAnswerKindEnum>[
    text,
    yesNo,
    number,
  ];

  static PrescreenAnswerKindEnum? fromJson(dynamic value) => PrescreenAnswerKindEnumTypeTransformer().decode(value);

  static List<PrescreenAnswerKindEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PrescreenAnswerKindEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PrescreenAnswerKindEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [PrescreenAnswerKindEnum] to String,
/// and [decode] dynamic data back to [PrescreenAnswerKindEnum].
class PrescreenAnswerKindEnumTypeTransformer {
  factory PrescreenAnswerKindEnumTypeTransformer() => _instance ??= const PrescreenAnswerKindEnumTypeTransformer._();

  const PrescreenAnswerKindEnumTypeTransformer._();

  String encode(PrescreenAnswerKindEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a PrescreenAnswerKindEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  PrescreenAnswerKindEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'text': return PrescreenAnswerKindEnum.text;
        case r'yes_no': return PrescreenAnswerKindEnum.yesNo;
        case r'number': return PrescreenAnswerKindEnum.number;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [PrescreenAnswerKindEnumTypeTransformer] instance.
  static PrescreenAnswerKindEnumTypeTransformer? _instance;
}


