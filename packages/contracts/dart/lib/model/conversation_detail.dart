//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ConversationDetail {
  /// Returns a new [ConversationDetail] instance.
  ConversationDetail({
    required this.conversation,
    this.peerReadAt,
    this.prescreen = const [],
  });

  Conversation conversation;

  /// When the other side last read the conversation.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? peerReadAt;

  List<PrescreenAnswer> prescreen;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ConversationDetail &&
    other.conversation == conversation &&
    other.peerReadAt == peerReadAt &&
    _deepEquality.equals(other.prescreen, prescreen);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (conversation.hashCode) +
    (peerReadAt == null ? 0 : peerReadAt!.hashCode) +
    (prescreen.hashCode);

  @override
  String toString() => 'ConversationDetail[conversation=$conversation, peerReadAt=$peerReadAt, prescreen=$prescreen]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'conversation'] = this.conversation;
    if (this.peerReadAt != null) {
      json[r'peer_read_at'] = this.peerReadAt!.toUtc().toIso8601String();
    } else {
      json[r'peer_read_at'] = null;
    }
      json[r'prescreen'] = this.prescreen;
    return json;
  }

  /// Returns a new [ConversationDetail] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ConversationDetail? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ConversationDetail[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ConversationDetail[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ConversationDetail(
        conversation: Conversation.fromJson(json[r'conversation'])!,
        peerReadAt: mapDateTime(json, r'peer_read_at', r''),
        prescreen: PrescreenAnswer.listFromJson(json[r'prescreen']),
      );
    }
    return null;
  }

  static List<ConversationDetail> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ConversationDetail>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ConversationDetail.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ConversationDetail> mapFromJson(dynamic json) {
    final map = <String, ConversationDetail>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ConversationDetail.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ConversationDetail-objects as value to a dart map
  static Map<String, List<ConversationDetail>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ConversationDetail>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ConversationDetail.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'conversation',
    'prescreen',
  };
}

