//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ModerationCase {
  /// Returns a new [ModerationCase] instance.
  ModerationCase({
    required this.id,
    required this.kind,
    required this.source_,
    this.conversationId,
    this.listingId,
    this.messageId,
    required this.reason,
    this.note,
    required this.status,
    this.reporterName,
    this.reporterEmail,
    this.reporterAnonymous,
    this.reportedId,
    this.reportedName,
    this.reportedEmail,
    required this.listingTitle,
    required this.messageBody,
    required this.aiStatus,
    this.aiSuggestion,
    this.decision,
    this.decisionNote,
    required this.createdAt,
  });

  String id;

  /// What was reported.
  ModerationCaseKindEnum kind;

  ModerationCaseSource_Enum source_;

  /// Set for conversation cases.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? conversationId;

  /// The reported listing (listing cases) or the conversation's listing.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? listingId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? messageId;

  String reason;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? note;

  ModerationCaseStatusEnum status;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? reporterName;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? reporterEmail;

  /// The reporter was not signed in (listing reports).
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? reporterAnonymous;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? reportedId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? reportedName;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? reportedEmail;

  I18nText listingTitle;

  String messageBody;

  ModerationCaseAiStatusEnum aiStatus;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  ModerationSuggestion? aiSuggestion;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  ModerationVerdict? decision;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? decisionNote;

  DateTime createdAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ModerationCase &&
    other.id == id &&
    other.kind == kind &&
    other.source_ == source_ &&
    other.conversationId == conversationId &&
    other.listingId == listingId &&
    other.messageId == messageId &&
    other.reason == reason &&
    other.note == note &&
    other.status == status &&
    other.reporterName == reporterName &&
    other.reporterEmail == reporterEmail &&
    other.reporterAnonymous == reporterAnonymous &&
    other.reportedId == reportedId &&
    other.reportedName == reportedName &&
    other.reportedEmail == reportedEmail &&
    other.listingTitle == listingTitle &&
    other.messageBody == messageBody &&
    other.aiStatus == aiStatus &&
    other.aiSuggestion == aiSuggestion &&
    other.decision == decision &&
    other.decisionNote == decisionNote &&
    other.createdAt == createdAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (kind.hashCode) +
    (source_.hashCode) +
    (conversationId == null ? 0 : conversationId!.hashCode) +
    (listingId == null ? 0 : listingId!.hashCode) +
    (messageId == null ? 0 : messageId!.hashCode) +
    (reason.hashCode) +
    (note == null ? 0 : note!.hashCode) +
    (status.hashCode) +
    (reporterName == null ? 0 : reporterName!.hashCode) +
    (reporterEmail == null ? 0 : reporterEmail!.hashCode) +
    (reporterAnonymous == null ? 0 : reporterAnonymous!.hashCode) +
    (reportedId == null ? 0 : reportedId!.hashCode) +
    (reportedName == null ? 0 : reportedName!.hashCode) +
    (reportedEmail == null ? 0 : reportedEmail!.hashCode) +
    (listingTitle.hashCode) +
    (messageBody.hashCode) +
    (aiStatus.hashCode) +
    (aiSuggestion == null ? 0 : aiSuggestion!.hashCode) +
    (decision == null ? 0 : decision!.hashCode) +
    (decisionNote == null ? 0 : decisionNote!.hashCode) +
    (createdAt.hashCode);

  @override
  String toString() => 'ModerationCase[id=$id, kind=$kind, source_=$source_, conversationId=$conversationId, listingId=$listingId, messageId=$messageId, reason=$reason, note=$note, status=$status, reporterName=$reporterName, reporterEmail=$reporterEmail, reporterAnonymous=$reporterAnonymous, reportedId=$reportedId, reportedName=$reportedName, reportedEmail=$reportedEmail, listingTitle=$listingTitle, messageBody=$messageBody, aiStatus=$aiStatus, aiSuggestion=$aiSuggestion, decision=$decision, decisionNote=$decisionNote, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'kind'] = this.kind;
      json[r'source'] = this.source_;
    if (this.conversationId != null) {
      json[r'conversation_id'] = this.conversationId;
    } else {
      json[r'conversation_id'] = null;
    }
    if (this.listingId != null) {
      json[r'listing_id'] = this.listingId;
    } else {
      json[r'listing_id'] = null;
    }
    if (this.messageId != null) {
      json[r'message_id'] = this.messageId;
    } else {
      json[r'message_id'] = null;
    }
      json[r'reason'] = this.reason;
    if (this.note != null) {
      json[r'note'] = this.note;
    } else {
      json[r'note'] = null;
    }
      json[r'status'] = this.status;
    if (this.reporterName != null) {
      json[r'reporter_name'] = this.reporterName;
    } else {
      json[r'reporter_name'] = null;
    }
    if (this.reporterEmail != null) {
      json[r'reporter_email'] = this.reporterEmail;
    } else {
      json[r'reporter_email'] = null;
    }
    if (this.reporterAnonymous != null) {
      json[r'reporter_anonymous'] = this.reporterAnonymous;
    } else {
      json[r'reporter_anonymous'] = null;
    }
    if (this.reportedId != null) {
      json[r'reported_id'] = this.reportedId;
    } else {
      json[r'reported_id'] = null;
    }
    if (this.reportedName != null) {
      json[r'reported_name'] = this.reportedName;
    } else {
      json[r'reported_name'] = null;
    }
    if (this.reportedEmail != null) {
      json[r'reported_email'] = this.reportedEmail;
    } else {
      json[r'reported_email'] = null;
    }
      json[r'listing_title'] = this.listingTitle;
      json[r'message_body'] = this.messageBody;
      json[r'ai_status'] = this.aiStatus;
    if (this.aiSuggestion != null) {
      json[r'ai_suggestion'] = this.aiSuggestion;
    } else {
      json[r'ai_suggestion'] = null;
    }
    if (this.decision != null) {
      json[r'decision'] = this.decision;
    } else {
      json[r'decision'] = null;
    }
    if (this.decisionNote != null) {
      json[r'decision_note'] = this.decisionNote;
    } else {
      json[r'decision_note'] = null;
    }
      json[r'created_at'] = this.createdAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [ModerationCase] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ModerationCase? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ModerationCase[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ModerationCase[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ModerationCase(
        id: mapValueOfType<String>(json, r'id')!,
        kind: ModerationCaseKindEnum.fromJson(json[r'kind'])!,
        source_: ModerationCaseSource_Enum.fromJson(json[r'source'])!,
        conversationId: mapValueOfType<String>(json, r'conversation_id'),
        listingId: mapValueOfType<String>(json, r'listing_id'),
        messageId: mapValueOfType<String>(json, r'message_id'),
        reason: mapValueOfType<String>(json, r'reason')!,
        note: mapValueOfType<String>(json, r'note'),
        status: ModerationCaseStatusEnum.fromJson(json[r'status'])!,
        reporterName: mapValueOfType<String>(json, r'reporter_name'),
        reporterEmail: mapValueOfType<String>(json, r'reporter_email'),
        reporterAnonymous: mapValueOfType<bool>(json, r'reporter_anonymous'),
        reportedId: mapValueOfType<String>(json, r'reported_id'),
        reportedName: mapValueOfType<String>(json, r'reported_name'),
        reportedEmail: mapValueOfType<String>(json, r'reported_email'),
        listingTitle: I18nText.fromJson(json[r'listing_title'])!,
        messageBody: mapValueOfType<String>(json, r'message_body')!,
        aiStatus: ModerationCaseAiStatusEnum.fromJson(json[r'ai_status'])!,
        aiSuggestion: ModerationSuggestion.fromJson(json[r'ai_suggestion']),
        decision: ModerationVerdict.fromJson(json[r'decision']),
        decisionNote: mapValueOfType<String>(json, r'decision_note'),
        createdAt: mapDateTime(json, r'created_at', r'')!,
      );
    }
    return null;
  }

  static List<ModerationCase> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ModerationCase>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ModerationCase.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ModerationCase> mapFromJson(dynamic json) {
    final map = <String, ModerationCase>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ModerationCase.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ModerationCase-objects as value to a dart map
  static Map<String, List<ModerationCase>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ModerationCase>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ModerationCase.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'kind',
    'source',
    'reason',
    'status',
    'listing_title',
    'message_body',
    'ai_status',
    'created_at',
  };
}

/// What was reported.
class ModerationCaseKindEnum {
  /// Instantiate a new enum with the provided [value].
  const ModerationCaseKindEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const conversation = ModerationCaseKindEnum._(r'conversation');
  static const listing = ModerationCaseKindEnum._(r'listing');

  /// List of all possible values in this [enum][ModerationCaseKindEnum].
  static const values = <ModerationCaseKindEnum>[
    conversation,
    listing,
  ];

  static ModerationCaseKindEnum? fromJson(dynamic value) => ModerationCaseKindEnumTypeTransformer().decode(value);

  static List<ModerationCaseKindEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ModerationCaseKindEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ModerationCaseKindEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ModerationCaseKindEnum] to String,
/// and [decode] dynamic data back to [ModerationCaseKindEnum].
class ModerationCaseKindEnumTypeTransformer {
  factory ModerationCaseKindEnumTypeTransformer() => _instance ??= const ModerationCaseKindEnumTypeTransformer._();

  const ModerationCaseKindEnumTypeTransformer._();

  String encode(ModerationCaseKindEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a ModerationCaseKindEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ModerationCaseKindEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'conversation': return ModerationCaseKindEnum.conversation;
        case r'listing': return ModerationCaseKindEnum.listing;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ModerationCaseKindEnumTypeTransformer] instance.
  static ModerationCaseKindEnumTypeTransformer? _instance;
}



class ModerationCaseSource_Enum {
  /// Instantiate a new enum with the provided [value].
  const ModerationCaseSource_Enum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const report = ModerationCaseSource_Enum._(r'report');
  static const auto = ModerationCaseSource_Enum._(r'auto');

  /// List of all possible values in this [enum][ModerationCaseSource_Enum].
  static const values = <ModerationCaseSource_Enum>[
    report,
    auto,
  ];

  static ModerationCaseSource_Enum? fromJson(dynamic value) => ModerationCaseSource_EnumTypeTransformer().decode(value);

  static List<ModerationCaseSource_Enum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ModerationCaseSource_Enum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ModerationCaseSource_Enum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ModerationCaseSource_Enum] to String,
/// and [decode] dynamic data back to [ModerationCaseSource_Enum].
class ModerationCaseSource_EnumTypeTransformer {
  factory ModerationCaseSource_EnumTypeTransformer() => _instance ??= const ModerationCaseSource_EnumTypeTransformer._();

  const ModerationCaseSource_EnumTypeTransformer._();

  String encode(ModerationCaseSource_Enum data) => data.value;

  /// Decodes a [dynamic value][data] to a ModerationCaseSource_Enum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ModerationCaseSource_Enum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'report': return ModerationCaseSource_Enum.report;
        case r'auto': return ModerationCaseSource_Enum.auto;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ModerationCaseSource_EnumTypeTransformer] instance.
  static ModerationCaseSource_EnumTypeTransformer? _instance;
}



class ModerationCaseStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const ModerationCaseStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const open = ModerationCaseStatusEnum._(r'open');
  static const resolved = ModerationCaseStatusEnum._(r'resolved');

  /// List of all possible values in this [enum][ModerationCaseStatusEnum].
  static const values = <ModerationCaseStatusEnum>[
    open,
    resolved,
  ];

  static ModerationCaseStatusEnum? fromJson(dynamic value) => ModerationCaseStatusEnumTypeTransformer().decode(value);

  static List<ModerationCaseStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ModerationCaseStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ModerationCaseStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ModerationCaseStatusEnum] to String,
/// and [decode] dynamic data back to [ModerationCaseStatusEnum].
class ModerationCaseStatusEnumTypeTransformer {
  factory ModerationCaseStatusEnumTypeTransformer() => _instance ??= const ModerationCaseStatusEnumTypeTransformer._();

  const ModerationCaseStatusEnumTypeTransformer._();

  String encode(ModerationCaseStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a ModerationCaseStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ModerationCaseStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'open': return ModerationCaseStatusEnum.open;
        case r'resolved': return ModerationCaseStatusEnum.resolved;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ModerationCaseStatusEnumTypeTransformer] instance.
  static ModerationCaseStatusEnumTypeTransformer? _instance;
}



class ModerationCaseAiStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const ModerationCaseAiStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const pending = ModerationCaseAiStatusEnum._(r'pending');
  static const ready = ModerationCaseAiStatusEnum._(r'ready');
  static const failed = ModerationCaseAiStatusEnum._(r'failed');
  static const disabled = ModerationCaseAiStatusEnum._(r'disabled');

  /// List of all possible values in this [enum][ModerationCaseAiStatusEnum].
  static const values = <ModerationCaseAiStatusEnum>[
    pending,
    ready,
    failed,
    disabled,
  ];

  static ModerationCaseAiStatusEnum? fromJson(dynamic value) => ModerationCaseAiStatusEnumTypeTransformer().decode(value);

  static List<ModerationCaseAiStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ModerationCaseAiStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ModerationCaseAiStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ModerationCaseAiStatusEnum] to String,
/// and [decode] dynamic data back to [ModerationCaseAiStatusEnum].
class ModerationCaseAiStatusEnumTypeTransformer {
  factory ModerationCaseAiStatusEnumTypeTransformer() => _instance ??= const ModerationCaseAiStatusEnumTypeTransformer._();

  const ModerationCaseAiStatusEnumTypeTransformer._();

  String encode(ModerationCaseAiStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a ModerationCaseAiStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ModerationCaseAiStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'pending': return ModerationCaseAiStatusEnum.pending;
        case r'ready': return ModerationCaseAiStatusEnum.ready;
        case r'failed': return ModerationCaseAiStatusEnum.failed;
        case r'disabled': return ModerationCaseAiStatusEnum.disabled;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ModerationCaseAiStatusEnumTypeTransformer] instance.
  static ModerationCaseAiStatusEnumTypeTransformer? _instance;
}


