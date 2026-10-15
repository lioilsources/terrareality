//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PaymentLink {
  /// Returns a new [PaymentLink] instance.
  PaymentLink({
    required this.id,
    required this.shareId,
    required this.provider,
    required this.url,
    required this.amount,
    required this.currency,
    required this.status,
    this.expiresAt,
    required this.createdAt,
  });

  String id;

  String shareId;

  PaymentLinkProviderEnum provider;

  String url;

  int amount;

  String currency;

  PaymentLinkStatusEnum status;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? expiresAt;

  DateTime createdAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PaymentLink &&
    other.id == id &&
    other.shareId == shareId &&
    other.provider == provider &&
    other.url == url &&
    other.amount == amount &&
    other.currency == currency &&
    other.status == status &&
    other.expiresAt == expiresAt &&
    other.createdAt == createdAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (shareId.hashCode) +
    (provider.hashCode) +
    (url.hashCode) +
    (amount.hashCode) +
    (currency.hashCode) +
    (status.hashCode) +
    (expiresAt == null ? 0 : expiresAt!.hashCode) +
    (createdAt.hashCode);

  @override
  String toString() => 'PaymentLink[id=$id, shareId=$shareId, provider=$provider, url=$url, amount=$amount, currency=$currency, status=$status, expiresAt=$expiresAt, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'share_id'] = this.shareId;
      json[r'provider'] = this.provider;
      json[r'url'] = this.url;
      json[r'amount'] = this.amount;
      json[r'currency'] = this.currency;
      json[r'status'] = this.status;
    if (this.expiresAt != null) {
      json[r'expires_at'] = this.expiresAt!.toUtc().toIso8601String();
    } else {
      json[r'expires_at'] = null;
    }
      json[r'created_at'] = this.createdAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [PaymentLink] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PaymentLink? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PaymentLink[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PaymentLink[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PaymentLink(
        id: mapValueOfType<String>(json, r'id')!,
        shareId: mapValueOfType<String>(json, r'share_id')!,
        provider: PaymentLinkProviderEnum.fromJson(json[r'provider'])!,
        url: mapValueOfType<String>(json, r'url')!,
        amount: mapValueOfType<int>(json, r'amount')!,
        currency: mapValueOfType<String>(json, r'currency')!,
        status: PaymentLinkStatusEnum.fromJson(json[r'status'])!,
        expiresAt: mapDateTime(json, r'expires_at', r''),
        createdAt: mapDateTime(json, r'created_at', r'')!,
      );
    }
    return null;
  }

  static List<PaymentLink> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PaymentLink>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PaymentLink.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PaymentLink> mapFromJson(dynamic json) {
    final map = <String, PaymentLink>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PaymentLink.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PaymentLink-objects as value to a dart map
  static Map<String, List<PaymentLink>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PaymentLink>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PaymentLink.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'share_id',
    'provider',
    'url',
    'amount',
    'currency',
    'status',
    'created_at',
  };
}


class PaymentLinkProviderEnum {
  /// Instantiate a new enum with the provided [value].
  const PaymentLinkProviderEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const revolut = PaymentLinkProviderEnum._(r'revolut');

  /// List of all possible values in this [enum][PaymentLinkProviderEnum].
  static const values = <PaymentLinkProviderEnum>[
    revolut,
  ];

  static PaymentLinkProviderEnum? fromJson(dynamic value) => PaymentLinkProviderEnumTypeTransformer().decode(value);

  static List<PaymentLinkProviderEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PaymentLinkProviderEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PaymentLinkProviderEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [PaymentLinkProviderEnum] to String,
/// and [decode] dynamic data back to [PaymentLinkProviderEnum].
class PaymentLinkProviderEnumTypeTransformer {
  factory PaymentLinkProviderEnumTypeTransformer() => _instance ??= const PaymentLinkProviderEnumTypeTransformer._();

  const PaymentLinkProviderEnumTypeTransformer._();

  String encode(PaymentLinkProviderEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a PaymentLinkProviderEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  PaymentLinkProviderEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'revolut': return PaymentLinkProviderEnum.revolut;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [PaymentLinkProviderEnumTypeTransformer] instance.
  static PaymentLinkProviderEnumTypeTransformer? _instance;
}



class PaymentLinkStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const PaymentLinkStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const created = PaymentLinkStatusEnum._(r'created');
  static const paid = PaymentLinkStatusEnum._(r'paid');
  static const expired = PaymentLinkStatusEnum._(r'expired');

  /// List of all possible values in this [enum][PaymentLinkStatusEnum].
  static const values = <PaymentLinkStatusEnum>[
    created,
    paid,
    expired,
  ];

  static PaymentLinkStatusEnum? fromJson(dynamic value) => PaymentLinkStatusEnumTypeTransformer().decode(value);

  static List<PaymentLinkStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PaymentLinkStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PaymentLinkStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [PaymentLinkStatusEnum] to String,
/// and [decode] dynamic data back to [PaymentLinkStatusEnum].
class PaymentLinkStatusEnumTypeTransformer {
  factory PaymentLinkStatusEnumTypeTransformer() => _instance ??= const PaymentLinkStatusEnumTypeTransformer._();

  const PaymentLinkStatusEnumTypeTransformer._();

  String encode(PaymentLinkStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a PaymentLinkStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  PaymentLinkStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'created': return PaymentLinkStatusEnum.created;
        case r'paid': return PaymentLinkStatusEnum.paid;
        case r'expired': return PaymentLinkStatusEnum.expired;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [PaymentLinkStatusEnumTypeTransformer] instance.
  static PaymentLinkStatusEnumTypeTransformer? _instance;
}


