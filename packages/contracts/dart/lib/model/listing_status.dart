//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class ListingStatus {
  /// Instantiate a new enum with the provided [value].
  const ListingStatus._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const draft = ListingStatus._(r'draft');
  static const review = ListingStatus._(r'review');
  static const published = ListingStatus._(r'published');
  static const paused = ListingStatus._(r'paused');
  static const rented = ListingStatus._(r'rented');
  static const archived = ListingStatus._(r'archived');

  /// List of all possible values in this [enum][ListingStatus].
  static const values = <ListingStatus>[
    draft,
    review,
    published,
    paused,
    rented,
    archived,
  ];

  static ListingStatus? fromJson(dynamic value) => ListingStatusTypeTransformer().decode(value);

  static List<ListingStatus> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ListingStatus>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ListingStatus.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ListingStatus] to String,
/// and [decode] dynamic data back to [ListingStatus].
class ListingStatusTypeTransformer {
  factory ListingStatusTypeTransformer() => _instance ??= const ListingStatusTypeTransformer._();

  const ListingStatusTypeTransformer._();

  String encode(ListingStatus data) => data.value;

  /// Decodes a [dynamic value][data] to a ListingStatus.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ListingStatus? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'draft': return ListingStatus.draft;
        case r'review': return ListingStatus.review;
        case r'published': return ListingStatus.published;
        case r'paused': return ListingStatus.paused;
        case r'rented': return ListingStatus.rented;
        case r'archived': return ListingStatus.archived;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ListingStatusTypeTransformer] instance.
  static ListingStatusTypeTransformer? _instance;
}

