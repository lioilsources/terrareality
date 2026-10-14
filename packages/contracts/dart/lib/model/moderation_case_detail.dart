//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ModerationCaseDetail {
  /// Returns a new [ModerationCaseDetail] instance.
  ModerationCaseDetail({
    required this.case_,
    this.transcript = const [],
  });

  ModerationCase case_;

  List<TranscriptMessage> transcript;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ModerationCaseDetail &&
    other.case_ == case_ &&
    _deepEquality.equals(other.transcript, transcript);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (case_.hashCode) +
    (transcript.hashCode);

  @override
  String toString() => 'ModerationCaseDetail[case_=$case_, transcript=$transcript]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'case'] = this.case_;
      json[r'transcript'] = this.transcript;
    return json;
  }

  /// Returns a new [ModerationCaseDetail] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ModerationCaseDetail? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ModerationCaseDetail[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ModerationCaseDetail[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ModerationCaseDetail(
        case_: ModerationCase.fromJson(json[r'case'])!,
        transcript: TranscriptMessage.listFromJson(json[r'transcript']),
      );
    }
    return null;
  }

  static List<ModerationCaseDetail> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ModerationCaseDetail>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ModerationCaseDetail.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ModerationCaseDetail> mapFromJson(dynamic json) {
    final map = <String, ModerationCaseDetail>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ModerationCaseDetail.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ModerationCaseDetail-objects as value to a dart map
  static Map<String, List<ModerationCaseDetail>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ModerationCaseDetail>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ModerationCaseDetail.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'case',
    'transcript',
  };
}

