//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Promotion {
  /// Returns a new [Promotion] instance.
  Promotion({
    required this.id,
    required this.listingId,
    required this.kind,
    required this.startsAt,
    required this.endsAt,
    required this.orderId,
    required this.active,
  });

  String id;

  String listingId;

  PromotionKindEnum kind;

  DateTime startsAt;

  DateTime endsAt;

  String orderId;

  /// Running right now.
  bool active;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Promotion &&
    other.id == id &&
    other.listingId == listingId &&
    other.kind == kind &&
    other.startsAt == startsAt &&
    other.endsAt == endsAt &&
    other.orderId == orderId &&
    other.active == active;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (listingId.hashCode) +
    (kind.hashCode) +
    (startsAt.hashCode) +
    (endsAt.hashCode) +
    (orderId.hashCode) +
    (active.hashCode);

  @override
  String toString() => 'Promotion[id=$id, listingId=$listingId, kind=$kind, startsAt=$startsAt, endsAt=$endsAt, orderId=$orderId, active=$active]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'listing_id'] = this.listingId;
      json[r'kind'] = this.kind;
      json[r'starts_at'] = this.startsAt.toUtc().toIso8601String();
      json[r'ends_at'] = this.endsAt.toUtc().toIso8601String();
      json[r'order_id'] = this.orderId;
      json[r'active'] = this.active;
    return json;
  }

  /// Returns a new [Promotion] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Promotion? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "Promotion[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "Promotion[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Promotion(
        id: mapValueOfType<String>(json, r'id')!,
        listingId: mapValueOfType<String>(json, r'listing_id')!,
        kind: PromotionKindEnum.fromJson(json[r'kind'])!,
        startsAt: mapDateTime(json, r'starts_at', r'')!,
        endsAt: mapDateTime(json, r'ends_at', r'')!,
        orderId: mapValueOfType<String>(json, r'order_id')!,
        active: mapValueOfType<bool>(json, r'active')!,
      );
    }
    return null;
  }

  static List<Promotion> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Promotion>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Promotion.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Promotion> mapFromJson(dynamic json) {
    final map = <String, Promotion>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Promotion.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Promotion-objects as value to a dart map
  static Map<String, List<Promotion>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Promotion>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Promotion.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'listing_id',
    'kind',
    'starts_at',
    'ends_at',
    'order_id',
    'active',
  };
}


class PromotionKindEnum {
  /// Instantiate a new enum with the provided [value].
  const PromotionKindEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const top = PromotionKindEnum._(r'top');
  static const highlight = PromotionKindEnum._(r'highlight');

  /// List of all possible values in this [enum][PromotionKindEnum].
  static const values = <PromotionKindEnum>[
    top,
    highlight,
  ];

  static PromotionKindEnum? fromJson(dynamic value) => PromotionKindEnumTypeTransformer().decode(value);

  static List<PromotionKindEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PromotionKindEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PromotionKindEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [PromotionKindEnum] to String,
/// and [decode] dynamic data back to [PromotionKindEnum].
class PromotionKindEnumTypeTransformer {
  factory PromotionKindEnumTypeTransformer() => _instance ??= const PromotionKindEnumTypeTransformer._();

  const PromotionKindEnumTypeTransformer._();

  String encode(PromotionKindEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a PromotionKindEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  PromotionKindEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'top': return PromotionKindEnum.top;
        case r'highlight': return PromotionKindEnum.highlight;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [PromotionKindEnumTypeTransformer] instance.
  static PromotionKindEnumTypeTransformer? _instance;
}


