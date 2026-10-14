//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class RejectReason {
  /// Instantiate a new enum with the provided [value].
  const RejectReason._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const otherApplicantChosen = RejectReason._(r'other_applicant_chosen');
  static const incomeInsufficient = RejectReason._(r'income_insufficient');
  static const moveInMismatch = RejectReason._(r'move_in_mismatch');
  static const durationMismatch = RejectReason._(r'duration_mismatch');
  static const incomplete = RejectReason._(r'incomplete');
  static const listingWithdrawn = RejectReason._(r'listing_withdrawn');
  static const other = RejectReason._(r'other');

  /// List of all possible values in this [enum][RejectReason].
  static const values = <RejectReason>[
    otherApplicantChosen,
    incomeInsufficient,
    moveInMismatch,
    durationMismatch,
    incomplete,
    listingWithdrawn,
    other,
  ];

  static RejectReason? fromJson(dynamic value) => RejectReasonTypeTransformer().decode(value);

  static List<RejectReason> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RejectReason>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RejectReason.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [RejectReason] to String,
/// and [decode] dynamic data back to [RejectReason].
class RejectReasonTypeTransformer {
  factory RejectReasonTypeTransformer() => _instance ??= const RejectReasonTypeTransformer._();

  const RejectReasonTypeTransformer._();

  String encode(RejectReason data) => data.value;

  /// Decodes a [dynamic value][data] to a RejectReason.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  RejectReason? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'other_applicant_chosen': return RejectReason.otherApplicantChosen;
        case r'income_insufficient': return RejectReason.incomeInsufficient;
        case r'move_in_mismatch': return RejectReason.moveInMismatch;
        case r'duration_mismatch': return RejectReason.durationMismatch;
        case r'incomplete': return RejectReason.incomplete;
        case r'listing_withdrawn': return RejectReason.listingWithdrawn;
        case r'other': return RejectReason.other;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [RejectReasonTypeTransformer] instance.
  static RejectReasonTypeTransformer? _instance;
}

