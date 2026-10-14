//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ChangeListingStatusRequest {
  /// Returns a new [ChangeListingStatusRequest] instance.
  ChangeListingStatusRequest({
    required this.status,
  });

  ChangeListingStatusRequestStatusEnum status;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ChangeListingStatusRequest &&
    other.status == status;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (status.hashCode);

  @override
  String toString() => 'ChangeListingStatusRequest[status=$status]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'status'] = this.status;
    return json;
  }

  /// Returns a new [ChangeListingStatusRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ChangeListingStatusRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ChangeListingStatusRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ChangeListingStatusRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ChangeListingStatusRequest(
        status: ChangeListingStatusRequestStatusEnum.fromJson(json[r'status'])!,
      );
    }
    return null;
  }

  static List<ChangeListingStatusRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ChangeListingStatusRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ChangeListingStatusRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ChangeListingStatusRequest> mapFromJson(dynamic json) {
    final map = <String, ChangeListingStatusRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ChangeListingStatusRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ChangeListingStatusRequest-objects as value to a dart map
  static Map<String, List<ChangeListingStatusRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ChangeListingStatusRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ChangeListingStatusRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'status',
  };
}


class ChangeListingStatusRequestStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const ChangeListingStatusRequestStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const published = ChangeListingStatusRequestStatusEnum._(r'published');
  static const paused = ChangeListingStatusRequestStatusEnum._(r'paused');
  static const rented = ChangeListingStatusRequestStatusEnum._(r'rented');
  static const archived = ChangeListingStatusRequestStatusEnum._(r'archived');

  /// List of all possible values in this [enum][ChangeListingStatusRequestStatusEnum].
  static const values = <ChangeListingStatusRequestStatusEnum>[
    published,
    paused,
    rented,
    archived,
  ];

  static ChangeListingStatusRequestStatusEnum? fromJson(dynamic value) => ChangeListingStatusRequestStatusEnumTypeTransformer().decode(value);

  static List<ChangeListingStatusRequestStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ChangeListingStatusRequestStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ChangeListingStatusRequestStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ChangeListingStatusRequestStatusEnum] to String,
/// and [decode] dynamic data back to [ChangeListingStatusRequestStatusEnum].
class ChangeListingStatusRequestStatusEnumTypeTransformer {
  factory ChangeListingStatusRequestStatusEnumTypeTransformer() => _instance ??= const ChangeListingStatusRequestStatusEnumTypeTransformer._();

  const ChangeListingStatusRequestStatusEnumTypeTransformer._();

  String encode(ChangeListingStatusRequestStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a ChangeListingStatusRequestStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ChangeListingStatusRequestStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'published': return ChangeListingStatusRequestStatusEnum.published;
        case r'paused': return ChangeListingStatusRequestStatusEnum.paused;
        case r'rented': return ChangeListingStatusRequestStatusEnum.rented;
        case r'archived': return ChangeListingStatusRequestStatusEnum.archived;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ChangeListingStatusRequestStatusEnumTypeTransformer] instance.
  static ChangeListingStatusRequestStatusEnumTypeTransformer? _instance;
}


