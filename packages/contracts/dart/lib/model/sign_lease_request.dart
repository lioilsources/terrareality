//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class SignLeaseRequest {
  /// Returns a new [SignLeaseRequest] instance.
  SignLeaseRequest({
    required this.provider,
  });

  SignLeaseRequestProviderEnum provider;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SignLeaseRequest &&
    other.provider == provider;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (provider.hashCode);

  @override
  String toString() => 'SignLeaseRequest[provider=$provider]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'provider'] = this.provider;
    return json;
  }

  /// Returns a new [SignLeaseRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SignLeaseRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "SignLeaseRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "SignLeaseRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return SignLeaseRequest(
        provider: SignLeaseRequestProviderEnum.fromJson(json[r'provider'])!,
      );
    }
    return null;
  }

  static List<SignLeaseRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SignLeaseRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SignLeaseRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SignLeaseRequest> mapFromJson(dynamic json) {
    final map = <String, SignLeaseRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SignLeaseRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SignLeaseRequest-objects as value to a dart map
  static Map<String, List<SignLeaseRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SignLeaseRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SignLeaseRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'provider',
  };
}


class SignLeaseRequestProviderEnum {
  /// Instantiate a new enum with the provided [value].
  const SignLeaseRequestProviderEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const mock = SignLeaseRequestProviderEnum._(r'mock');
  static const bankidSign = SignLeaseRequestProviderEnum._(r'bankid_sign');

  /// List of all possible values in this [enum][SignLeaseRequestProviderEnum].
  static const values = <SignLeaseRequestProviderEnum>[
    mock,
    bankidSign,
  ];

  static SignLeaseRequestProviderEnum? fromJson(dynamic value) => SignLeaseRequestProviderEnumTypeTransformer().decode(value);

  static List<SignLeaseRequestProviderEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SignLeaseRequestProviderEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SignLeaseRequestProviderEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [SignLeaseRequestProviderEnum] to String,
/// and [decode] dynamic data back to [SignLeaseRequestProviderEnum].
class SignLeaseRequestProviderEnumTypeTransformer {
  factory SignLeaseRequestProviderEnumTypeTransformer() => _instance ??= const SignLeaseRequestProviderEnumTypeTransformer._();

  const SignLeaseRequestProviderEnumTypeTransformer._();

  String encode(SignLeaseRequestProviderEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a SignLeaseRequestProviderEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  SignLeaseRequestProviderEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'mock': return SignLeaseRequestProviderEnum.mock;
        case r'bankid_sign': return SignLeaseRequestProviderEnum.bankidSign;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [SignLeaseRequestProviderEnumTypeTransformer] instance.
  static SignLeaseRequestProviderEnumTypeTransformer? _instance;
}


