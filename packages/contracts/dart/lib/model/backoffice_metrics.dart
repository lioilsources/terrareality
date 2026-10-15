//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class BackofficeMetrics {
  /// Returns a new [BackofficeMetrics] instance.
  BackofficeMetrics({
    required this.users,
    required this.orgs,
    required this.listingsPublished,
    required this.listingsPromoted,
    required this.applications30d,
    required this.leasesSigned30d,
    required this.moderationOpen,
    required this.attributeSuggestionsOpen,
    required this.revenue30d,
    required this.ordersPaid30d,
  });

  int users;

  int orgs;

  int listingsPublished;

  int listingsPromoted;

  int applications30d;

  int leasesSigned30d;

  /// Open message moderation cases plus listing versions waiting for review.
  int moderationOpen;

  int attributeSuggestionsOpen;

  Money revenue30d;

  int ordersPaid30d;

  @override
  bool operator ==(Object other) => identical(this, other) || other is BackofficeMetrics &&
    other.users == users &&
    other.orgs == orgs &&
    other.listingsPublished == listingsPublished &&
    other.listingsPromoted == listingsPromoted &&
    other.applications30d == applications30d &&
    other.leasesSigned30d == leasesSigned30d &&
    other.moderationOpen == moderationOpen &&
    other.attributeSuggestionsOpen == attributeSuggestionsOpen &&
    other.revenue30d == revenue30d &&
    other.ordersPaid30d == ordersPaid30d;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (users.hashCode) +
    (orgs.hashCode) +
    (listingsPublished.hashCode) +
    (listingsPromoted.hashCode) +
    (applications30d.hashCode) +
    (leasesSigned30d.hashCode) +
    (moderationOpen.hashCode) +
    (attributeSuggestionsOpen.hashCode) +
    (revenue30d.hashCode) +
    (ordersPaid30d.hashCode);

  @override
  String toString() => 'BackofficeMetrics[users=$users, orgs=$orgs, listingsPublished=$listingsPublished, listingsPromoted=$listingsPromoted, applications30d=$applications30d, leasesSigned30d=$leasesSigned30d, moderationOpen=$moderationOpen, attributeSuggestionsOpen=$attributeSuggestionsOpen, revenue30d=$revenue30d, ordersPaid30d=$ordersPaid30d]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'users'] = this.users;
      json[r'orgs'] = this.orgs;
      json[r'listings_published'] = this.listingsPublished;
      json[r'listings_promoted'] = this.listingsPromoted;
      json[r'applications_30d'] = this.applications30d;
      json[r'leases_signed_30d'] = this.leasesSigned30d;
      json[r'moderation_open'] = this.moderationOpen;
      json[r'attribute_suggestions_open'] = this.attributeSuggestionsOpen;
      json[r'revenue_30d'] = this.revenue30d;
      json[r'orders_paid_30d'] = this.ordersPaid30d;
    return json;
  }

  /// Returns a new [BackofficeMetrics] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static BackofficeMetrics? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "BackofficeMetrics[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "BackofficeMetrics[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return BackofficeMetrics(
        users: mapValueOfType<int>(json, r'users')!,
        orgs: mapValueOfType<int>(json, r'orgs')!,
        listingsPublished: mapValueOfType<int>(json, r'listings_published')!,
        listingsPromoted: mapValueOfType<int>(json, r'listings_promoted')!,
        applications30d: mapValueOfType<int>(json, r'applications_30d')!,
        leasesSigned30d: mapValueOfType<int>(json, r'leases_signed_30d')!,
        moderationOpen: mapValueOfType<int>(json, r'moderation_open')!,
        attributeSuggestionsOpen: mapValueOfType<int>(json, r'attribute_suggestions_open')!,
        revenue30d: Money.fromJson(json[r'revenue_30d'])!,
        ordersPaid30d: mapValueOfType<int>(json, r'orders_paid_30d')!,
      );
    }
    return null;
  }

  static List<BackofficeMetrics> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <BackofficeMetrics>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = BackofficeMetrics.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, BackofficeMetrics> mapFromJson(dynamic json) {
    final map = <String, BackofficeMetrics>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = BackofficeMetrics.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of BackofficeMetrics-objects as value to a dart map
  static Map<String, List<BackofficeMetrics>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<BackofficeMetrics>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = BackofficeMetrics.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'users',
    'orgs',
    'listings_published',
    'listings_promoted',
    'applications_30d',
    'leases_signed_30d',
    'moderation_open',
    'attribute_suggestions_open',
    'revenue_30d',
    'orders_paid_30d',
  };
}

