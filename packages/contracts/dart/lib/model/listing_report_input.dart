//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ListingReportInput {
  /// Returns a new [ListingReportInput] instance.
  ListingReportInput({
    required this.reason,
    required this.explanation,
    this.email,
    this.name,
    this.locale,
  });

  ListingReportReason reason;

  /// Why the reporter considers the listing illegal or in breach of the terms (DSA art. 16(2)(a)).
  String explanation;

  /// Required for anonymous reporters; ignored when signed in (the account e-mail is used).
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? email;

  /// Optional reporter name (anonymous reporters).
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? name;

  /// Language of the e-mails for anonymous reporters.
  ListingReportInputLocaleEnum? locale;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ListingReportInput &&
    other.reason == reason &&
    other.explanation == explanation &&
    other.email == email &&
    other.name == name &&
    other.locale == locale;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (reason.hashCode) +
    (explanation.hashCode) +
    (email == null ? 0 : email!.hashCode) +
    (name == null ? 0 : name!.hashCode) +
    (locale == null ? 0 : locale!.hashCode);

  @override
  String toString() => 'ListingReportInput[reason=$reason, explanation=$explanation, email=$email, name=$name, locale=$locale]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'reason'] = this.reason;
      json[r'explanation'] = this.explanation;
    if (this.email != null) {
      json[r'email'] = this.email;
    } else {
      json[r'email'] = null;
    }
    if (this.name != null) {
      json[r'name'] = this.name;
    } else {
      json[r'name'] = null;
    }
    if (this.locale != null) {
      json[r'locale'] = this.locale;
    } else {
      json[r'locale'] = null;
    }
    return json;
  }

  /// Returns a new [ListingReportInput] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ListingReportInput? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ListingReportInput[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ListingReportInput[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ListingReportInput(
        reason: ListingReportReason.fromJson(json[r'reason'])!,
        explanation: mapValueOfType<String>(json, r'explanation')!,
        email: mapValueOfType<String>(json, r'email'),
        name: mapValueOfType<String>(json, r'name'),
        locale: ListingReportInputLocaleEnum.fromJson(json[r'locale']),
      );
    }
    return null;
  }

  static List<ListingReportInput> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ListingReportInput>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ListingReportInput.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ListingReportInput> mapFromJson(dynamic json) {
    final map = <String, ListingReportInput>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ListingReportInput.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ListingReportInput-objects as value to a dart map
  static Map<String, List<ListingReportInput>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ListingReportInput>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ListingReportInput.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'reason',
    'explanation',
  };
}

/// Language of the e-mails for anonymous reporters.
class ListingReportInputLocaleEnum {
  /// Instantiate a new enum with the provided [value].
  const ListingReportInputLocaleEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const cs = ListingReportInputLocaleEnum._(r'cs');
  static const en = ListingReportInputLocaleEnum._(r'en');

  /// List of all possible values in this [enum][ListingReportInputLocaleEnum].
  static const values = <ListingReportInputLocaleEnum>[
    cs,
    en,
  ];

  static ListingReportInputLocaleEnum? fromJson(dynamic value) => ListingReportInputLocaleEnumTypeTransformer().decode(value);

  static List<ListingReportInputLocaleEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ListingReportInputLocaleEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ListingReportInputLocaleEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ListingReportInputLocaleEnum] to String,
/// and [decode] dynamic data back to [ListingReportInputLocaleEnum].
class ListingReportInputLocaleEnumTypeTransformer {
  factory ListingReportInputLocaleEnumTypeTransformer() => _instance ??= const ListingReportInputLocaleEnumTypeTransformer._();

  const ListingReportInputLocaleEnumTypeTransformer._();

  String encode(ListingReportInputLocaleEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a ListingReportInputLocaleEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ListingReportInputLocaleEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'cs': return ListingReportInputLocaleEnum.cs;
        case r'en': return ListingReportInputLocaleEnum.en;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ListingReportInputLocaleEnumTypeTransformer] instance.
  static ListingReportInputLocaleEnumTypeTransformer? _instance;
}


