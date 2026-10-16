//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

/// Statutory reasons of a landlord's notice (§ 2288 of the Czech Civil Code): odst. 1 a) gross_breach_tenant – the tenant grossly breaches their duties; b) conviction – the tenant was convicted of an intentional crime against the landlord, a member of their household, a person living in the house or property in the house; c) public_interest_vacate – the flat must be vacated because the flat or house is to be dealt with in the public interest so that it cannot be used at all; d) other_serious_reason – another similarly serious reason (explanation required); odst. 2 flat_needed_for_landlord_or_relative – leases for an indefinite term only: the flat is to be used by the landlord, their spouse (in the situations the law names) or a relative in the direct line or a sibling of the landlord or the spouse. 
class LandlordNoticeReason {
  /// Instantiate a new enum with the provided [value].
  const LandlordNoticeReason._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const grossBreachTenant = LandlordNoticeReason._(r'gross_breach_tenant');
  static const conviction = LandlordNoticeReason._(r'conviction');
  static const publicInterestVacate = LandlordNoticeReason._(r'public_interest_vacate');
  static const otherSeriousReason = LandlordNoticeReason._(r'other_serious_reason');
  static const flatNeededForLandlordOrRelative = LandlordNoticeReason._(r'flat_needed_for_landlord_or_relative');

  /// List of all possible values in this [enum][LandlordNoticeReason].
  static const values = <LandlordNoticeReason>[
    grossBreachTenant,
    conviction,
    publicInterestVacate,
    otherSeriousReason,
    flatNeededForLandlordOrRelative,
  ];

  static LandlordNoticeReason? fromJson(dynamic value) => LandlordNoticeReasonTypeTransformer().decode(value);

  static List<LandlordNoticeReason> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LandlordNoticeReason>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LandlordNoticeReason.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [LandlordNoticeReason] to String,
/// and [decode] dynamic data back to [LandlordNoticeReason].
class LandlordNoticeReasonTypeTransformer {
  factory LandlordNoticeReasonTypeTransformer() => _instance ??= const LandlordNoticeReasonTypeTransformer._();

  const LandlordNoticeReasonTypeTransformer._();

  String encode(LandlordNoticeReason data) => data.value;

  /// Decodes a [dynamic value][data] to a LandlordNoticeReason.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  LandlordNoticeReason? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'gross_breach_tenant': return LandlordNoticeReason.grossBreachTenant;
        case r'conviction': return LandlordNoticeReason.conviction;
        case r'public_interest_vacate': return LandlordNoticeReason.publicInterestVacate;
        case r'other_serious_reason': return LandlordNoticeReason.otherSeriousReason;
        case r'flat_needed_for_landlord_or_relative': return LandlordNoticeReason.flatNeededForLandlordOrRelative;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [LandlordNoticeReasonTypeTransformer] instance.
  static LandlordNoticeReasonTypeTransformer? _instance;
}

