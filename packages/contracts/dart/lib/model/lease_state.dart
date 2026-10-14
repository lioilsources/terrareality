//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class LeaseState {
  /// Instantiate a new enum with the provided [value].
  const LeaseState._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const draft = LeaseState._(r'draft');
  static const proposed = LeaseState._(r'proposed');
  static const negotiating = LeaseState._(r'negotiating');
  static const signed = LeaseState._(r'signed');
  static const active = LeaseState._(r'active');
  static const noticeGiven = LeaseState._(r'notice_given');
  static const terminated = LeaseState._(r'terminated');
  static const settled = LeaseState._(r'settled');
  static const cancelled = LeaseState._(r'cancelled');

  /// List of all possible values in this [enum][LeaseState].
  static const values = <LeaseState>[
    draft,
    proposed,
    negotiating,
    signed,
    active,
    noticeGiven,
    terminated,
    settled,
    cancelled,
  ];

  static LeaseState? fromJson(dynamic value) => LeaseStateTypeTransformer().decode(value);

  static List<LeaseState> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LeaseState>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LeaseState.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [LeaseState] to String,
/// and [decode] dynamic data back to [LeaseState].
class LeaseStateTypeTransformer {
  factory LeaseStateTypeTransformer() => _instance ??= const LeaseStateTypeTransformer._();

  const LeaseStateTypeTransformer._();

  String encode(LeaseState data) => data.value;

  /// Decodes a [dynamic value][data] to a LeaseState.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  LeaseState? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'draft': return LeaseState.draft;
        case r'proposed': return LeaseState.proposed;
        case r'negotiating': return LeaseState.negotiating;
        case r'signed': return LeaseState.signed;
        case r'active': return LeaseState.active;
        case r'notice_given': return LeaseState.noticeGiven;
        case r'terminated': return LeaseState.terminated;
        case r'settled': return LeaseState.settled;
        case r'cancelled': return LeaseState.cancelled;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [LeaseStateTypeTransformer] instance.
  static LeaseStateTypeTransformer? _instance;
}

