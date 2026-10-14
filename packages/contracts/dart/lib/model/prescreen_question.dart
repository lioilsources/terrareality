//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PrescreenQuestion {
  /// Returns a new [PrescreenQuestion] instance.
  PrescreenQuestion({
    this.id,
    required this.text,
    required this.kind,
    required this.required_,
  });

  /// Assigned by the server for new questions.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? id;

  PrescreenQuestionText text;

  PrescreenQuestionKindEnum kind;

  bool required_;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PrescreenQuestion &&
    other.id == id &&
    other.text == text &&
    other.kind == kind &&
    other.required_ == required_;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (text.hashCode) +
    (kind.hashCode) +
    (required_.hashCode);

  @override
  String toString() => 'PrescreenQuestion[id=$id, text=$text, kind=$kind, required_=$required_]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
      json[r'text'] = this.text;
      json[r'kind'] = this.kind;
      json[r'required'] = this.required_;
    return json;
  }

  /// Returns a new [PrescreenQuestion] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PrescreenQuestion? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PrescreenQuestion[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PrescreenQuestion[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PrescreenQuestion(
        id: mapValueOfType<String>(json, r'id'),
        text: PrescreenQuestionText.fromJson(json[r'text'])!,
        kind: PrescreenQuestionKindEnum.fromJson(json[r'kind'])!,
        required_: mapValueOfType<bool>(json, r'required')!,
      );
    }
    return null;
  }

  static List<PrescreenQuestion> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PrescreenQuestion>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PrescreenQuestion.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PrescreenQuestion> mapFromJson(dynamic json) {
    final map = <String, PrescreenQuestion>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PrescreenQuestion.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PrescreenQuestion-objects as value to a dart map
  static Map<String, List<PrescreenQuestion>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PrescreenQuestion>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PrescreenQuestion.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'text',
    'kind',
    'required',
  };
}


class PrescreenQuestionKindEnum {
  /// Instantiate a new enum with the provided [value].
  const PrescreenQuestionKindEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const text = PrescreenQuestionKindEnum._(r'text');
  static const yesNo = PrescreenQuestionKindEnum._(r'yes_no');
  static const number = PrescreenQuestionKindEnum._(r'number');

  /// List of all possible values in this [enum][PrescreenQuestionKindEnum].
  static const values = <PrescreenQuestionKindEnum>[
    text,
    yesNo,
    number,
  ];

  static PrescreenQuestionKindEnum? fromJson(dynamic value) => PrescreenQuestionKindEnumTypeTransformer().decode(value);

  static List<PrescreenQuestionKindEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PrescreenQuestionKindEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PrescreenQuestionKindEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [PrescreenQuestionKindEnum] to String,
/// and [decode] dynamic data back to [PrescreenQuestionKindEnum].
class PrescreenQuestionKindEnumTypeTransformer {
  factory PrescreenQuestionKindEnumTypeTransformer() => _instance ??= const PrescreenQuestionKindEnumTypeTransformer._();

  const PrescreenQuestionKindEnumTypeTransformer._();

  String encode(PrescreenQuestionKindEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a PrescreenQuestionKindEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  PrescreenQuestionKindEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'text': return PrescreenQuestionKindEnum.text;
        case r'yes_no': return PrescreenQuestionKindEnum.yesNo;
        case r'number': return PrescreenQuestionKindEnum.number;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [PrescreenQuestionKindEnumTypeTransformer] instance.
  static PrescreenQuestionKindEnumTypeTransformer? _instance;
}


