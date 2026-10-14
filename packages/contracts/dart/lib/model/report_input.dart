//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ReportInput {
  /// Returns a new [ReportInput] instance.
  ReportInput({
    required this.reason,
    this.messageId,
    this.note,
  });

  ReportInputReasonEnum reason;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? messageId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? note;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ReportInput &&
    other.reason == reason &&
    other.messageId == messageId &&
    other.note == note;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (reason.hashCode) +
    (messageId == null ? 0 : messageId!.hashCode) +
    (note == null ? 0 : note!.hashCode);

  @override
  String toString() => 'ReportInput[reason=$reason, messageId=$messageId, note=$note]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'reason'] = this.reason;
    if (this.messageId != null) {
      json[r'message_id'] = this.messageId;
    } else {
      json[r'message_id'] = null;
    }
    if (this.note != null) {
      json[r'note'] = this.note;
    } else {
      json[r'note'] = null;
    }
    return json;
  }

  /// Returns a new [ReportInput] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ReportInput? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ReportInput[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ReportInput[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ReportInput(
        reason: ReportInputReasonEnum.fromJson(json[r'reason'])!,
        messageId: mapValueOfType<String>(json, r'message_id'),
        note: mapValueOfType<String>(json, r'note'),
      );
    }
    return null;
  }

  static List<ReportInput> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ReportInput>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ReportInput.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ReportInput> mapFromJson(dynamic json) {
    final map = <String, ReportInput>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ReportInput.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ReportInput-objects as value to a dart map
  static Map<String, List<ReportInput>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ReportInput>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ReportInput.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'reason',
  };
}


class ReportInputReasonEnum {
  /// Instantiate a new enum with the provided [value].
  const ReportInputReasonEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const scam = ReportInputReasonEnum._(r'scam');
  static const advancePayment = ReportInputReasonEnum._(r'advance_payment');
  static const harassment = ReportInputReasonEnum._(r'harassment');
  static const discrimination = ReportInputReasonEnum._(r'discrimination');
  static const spam = ReportInputReasonEnum._(r'spam');
  static const other = ReportInputReasonEnum._(r'other');

  /// List of all possible values in this [enum][ReportInputReasonEnum].
  static const values = <ReportInputReasonEnum>[
    scam,
    advancePayment,
    harassment,
    discrimination,
    spam,
    other,
  ];

  static ReportInputReasonEnum? fromJson(dynamic value) => ReportInputReasonEnumTypeTransformer().decode(value);

  static List<ReportInputReasonEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ReportInputReasonEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ReportInputReasonEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ReportInputReasonEnum] to String,
/// and [decode] dynamic data back to [ReportInputReasonEnum].
class ReportInputReasonEnumTypeTransformer {
  factory ReportInputReasonEnumTypeTransformer() => _instance ??= const ReportInputReasonEnumTypeTransformer._();

  const ReportInputReasonEnumTypeTransformer._();

  String encode(ReportInputReasonEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a ReportInputReasonEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ReportInputReasonEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'scam': return ReportInputReasonEnum.scam;
        case r'advance_payment': return ReportInputReasonEnum.advancePayment;
        case r'harassment': return ReportInputReasonEnum.harassment;
        case r'discrimination': return ReportInputReasonEnum.discrimination;
        case r'spam': return ReportInputReasonEnum.spam;
        case r'other': return ReportInputReasonEnum.other;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ReportInputReasonEnumTypeTransformer] instance.
  static ReportInputReasonEnumTypeTransformer? _instance;
}


