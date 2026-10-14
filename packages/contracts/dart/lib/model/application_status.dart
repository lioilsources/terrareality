//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class ApplicationStatus {
  /// Instantiate a new enum with the provided [value].
  const ApplicationStatus._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const pendingConsent = ApplicationStatus._(r'pending_consent');
  static const submitted = ApplicationStatus._(r'submitted');
  static const invited = ApplicationStatus._(r'invited');
  static const accepted = ApplicationStatus._(r'accepted');
  static const rejected = ApplicationStatus._(r'rejected');
  static const withdrawn = ApplicationStatus._(r'withdrawn');

  /// List of all possible values in this [enum][ApplicationStatus].
  static const values = <ApplicationStatus>[
    pendingConsent,
    submitted,
    invited,
    accepted,
    rejected,
    withdrawn,
  ];

  static ApplicationStatus? fromJson(dynamic value) => ApplicationStatusTypeTransformer().decode(value);

  static List<ApplicationStatus> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ApplicationStatus>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ApplicationStatus.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ApplicationStatus] to String,
/// and [decode] dynamic data back to [ApplicationStatus].
class ApplicationStatusTypeTransformer {
  factory ApplicationStatusTypeTransformer() => _instance ??= const ApplicationStatusTypeTransformer._();

  const ApplicationStatusTypeTransformer._();

  String encode(ApplicationStatus data) => data.value;

  /// Decodes a [dynamic value][data] to a ApplicationStatus.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ApplicationStatus? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'pending_consent': return ApplicationStatus.pendingConsent;
        case r'submitted': return ApplicationStatus.submitted;
        case r'invited': return ApplicationStatus.invited;
        case r'accepted': return ApplicationStatus.accepted;
        case r'rejected': return ApplicationStatus.rejected;
        case r'withdrawn': return ApplicationStatus.withdrawn;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ApplicationStatusTypeTransformer] instance.
  static ApplicationStatusTypeTransformer? _instance;
}

