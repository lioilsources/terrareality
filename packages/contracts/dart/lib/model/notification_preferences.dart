//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class NotificationPreferences {
  /// Returns a new [NotificationPreferences] instance.
  NotificationPreferences({
    required this.emailMessages,
    required this.pushMessages,
  });

  /// instant = one e-mail per unread conversation; daily = summary at 18:00.
  NotificationPreferencesEmailMessagesEnum emailMessages;

  bool pushMessages;

  @override
  bool operator ==(Object other) => identical(this, other) || other is NotificationPreferences &&
    other.emailMessages == emailMessages &&
    other.pushMessages == pushMessages;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (emailMessages.hashCode) +
    (pushMessages.hashCode);

  @override
  String toString() => 'NotificationPreferences[emailMessages=$emailMessages, pushMessages=$pushMessages]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'email_messages'] = this.emailMessages;
      json[r'push_messages'] = this.pushMessages;
    return json;
  }

  /// Returns a new [NotificationPreferences] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static NotificationPreferences? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "NotificationPreferences[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "NotificationPreferences[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return NotificationPreferences(
        emailMessages: NotificationPreferencesEmailMessagesEnum.fromJson(json[r'email_messages'])!,
        pushMessages: mapValueOfType<bool>(json, r'push_messages')!,
      );
    }
    return null;
  }

  static List<NotificationPreferences> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NotificationPreferences>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotificationPreferences.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, NotificationPreferences> mapFromJson(dynamic json) {
    final map = <String, NotificationPreferences>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = NotificationPreferences.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of NotificationPreferences-objects as value to a dart map
  static Map<String, List<NotificationPreferences>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<NotificationPreferences>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = NotificationPreferences.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'email_messages',
    'push_messages',
  };
}

/// instant = one e-mail per unread conversation; daily = summary at 18:00.
class NotificationPreferencesEmailMessagesEnum {
  /// Instantiate a new enum with the provided [value].
  const NotificationPreferencesEmailMessagesEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const instant = NotificationPreferencesEmailMessagesEnum._(r'instant');
  static const daily = NotificationPreferencesEmailMessagesEnum._(r'daily');
  static const off = NotificationPreferencesEmailMessagesEnum._(r'off');

  /// List of all possible values in this [enum][NotificationPreferencesEmailMessagesEnum].
  static const values = <NotificationPreferencesEmailMessagesEnum>[
    instant,
    daily,
    off,
  ];

  static NotificationPreferencesEmailMessagesEnum? fromJson(dynamic value) => NotificationPreferencesEmailMessagesEnumTypeTransformer().decode(value);

  static List<NotificationPreferencesEmailMessagesEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NotificationPreferencesEmailMessagesEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotificationPreferencesEmailMessagesEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [NotificationPreferencesEmailMessagesEnum] to String,
/// and [decode] dynamic data back to [NotificationPreferencesEmailMessagesEnum].
class NotificationPreferencesEmailMessagesEnumTypeTransformer {
  factory NotificationPreferencesEmailMessagesEnumTypeTransformer() => _instance ??= const NotificationPreferencesEmailMessagesEnumTypeTransformer._();

  const NotificationPreferencesEmailMessagesEnumTypeTransformer._();

  String encode(NotificationPreferencesEmailMessagesEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a NotificationPreferencesEmailMessagesEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  NotificationPreferencesEmailMessagesEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'instant': return NotificationPreferencesEmailMessagesEnum.instant;
        case r'daily': return NotificationPreferencesEmailMessagesEnum.daily;
        case r'off': return NotificationPreferencesEmailMessagesEnum.off;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [NotificationPreferencesEmailMessagesEnumTypeTransformer] instance.
  static NotificationPreferencesEmailMessagesEnumTypeTransformer? _instance;
}


