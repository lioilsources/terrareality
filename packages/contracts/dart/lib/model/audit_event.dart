//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AuditEvent {
  /// Returns a new [AuditEvent] instance.
  AuditEvent({
    required this.id,
    required this.occurredAt,
    this.actorId,
    this.actorEmail,
    this.impersonatorId,
    this.orgId,
    required this.entity,
    this.entityId,
    required this.action,
    this.diff = const {},
  });

  String id;

  DateTime occurredAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? actorId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? actorEmail;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? impersonatorId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? orgId;

  String entity;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? entityId;

  String action;

  Map<String, Object> diff;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AuditEvent &&
    other.id == id &&
    other.occurredAt == occurredAt &&
    other.actorId == actorId &&
    other.actorEmail == actorEmail &&
    other.impersonatorId == impersonatorId &&
    other.orgId == orgId &&
    other.entity == entity &&
    other.entityId == entityId &&
    other.action == action &&
    _deepEquality.equals(other.diff, diff);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (occurredAt.hashCode) +
    (actorId == null ? 0 : actorId!.hashCode) +
    (actorEmail == null ? 0 : actorEmail!.hashCode) +
    (impersonatorId == null ? 0 : impersonatorId!.hashCode) +
    (orgId == null ? 0 : orgId!.hashCode) +
    (entity.hashCode) +
    (entityId == null ? 0 : entityId!.hashCode) +
    (action.hashCode) +
    (diff.hashCode);

  @override
  String toString() => 'AuditEvent[id=$id, occurredAt=$occurredAt, actorId=$actorId, actorEmail=$actorEmail, impersonatorId=$impersonatorId, orgId=$orgId, entity=$entity, entityId=$entityId, action=$action, diff=$diff]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'occurred_at'] = this.occurredAt.toUtc().toIso8601String();
    if (this.actorId != null) {
      json[r'actor_id'] = this.actorId;
    } else {
      json[r'actor_id'] = null;
    }
    if (this.actorEmail != null) {
      json[r'actor_email'] = this.actorEmail;
    } else {
      json[r'actor_email'] = null;
    }
    if (this.impersonatorId != null) {
      json[r'impersonator_id'] = this.impersonatorId;
    } else {
      json[r'impersonator_id'] = null;
    }
    if (this.orgId != null) {
      json[r'org_id'] = this.orgId;
    } else {
      json[r'org_id'] = null;
    }
      json[r'entity'] = this.entity;
    if (this.entityId != null) {
      json[r'entity_id'] = this.entityId;
    } else {
      json[r'entity_id'] = null;
    }
      json[r'action'] = this.action;
      json[r'diff'] = this.diff;
    return json;
  }

  /// Returns a new [AuditEvent] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AuditEvent? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "AuditEvent[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "AuditEvent[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return AuditEvent(
        id: mapValueOfType<String>(json, r'id')!,
        occurredAt: mapDateTime(json, r'occurred_at', r'')!,
        actorId: mapValueOfType<String>(json, r'actor_id'),
        actorEmail: mapValueOfType<String>(json, r'actor_email'),
        impersonatorId: mapValueOfType<String>(json, r'impersonator_id'),
        orgId: mapValueOfType<String>(json, r'org_id'),
        entity: mapValueOfType<String>(json, r'entity')!,
        entityId: mapValueOfType<String>(json, r'entity_id'),
        action: mapValueOfType<String>(json, r'action')!,
        diff: mapCastOfType<String, Object>(json, r'diff')!,
      );
    }
    return null;
  }

  static List<AuditEvent> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AuditEvent>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AuditEvent.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AuditEvent> mapFromJson(dynamic json) {
    final map = <String, AuditEvent>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AuditEvent.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AuditEvent-objects as value to a dart map
  static Map<String, List<AuditEvent>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AuditEvent>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AuditEvent.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'occurred_at',
    'entity',
    'action',
    'diff',
  };
}

