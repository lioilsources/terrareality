//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class FilterProposal {
  /// Returns a new [FilterProposal] instance.
  FilterProposal({
    required this.id,
    required this.attributeKey,
    required this.value,
    required this.label,
    required this.occurrences,
    required this.status,
    this.exampleListingId,
    required this.createdAt,
  });

  String id;

  String attributeKey;

  String value;

  I18nText label;

  int occurrences;

  FilterProposalStatusEnum status;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? exampleListingId;

  DateTime createdAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is FilterProposal &&
    other.id == id &&
    other.attributeKey == attributeKey &&
    other.value == value &&
    other.label == label &&
    other.occurrences == occurrences &&
    other.status == status &&
    other.exampleListingId == exampleListingId &&
    other.createdAt == createdAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (attributeKey.hashCode) +
    (value.hashCode) +
    (label.hashCode) +
    (occurrences.hashCode) +
    (status.hashCode) +
    (exampleListingId == null ? 0 : exampleListingId!.hashCode) +
    (createdAt.hashCode);

  @override
  String toString() => 'FilterProposal[id=$id, attributeKey=$attributeKey, value=$value, label=$label, occurrences=$occurrences, status=$status, exampleListingId=$exampleListingId, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'attribute_key'] = this.attributeKey;
      json[r'value'] = this.value;
      json[r'label'] = this.label;
      json[r'occurrences'] = this.occurrences;
      json[r'status'] = this.status;
    if (this.exampleListingId != null) {
      json[r'example_listing_id'] = this.exampleListingId;
    } else {
      json[r'example_listing_id'] = null;
    }
      json[r'created_at'] = this.createdAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [FilterProposal] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static FilterProposal? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "FilterProposal[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "FilterProposal[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return FilterProposal(
        id: mapValueOfType<String>(json, r'id')!,
        attributeKey: mapValueOfType<String>(json, r'attribute_key')!,
        value: mapValueOfType<String>(json, r'value')!,
        label: I18nText.fromJson(json[r'label'])!,
        occurrences: mapValueOfType<int>(json, r'occurrences')!,
        status: FilterProposalStatusEnum.fromJson(json[r'status'])!,
        exampleListingId: mapValueOfType<String>(json, r'example_listing_id'),
        createdAt: mapDateTime(json, r'created_at', r'')!,
      );
    }
    return null;
  }

  static List<FilterProposal> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <FilterProposal>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = FilterProposal.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, FilterProposal> mapFromJson(dynamic json) {
    final map = <String, FilterProposal>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = FilterProposal.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of FilterProposal-objects as value to a dart map
  static Map<String, List<FilterProposal>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<FilterProposal>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = FilterProposal.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'attribute_key',
    'value',
    'label',
    'occurrences',
    'status',
    'created_at',
  };
}


class FilterProposalStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const FilterProposalStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const pending = FilterProposalStatusEnum._(r'pending');
  static const approved = FilterProposalStatusEnum._(r'approved');
  static const rejected = FilterProposalStatusEnum._(r'rejected');

  /// List of all possible values in this [enum][FilterProposalStatusEnum].
  static const values = <FilterProposalStatusEnum>[
    pending,
    approved,
    rejected,
  ];

  static FilterProposalStatusEnum? fromJson(dynamic value) => FilterProposalStatusEnumTypeTransformer().decode(value);

  static List<FilterProposalStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <FilterProposalStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = FilterProposalStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [FilterProposalStatusEnum] to String,
/// and [decode] dynamic data back to [FilterProposalStatusEnum].
class FilterProposalStatusEnumTypeTransformer {
  factory FilterProposalStatusEnumTypeTransformer() => _instance ??= const FilterProposalStatusEnumTypeTransformer._();

  const FilterProposalStatusEnumTypeTransformer._();

  String encode(FilterProposalStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a FilterProposalStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  FilterProposalStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'pending': return FilterProposalStatusEnum.pending;
        case r'approved': return FilterProposalStatusEnum.approved;
        case r'rejected': return FilterProposalStatusEnum.rejected;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [FilterProposalStatusEnumTypeTransformer] instance.
  static FilterProposalStatusEnumTypeTransformer? _instance;
}


