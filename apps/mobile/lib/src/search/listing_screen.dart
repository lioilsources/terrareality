import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:terra_api/api.dart';

import '../../l10n/gen/app_localizations.dart';
import '../leases/leases_screen.dart' show money;
import '../messaging/conversations_screen.dart' show titleOf;
import 'listing_map.dart';
import 'search_repository.dart';
import 'search_screen.dart' show kindText;

/// What the seeker fills in before contacting the landlord or applying.
class ContactDraft {
  ContactDraft(this.message, this.answers, {this.householdSize});

  final String message;
  final Map<String, String> answers;
  final int? householdSize;
}

/// A public listing: photos, parameters, rent, a map pin and the seeker's
/// actions (message, viewing, application).
class ListingScreen extends ConsumerWidget {
  const ListingScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final listing = ref.watch(publicListingProvider(id));
    return Scaffold(
      appBar: AppBar(title: Text(t.listingTitle)),
      body: listing.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e is ApiException && e.code == 404 ? t.listingGone : t.statusUnreachable)),
        data: (l) => _ListingBody(listing: l),
      ),
    );
  }
}

class _ListingBody extends ConsumerWidget {
  const _ListingBody({required this.listing});

  final PublicListing listing;

  Future<void> _guard(BuildContext context, AppLocalizations t, Future<void> Function() action) async {
    try {
      await action();
    } on ApiException catch (e) {
      if (!context.mounted) return;
      if (e.code == 401) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.loginRequired)));
        context.push('/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.actionFailed)));
      }
    }
  }

  Future<ContactDraft?> _ask(BuildContext context, {required String title, required String message, bool household = false}) =>
      showDialog<ContactDraft>(
        context: context,
        builder: (_) => _ContactDialog(listing: listing, title: title, message: message, household: household),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final lang = locale.languageCode;
    final repo = ref.read(searchRepositoryProvider);
    final text = Theme.of(context).textTheme;
    final u = listing.unit;
    final loc = listing.location;
    final date = DateFormat.yMd(locale.toString());
    final facts = <(String, String)>[
      (t.attrKind, kindText(t, u.kind)),
      if (u.layout != null) (t.attrLayout, u.layout!),
      if (u.floorArea != null) (t.attrArea, '${u.floorArea!.round()} m²'),
      if (u.floor != null) (t.attrFloor, '${u.floor}'),
      if (listing.availableFrom != null) (t.attrAvailable, date.format(listing.availableFrom!)),
      if (listing.minTermMonths != null) (t.attrMinTerm, t.months(listing.minTermMonths!)),
      if (listing.depositAmount != null) (t.attrDeposit, money(listing.depositAmount!, locale.toString())),
      if (listing.utilitiesAmount != null) (t.attrUtilities, money(listing.utilitiesAmount!, locale.toString())),
      for (final e in listing.attributes.entries)
        if (e.value is! bool || e.value == true) (e.key, e.value is bool ? '✓' : '${e.value}'),
    ];
    return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
      if (listing.photos.isNotEmpty)
        SizedBox(
          height: 240,
          child: PageView(
            key: const Key('photos'),
            children: [
              for (final (i, p) in listing.photos.indexed)
                Semantics(
                  image: true,
                  label: t.photoOf(i + 1, listing.photos.length),
                  child: Image.network(
                    p.medium,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => ColoredBox(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                  ),
                ),
            ],
          ),
        ),
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titleOf(listing.title, lang), style: text.titleLarge),
          if (loc.address != null || listing.areaNames.isNotEmpty)
            Text(loc.address ?? listing.areaNames.join(', '), style: text.bodyMedium),
          const SizedBox(height: 8),
          Text(t.perMonth(money(listing.rentAmount, locale.toString())), key: const Key('rent'), style: text.headlineSmall),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton.icon(
              key: const Key('action-chat'),
              icon: const Icon(Icons.chat_bubble_outline),
              label: Text(t.actionMessage),
              onPressed: () => _guard(context, t, () async {
                final d = await _ask(context, title: t.actionMessage, message: t.chatDefault);
                if (d == null) return;
                final conv = await repo.startChat(listing.id, d.message, d.answers);
                if (context.mounted) context.push('/zpravy/$conv');
              }),
            ),
            OutlinedButton.icon(
              key: const Key('action-viewing'),
              icon: const Icon(Icons.event_outlined),
              label: Text(t.actionViewing),
              onPressed: () => _guard(context, t, () async {
                var app = await repo.applicationFor(listing.id);
                if (app == null) {
                  if (!context.mounted) return;
                  final needsAnswers = listing.prescreen.any((q) => q.required_);
                  final d = needsAnswers
                      ? await _ask(context, title: t.actionViewing, message: t.viewingRequestMessage)
                      : ContactDraft(t.viewingRequestMessage, const {});
                  if (d == null) return;
                  app = await repo.apply(listing.id, message: d.message, prescreen: d.answers);
                }
                if (context.mounted) context.push('/zadosti/$app');
              }),
            ),
            OutlinedButton.icon(
              key: const Key('action-apply'),
              icon: const Icon(Icons.assignment_outlined),
              label: Text(t.actionApply),
              onPressed: () => _guard(context, t, () async {
                final existing = await repo.applicationFor(listing.id);
                if (existing != null) {
                  if (context.mounted) context.push('/zadosti/$existing');
                  return;
                }
                if (!context.mounted) return;
                final d = await _ask(context, title: t.actionApply, message: '', household: true);
                if (d == null) return;
                final app = await repo.apply(listing.id,
                    message: d.message.isEmpty ? null : d.message, householdSize: d.householdSize, prescreen: d.answers);
                if (context.mounted) context.push('/zadosti/$app');
              }),
            ),
          ]),
          const SizedBox(height: 16),
          Text(listing.description.cs.isEmpty ? '' : titleOf(listing.description, lang)),
          const SizedBox(height: 16),
          Text(t.parameters, style: text.titleMedium),
          for (final (k, v) in facts)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Text(k, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
                Expanded(child: Text(v)),
              ]),
            ),
          const SizedBox(height: 16),
          Text(t.location, style: text.titleMedium),
          if (loc.precision == PublicListingLocationPrecisionEnum.approximate)
            Text(t.locationApproximate, style: text.bodySmall),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: _Pin(listing: listing),
          ),
          const SizedBox(height: 12),
          Text(t.safetyNote, style: text.bodySmall),
        ]),
      ),
    ]);
  }
}

/// The map pin; degrades to the coordinates when the map is unavailable.
class _Pin extends ConsumerStatefulWidget {
  const _Pin({required this.listing});

  final PublicListing listing;

  @override
  ConsumerState<_Pin> createState() => _PinState();
}

class _PinState extends ConsumerState<_Pin> {
  bool _failed = false;
  late final _markers = [
    MapMarker(id: widget.listing.id, lat: widget.listing.location.lat, lng: widget.listing.location.lng),
  ];

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final l = widget.listing.location;
    if (_failed) {
      return Card(
        child: Center(
          child: Text('${t.mapUnavailable}\n${l.lat.toStringAsFixed(4)}, ${l.lng.toStringAsFixed(4)}',
              textAlign: TextAlign.center),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Semantics(
        label: t.mapPinLabel,
        child: ref.watch(listingMapProvider).build(
              key: const Key('listing-map'),
              markers: _markers,
              interactive: false,
              onUnavailable: () {
                if (mounted) setState(() => _failed = true);
              },
            ),
      ),
    );
  }
}

class _ContactDialog extends StatefulWidget {
  const _ContactDialog({required this.listing, required this.title, required this.message, required this.household});

  final PublicListing listing;
  final String title;
  final String message;
  final bool household;

  @override
  State<_ContactDialog> createState() => _ContactDialogState();
}

class _ContactDialogState extends State<_ContactDialog> {
  final _form = GlobalKey<FormState>();
  late final _message = TextEditingController(text: widget.message);
  final _household = TextEditingController(text: '1');
  final _answers = <String, String>{};

  @override
  void dispose() {
    _message.dispose();
    _household.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final questions = widget.listing.prescreen.where((q) => q.id != null).toList();
    String? required(String? v) => (v == null || v.trim().isEmpty) ? t.fieldRequired : null;
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              key: const Key('contact-message'),
              controller: _message,
              minLines: 2,
              maxLines: 5,
              decoration: InputDecoration(labelText: t.messageHint),
              validator: widget.household ? null : required,
            ),
            if (widget.household)
              TextFormField(
                key: const Key('household'),
                controller: _household,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: t.householdSize),
                validator: (v) => (int.tryParse(v ?? '') ?? 0) < 1 ? t.fieldRequired : null,
              ),
            for (final q in questions)
              q.kind == PrescreenQuestionKindEnum.yesNo
                  ? DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: (lang == 'en' ? q.text.en : null) ?? q.text.cs ?? ''),
                      items: [
                        DropdownMenuItem(value: 'yes', child: Text(t.yes)),
                        DropdownMenuItem(value: 'no', child: Text(t.no)),
                      ],
                      onChanged: (v) => _answers[q.id!] = v ?? '',
                      validator: q.required_ ? required : null,
                    )
                  : TextFormField(
                      decoration: InputDecoration(labelText: (lang == 'en' ? q.text.en : null) ?? q.text.cs ?? ''),
                      keyboardType:
                          q.kind == PrescreenQuestionKindEnum.number ? TextInputType.number : TextInputType.text,
                      onChanged: (v) => _answers[q.id!] = v,
                      validator: q.required_ ? required : null,
                    ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
        FilledButton(
          key: const Key('contact-send'),
          onPressed: () {
            if (!(_form.currentState?.validate() ?? false)) return;
            Navigator.pop(
              context,
              ContactDraft(
                _message.text.trim(),
                {for (final e in _answers.entries) if (e.value.isNotEmpty) e.key: e.value},
                householdSize: widget.household ? int.tryParse(_household.text) : null,
              ),
            );
          },
          child: Text(t.messageSend),
        ),
      ],
    );
  }
}
