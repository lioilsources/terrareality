//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class LeaseTemplate {
  /// Instantiate a new enum with the provided [value].
  const LeaseTemplate._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const bytDobaUrcita = LeaseTemplate._(r'byt_doba_urcita');
  static const bytDobaNeurcita = LeaseTemplate._(r'byt_doba_neurcita');
  static const spolecnyNajem = LeaseTemplate._(r'spolecny_najem');
  static const pokoj = LeaseTemplate._(r'pokoj');

  /// List of all possible values in this [enum][LeaseTemplate].
  static const values = <LeaseTemplate>[
    bytDobaUrcita,
    bytDobaNeurcita,
    spolecnyNajem,
    pokoj,
  ];

  static LeaseTemplate? fromJson(dynamic value) => LeaseTemplateTypeTransformer().decode(value);

  static List<LeaseTemplate> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LeaseTemplate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LeaseTemplate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [LeaseTemplate] to String,
/// and [decode] dynamic data back to [LeaseTemplate].
class LeaseTemplateTypeTransformer {
  factory LeaseTemplateTypeTransformer() => _instance ??= const LeaseTemplateTypeTransformer._();

  const LeaseTemplateTypeTransformer._();

  String encode(LeaseTemplate data) => data.value;

  /// Decodes a [dynamic value][data] to a LeaseTemplate.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  LeaseTemplate? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'byt_doba_urcita': return LeaseTemplate.bytDobaUrcita;
        case r'byt_doba_neurcita': return LeaseTemplate.bytDobaNeurcita;
        case r'spolecny_najem': return LeaseTemplate.spolecnyNajem;
        case r'pokoj': return LeaseTemplate.pokoj;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [LeaseTemplateTypeTransformer] instance.
  static LeaseTemplateTypeTransformer? _instance;
}

