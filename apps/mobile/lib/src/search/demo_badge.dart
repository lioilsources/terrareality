import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';

/// The "Demo listing – not available to rent" label on closed-beta
/// placeholder listings. Same shape as the "Promoted" label, in the error
/// colours so it cannot be missed.
class DemoBadge extends StatelessWidget {
  const DemoBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.info_outline, size: 16, color: scheme.onErrorContainer),
        const SizedBox(width: 4),
        Flexible(
          child: Text(t.demoBadge, style: TextStyle(color: scheme.onErrorContainer, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}
