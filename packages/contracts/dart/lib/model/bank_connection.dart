//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class BankConnection {
  /// Returns a new [BankConnection] instance.
  BankConnection({
    required this.id,
    required this.provider,
    required this.status,
    required this.iban,
    this.lastSyncedAt,
    required this.createdAt,
  });

  String id;

  BankConnectionProviderEnum provider;

  BankConnectionStatusEnum status;

  String iban;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? lastSyncedAt;

  DateTime createdAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is BankConnection &&
    other.id == id &&
    other.provider == provider &&
    other.status == status &&
    other.iban == iban &&
    other.lastSyncedAt == lastSyncedAt &&
    other.createdAt == createdAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (provider.hashCode) +
    (status.hashCode) +
    (iban.hashCode) +
    (lastSyncedAt == null ? 0 : lastSyncedAt!.hashCode) +
    (createdAt.hashCode);

  @override
  String toString() => 'BankConnection[id=$id, provider=$provider, status=$status, iban=$iban, lastSyncedAt=$lastSyncedAt, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'provider'] = this.provider;
      json[r'status'] = this.status;
      json[r'iban'] = this.iban;
    if (this.lastSyncedAt != null) {
      json[r'last_synced_at'] = this.lastSyncedAt!.toUtc().toIso8601String();
    } else {
      json[r'last_synced_at'] = null;
    }
      json[r'created_at'] = this.createdAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [BankConnection] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static BankConnection? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "BankConnection[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "BankConnection[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return BankConnection(
        id: mapValueOfType<String>(json, r'id')!,
        provider: BankConnectionProviderEnum.fromJson(json[r'provider'])!,
        status: BankConnectionStatusEnum.fromJson(json[r'status'])!,
        iban: mapValueOfType<String>(json, r'iban')!,
        lastSyncedAt: mapDateTime(json, r'last_synced_at', r''),
        createdAt: mapDateTime(json, r'created_at', r'')!,
      );
    }
    return null;
  }

  static List<BankConnection> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <BankConnection>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = BankConnection.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, BankConnection> mapFromJson(dynamic json) {
    final map = <String, BankConnection>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = BankConnection.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of BankConnection-objects as value to a dart map
  static Map<String, List<BankConnection>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<BankConnection>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = BankConnection.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'provider',
    'status',
    'iban',
    'created_at',
  };
}


class BankConnectionProviderEnum {
  /// Instantiate a new enum with the provided [value].
  const BankConnectionProviderEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const gocardless = BankConnectionProviderEnum._(r'gocardless');
  static const mock = BankConnectionProviderEnum._(r'mock');

  /// List of all possible values in this [enum][BankConnectionProviderEnum].
  static const values = <BankConnectionProviderEnum>[
    gocardless,
    mock,
  ];

  static BankConnectionProviderEnum? fromJson(dynamic value) => BankConnectionProviderEnumTypeTransformer().decode(value);

  static List<BankConnectionProviderEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <BankConnectionProviderEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = BankConnectionProviderEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [BankConnectionProviderEnum] to String,
/// and [decode] dynamic data back to [BankConnectionProviderEnum].
class BankConnectionProviderEnumTypeTransformer {
  factory BankConnectionProviderEnumTypeTransformer() => _instance ??= const BankConnectionProviderEnumTypeTransformer._();

  const BankConnectionProviderEnumTypeTransformer._();

  String encode(BankConnectionProviderEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a BankConnectionProviderEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  BankConnectionProviderEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'gocardless': return BankConnectionProviderEnum.gocardless;
        case r'mock': return BankConnectionProviderEnum.mock;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [BankConnectionProviderEnumTypeTransformer] instance.
  static BankConnectionProviderEnumTypeTransformer? _instance;
}



class BankConnectionStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const BankConnectionStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const pending = BankConnectionStatusEnum._(r'pending');
  static const linked = BankConnectionStatusEnum._(r'linked');
  static const expired = BankConnectionStatusEnum._(r'expired');
  static const error = BankConnectionStatusEnum._(r'error');

  /// List of all possible values in this [enum][BankConnectionStatusEnum].
  static const values = <BankConnectionStatusEnum>[
    pending,
    linked,
    expired,
    error,
  ];

  static BankConnectionStatusEnum? fromJson(dynamic value) => BankConnectionStatusEnumTypeTransformer().decode(value);

  static List<BankConnectionStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <BankConnectionStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = BankConnectionStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [BankConnectionStatusEnum] to String,
/// and [decode] dynamic data back to [BankConnectionStatusEnum].
class BankConnectionStatusEnumTypeTransformer {
  factory BankConnectionStatusEnumTypeTransformer() => _instance ??= const BankConnectionStatusEnumTypeTransformer._();

  const BankConnectionStatusEnumTypeTransformer._();

  String encode(BankConnectionStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a BankConnectionStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  BankConnectionStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'pending': return BankConnectionStatusEnum.pending;
        case r'linked': return BankConnectionStatusEnum.linked;
        case r'expired': return BankConnectionStatusEnum.expired;
        case r'error': return BankConnectionStatusEnum.error;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [BankConnectionStatusEnumTypeTransformer] instance.
  static BankConnectionStatusEnumTypeTransformer? _instance;
}


