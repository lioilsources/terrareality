//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class InvitationPreview {
  /// Returns a new [InvitationPreview] instance.
  InvitationPreview({
    required this.orgName,
    required this.role,
    required this.email,
    required this.inviterName,
    required this.expiresAt,
    required this.status,
  });

  String orgName;

  Role role;

  String email;

  String inviterName;

  DateTime expiresAt;

  InvitationPreviewStatusEnum status;

  @override
  bool operator ==(Object other) => identical(this, other) || other is InvitationPreview &&
    other.orgName == orgName &&
    other.role == role &&
    other.email == email &&
    other.inviterName == inviterName &&
    other.expiresAt == expiresAt &&
    other.status == status;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (orgName.hashCode) +
    (role.hashCode) +
    (email.hashCode) +
    (inviterName.hashCode) +
    (expiresAt.hashCode) +
    (status.hashCode);

  @override
  String toString() => 'InvitationPreview[orgName=$orgName, role=$role, email=$email, inviterName=$inviterName, expiresAt=$expiresAt, status=$status]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'org_name'] = this.orgName;
      json[r'role'] = this.role;
      json[r'email'] = this.email;
      json[r'inviter_name'] = this.inviterName;
      json[r'expires_at'] = this.expiresAt.toUtc().toIso8601String();
      json[r'status'] = this.status;
    return json;
  }

  /// Returns a new [InvitationPreview] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static InvitationPreview? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "InvitationPreview[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "InvitationPreview[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return InvitationPreview(
        orgName: mapValueOfType<String>(json, r'org_name')!,
        role: Role.fromJson(json[r'role'])!,
        email: mapValueOfType<String>(json, r'email')!,
        inviterName: mapValueOfType<String>(json, r'inviter_name')!,
        expiresAt: mapDateTime(json, r'expires_at', r'')!,
        status: InvitationPreviewStatusEnum.fromJson(json[r'status'])!,
      );
    }
    return null;
  }

  static List<InvitationPreview> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <InvitationPreview>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = InvitationPreview.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, InvitationPreview> mapFromJson(dynamic json) {
    final map = <String, InvitationPreview>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = InvitationPreview.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of InvitationPreview-objects as value to a dart map
  static Map<String, List<InvitationPreview>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<InvitationPreview>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = InvitationPreview.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'org_name',
    'role',
    'email',
    'inviter_name',
    'expires_at',
    'status',
  };
}


class InvitationPreviewStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const InvitationPreviewStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const open = InvitationPreviewStatusEnum._(r'open');
  static const accepted = InvitationPreviewStatusEnum._(r'accepted');
  static const revoked = InvitationPreviewStatusEnum._(r'revoked');
  static const expired = InvitationPreviewStatusEnum._(r'expired');

  /// List of all possible values in this [enum][InvitationPreviewStatusEnum].
  static const values = <InvitationPreviewStatusEnum>[
    open,
    accepted,
    revoked,
    expired,
  ];

  static InvitationPreviewStatusEnum? fromJson(dynamic value) => InvitationPreviewStatusEnumTypeTransformer().decode(value);

  static List<InvitationPreviewStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <InvitationPreviewStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = InvitationPreviewStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [InvitationPreviewStatusEnum] to String,
/// and [decode] dynamic data back to [InvitationPreviewStatusEnum].
class InvitationPreviewStatusEnumTypeTransformer {
  factory InvitationPreviewStatusEnumTypeTransformer() => _instance ??= const InvitationPreviewStatusEnumTypeTransformer._();

  const InvitationPreviewStatusEnumTypeTransformer._();

  String encode(InvitationPreviewStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a InvitationPreviewStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  InvitationPreviewStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'open': return InvitationPreviewStatusEnum.open;
        case r'accepted': return InvitationPreviewStatusEnum.accepted;
        case r'revoked': return InvitationPreviewStatusEnum.revoked;
        case r'expired': return InvitationPreviewStatusEnum.expired;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [InvitationPreviewStatusEnumTypeTransformer] instance.
  static InvitationPreviewStatusEnumTypeTransformer? _instance;
}


