//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class ListingReportReason {
  /// Instantiate a new enum with the provided [value].
  const ListingReportReason._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const illegalContent = ListingReportReason._(r'illegal_content');
  static const fraud = ListingReportReason._(r'fraud');
  static const discrimination = ListingReportReason._(r'discrimination');
  static const wrongInfo = ListingReportReason._(r'wrong_info');
  static const other = ListingReportReason._(r'other');

  /// List of all possible values in this [enum][ListingReportReason].
  static const values = <ListingReportReason>[
    illegalContent,
    fraud,
    discrimination,
    wrongInfo,
    other,
  ];

  static ListingReportReason? fromJson(dynamic value) => ListingReportReasonTypeTransformer().decode(value);

  static List<ListingReportReason> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ListingReportReason>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ListingReportReason.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ListingReportReason] to String,
/// and [decode] dynamic data back to [ListingReportReason].
class ListingReportReasonTypeTransformer {
  factory ListingReportReasonTypeTransformer() => _instance ??= const ListingReportReasonTypeTransformer._();

  const ListingReportReasonTypeTransformer._();

  String encode(ListingReportReason data) => data.value;

  /// Decodes a [dynamic value][data] to a ListingReportReason.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ListingReportReason? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'illegal_content': return ListingReportReason.illegalContent;
        case r'fraud': return ListingReportReason.fraud;
        case r'discrimination': return ListingReportReason.discrimination;
        case r'wrong_info': return ListingReportReason.wrongInfo;
        case r'other': return ListingReportReason.other;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ListingReportReasonTypeTransformer] instance.
  static ListingReportReasonTypeTransformer? _instance;
}

